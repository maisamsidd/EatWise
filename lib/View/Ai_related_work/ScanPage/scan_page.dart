import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eat_wise/Utils/Apis_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image/image.dart' as img;
import 'output.dart';

class ScanPage extends StatefulWidget {
  final String name;
  final Map<String, bool> healthConditions;
  final String userId;
  final String profileId;

  const ScanPage({
    super.key,
    required this.name,
    required this.healthConditions,
    required this.userId,
    required this.profileId,
  });

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with SingleTickerProviderStateMixin {
  late CameraController _cameraController;
  late List<CameraDescription> cameras;
  XFile? capturedImage;
  bool isCameraInitialized = false;
  bool isFlashOn = false;
  bool isFlashEffect = false;
  bool isProcessing = false;
  late GenerativeModel geminiModel;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    geminiModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: 'AIzaSyBqmf39zxQnvE3qoAIjGLl3pSyNdkWSs78', // Replace with your actual API key
    );
    // Initialize glow animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 10, end: 20).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      cameras = await availableCameras();
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController.initialize();
      setState(() {
        isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint("Camera initialization error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to initialize camera"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.red[800],
        ),
      );
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> captureImage() async {
    if (!_cameraController.value.isInitialized || isProcessing) return;

    setState(() {
      isProcessing = true;
      isFlashEffect = true;
    });

    try {
      final XFile image = await _cameraController.takePicture();
      // Turn off flash after capturing image
      if (isFlashOn) {
        await _cameraController.setFlashMode(FlashMode.off);
        setState(() {
          isFlashOn = false;
        });
      }
      setState(() {
        capturedImage = image;
        isFlashEffect = false;
      });
      await processImageForConfirmation(image.path);
    } catch (e) {
      debugPrint("Error capturing image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to capture image"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.red[800],
        ),
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<void> processImageForConfirmation(String imagePath) async {
    setState(() => isProcessing = true);

    try {
      final textRecognizer = GoogleMlKit.vision.textRecognizer();
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      List<Map<String, dynamic>> textWithBounds = [];
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          textWithBounds.add({
            'text': line.text.trim(),
            'boundingBox': line.boundingBox,
          });
        }
      }

      textRecognizer.close();

      if (textWithBounds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("No text detected in the image"),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.orange[800],
          ),
        );
        return;
      }

      List<String> allTextBlocks = textWithBounds.map((e) => e['text'] as String).toList();
      List<String> extractedDishes = await _processTextWithGemini(allTextBlocks);

      if (extractedDishes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("No dishes detected in the image"),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.orange[800],
          ),
        );
        return;
      }

      List<Map<String, dynamic>> dishesWithBounds = [];
      for (String dish in extractedDishes) {
        var match = textWithBounds.firstWhere(
              (element) => element['text'].toLowerCase().contains(dish.toLowerCase()),
          orElse: () => {'text': dish, 'boundingBox': const Rect.fromLTWH(0, 0, 0, 0)},
        );
        dishesWithBounds.add({
          'text': dish,
          'boundingBox': match['boundingBox'],
        });
      }

      showDishConfirmationDialog(imagePath, dishesWithBounds);
    } catch (e) {
      debugPrint("Image processing error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Processing failed: ${e.toString()}"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.red[800],
        ),
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<List<String>> _processTextWithGemini(List<String> textBlocks) async {
    try {
      final prompt = """
      I have extracted text from a restaurant menu image. Please analyze this text and:
      1. Identify only the dish/food item names
      2. Correct any spelling mistakes
      3. Remove any non-food items (like prices, section headers, etc.)
      4. Return only the cleaned food names in a comma-separated list
      5. Do not include any beverages, drinks, or menu section titles
      6. Keep names in their original language (don't translate)
      
      Here is the extracted text:
      ${textBlocks.join('\n')}
      
      Please respond with ONLY the comma-separated list of food items, nothing else.
      """;

      final response = await geminiModel.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';

      if (text.isEmpty) return [];

      List<String> dishes = text
          .split(',')
          .map((dish) => dish.trim())
          .where((dish) => dish.isNotEmpty && dish.length > 3)
          .toList();

      return dishes;
    } catch (e) {
      debugPrint("Gemini processing error: $e");
      return _fallbackProcessing(textBlocks);
    }
  }

  List<String> _fallbackProcessing(List<String> textBlocks) {
    const ignoreKeywords = [
      "drinks",
      "beverages",
      "menu",
      "deals",
      "snacks",
      "appetizers",
      "desserts",
      "specials",
      "combo",
      "platter",
      "wraps",
      "sides",
      "price",
      "\$",
      "€",
      "£",
      "₹",
      "rs",
      "usd",
      "euro",
      "inr",
    ];

    List<String> extractedDishes = [];

    for (String text in textBlocks) {
      String lowerText = text.toLowerCase();

      if (text.length > 3 &&
          text.length < 40 &&
          !text.contains(RegExp(r'\d')) &&
          !ignoreKeywords.any((kw) => lowerText.contains(kw)) &&
          text != text.toUpperCase() &&
          _isValidDish(text)) {
        extractedDishes.add(text);
      }
    }

    return extractedDishes;
  }

  void showDishConfirmationDialog(String imagePath, List<Map<String, dynamic>> dishesWithBounds) {
    List<String> dishes = dishesWithBounds.map((dish) => dish['text'] as String).toList();
    List<TextEditingController> controllers = dishes.map((dish) => TextEditingController(text: dish)).toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          File imageFile = File(imagePath);
          img.Image? decodedImage = img.decodeImage(imageFile.readAsBytesSync());
          double imageWidth = decodedImage?.width.toDouble() ?? _cameraController.value.previewSize!.height;
          double imageHeight = decodedImage?.height.toDouble() ?? _cameraController.value.previewSize!.width;
          double screenWidth = MediaQuery.of(context).size.width - 40;
          double displayHeight = (imageHeight / imageWidth) * screenWidth;

          return Dialog(
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                Container(
                  width: screenWidth,
                  height: displayHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(imageFile),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: screenWidth * 0.9,
                    height: displayHeight * 1.0,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Review Detected Dishes",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: dishes.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          dishes[index],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              TextEditingController editController =
                                              TextEditingController(text: dishes[index]);
                                              return AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                backgroundColor: Colors.white,
                                                title: Text(
                                                  "Edit Dish Name",
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                content: TextField(
                                                  controller: editController,
                                                  decoration: InputDecoration(
                                                    hintText: "Enter dish name",
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                      borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                                                    ),
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                  ),
                                                  style: const TextStyle(fontSize: 16),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor: Colors.grey[600],
                                                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                                                    ),
                                                    child: const Text("Cancel"),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        dishes[index] = editController.text.trim();
                                                        controllers[index].text = editController.text.trim();
                                                      });
                                                      Navigator.pop(context);
                                                    },
                                                    style: TextButton.styleFrom(
                                                      foregroundColor: Colors.blue[600],
                                                      backgroundColor: Colors.blue[50],
                                                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                    ),
                                                    child: const Text("Save"),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 20, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            dishes.removeAt(index);
                                            controllers.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() => isProcessing = false);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  side: const BorderSide(color: Colors.red),
                                ),
                                child: const Text(
                                  "RETRY",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (dishes.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text("Please keep at least one dish"),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        backgroundColor: Colors.orange[800],
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.pop(context);
                                  _processConfirmedDishes(imagePath, dishes);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  "CONFIRM",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _processConfirmedDishes(String imagePath, List<String> dishes) async {
    setState(() => isProcessing = true);

    try {
      await _updateExtractedDishes(dishes);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Output(
            dishes: dishes,
            healthConditions: widget.healthConditions,
            userId: widget.userId,
            profileId: widget.profileId,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error processing confirmed dishes: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to process dishes: ${e.toString()}"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.red[800],
        ),
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  void toggleFlash() async {
    if (!isCameraInitialized) return;
    try {
      setState(() => isFlashOn = !isFlashOn);
      await _cameraController.setFlashMode(
        isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      debugPrint("Flash toggle error: $e");
    }
  }

  bool _isValidDish(String text) {
    return !text.contains("beverage") && !text.contains("drink");
  }

  Future<void> _updateExtractedDishes(List<String> dishes) async {
    try {
      await ApisUtils.users
          .doc(widget.userId)
          .collection("profiles")
          .doc(widget.profileId)
          .update({
        'extractedDishes': dishes,
        'healthConditions': widget.healthConditions,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Firestore update error: $e");
      throw Exception("Failed to update dishes");
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Scan Menu",
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue.shade700!.withOpacity(0.3),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 24, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: Colors.white,
              size: 24,
            ),
            onPressed: toggleFlash,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (isCameraInitialized)
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: CameraPreview(_cameraController),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          Positioned(
            top: mq.height * 0.15,
            left: mq.width * 0.1,
            child: Container(
              width: mq.width * 0.8,
              height: mq.height * 0.6,
              child: Stack(
                children: [
                  // Semi-transparent overlay for outside the guide
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.5), // Dim area outside guide
                    ),
                  ),
                  // Transparent inner guide area
                  Positioned(
                    left: 0,
                    top: 0,
                    width: mq.width * 0.8,
                    height: mq.height * 0.6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        color: Colors.transparent, // Ensure no tint inside
                      ),
                    ),
                  ),
                  // Corner markers
                  _buildCornerMarker(0, 0, Alignment.topLeft),
                  _buildCornerMarker(mq.width * 0.8, 0, Alignment.topRight),
                  _buildCornerMarker(0, mq.height * 0.6, Alignment.bottomLeft),
                  _buildCornerMarker(mq.width * 0.8, mq.height * 0.6, Alignment.bottomRight),
                  // Instruction text
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        "Align menu within this frame",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isProcessing)
            Positioned(
              bottom: mq.height * 0.05,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: captureImage,
                  child: AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade700.withOpacity(0.5),
                              blurRadius: _glowAnimation.value,
                              spreadRadius: _glowAnimation.value / 1,
                            ),
                          ],
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.shade700,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade700.withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          if (isProcessing)
            Container(
              color: Colors.black.withOpacity(0.6),
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Processing image...",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (isFlashEffect)
            Container(
              color: Colors.white.withOpacity(0.7),
              width: double.infinity,
              height: double.infinity,
            ),
        ],
      ),
    );
  }

  Widget _buildCornerMarker(double x, double y, Alignment alignment) {
    const double size = 24;
    return Positioned(
      left: alignment == Alignment.topRight || alignment == Alignment.bottomRight ? x - size : x,
      top: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight ? y - size : y,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: alignment == Alignment.topLeft
                  ? Border(
                top: BorderSide(color: Colors.blueAccent.withOpacity(0.9), width: 3),
                left: BorderSide(color: Colors.blueAccent.withOpacity(0.9), width: 3),
              )
                  : alignment == Alignment.topRight
                  ? Border(
                top: BorderSide(color: Colors.blueAccent.withOpacity(0.9), width: 3),
                right: BorderSide(color: Colors.blueAccent.withOpacity(0.9), width: 3),
              )
                  : alignment == Alignment.bottomLeft
                  ? Border(
                bottom: BorderSide(color: Colors.blueAccent.withOpacity(0.9), width: 3),
                left: BorderSide(color: Colors.blueAccent.withOpacity(0.9), width: 3),
              )
                  : Border(
                bottom: BorderSide(color: Colors.blueAccent.withOpacity(0.9), width: 3),
                right: BorderSide(color: Colors.blueAccent.withOpacity(0.9), width: 3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.4),
                  blurRadius: _glowAnimation.value / 2,
                  spreadRadius: 1,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}