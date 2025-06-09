import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eat_wise/Utils/Apis_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
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

class _ScanPageState extends State<ScanPage>
    with SingleTickerProviderStateMixin {
  late CameraController _cameraController;
  late List<CameraDescription> cameras;
  XFile? capturedImage;
  bool isCameraInitialized = false;
  bool isFlashOn = false;
  bool isFlashEffect = false;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
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
        const SnackBar(content: Text("Failed to initialize camera")),
      );
    }
  }

  @override
  void dispose() {
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
      setState(() {
        capturedImage = image;
        isFlashEffect = false;
      });
      showConfirmationDialog(image.path);
    } catch (e) {
      debugPrint("Error capturing image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to capture image")),
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  void showConfirmationDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Image"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(File(imagePath)),
            if (isProcessing)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => isProcessing = false);
            },
            child: const Text("Retake", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              processImage(imagePath);
            },
            child: const Text("Confirm", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
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

  Future<void> processImage(String imagePath) async {
    setState(() => isProcessing = true);

    try {
      final textRecognizer = GoogleMlKit.vision.textRecognizer();
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      List<String> extractedDishes = [];
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
      ];

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          String text = line.text.trim();
          String lowerText = text.toLowerCase();

          if (text.length > 3 &&
              text.length < 40 &&
              !text.contains(RegExp(r'\d')) &&
              !ignoreKeywords.any((kw) => lowerText.contains(kw)) &&
              text != text.toUpperCase()) {
            extractedDishes.add(text);
          }
        }
      }

      textRecognizer.close();

      if (extractedDishes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No dishes detected in the image")),
        );
        return;
      }

      await _updateExtractedDishes(extractedDishes);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Output(
            dishes: extractedDishes,
            healthConditions: widget.healthConditions,
            userId: widget.userId,
            profileId: widget.profileId,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Image processing error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Processing failed: ${e.toString()}")),
      );
    } finally {
      setState(() => isProcessing = false);
    }
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black.withOpacity(0.8),
        actions: [
          IconButton(
            icon: Icon(
              isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: toggleFlash,
          )
        ],
      ),
      body: Stack(
        children: [
          if (isCameraInitialized)
            CameraPreview(_cameraController)
          else
            const Center(child: CircularProgressIndicator()),

          // Scanning frame overlay
          Positioned(
            top: 30,
            left: 40,
            child: Container(
              width: mq.width * 0.8,
              height: mq.height * 0.6,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Center(
                child: Text(
                  "Align the menu card here",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Capture button
          if (!isProcessing)
            Positioned(
              bottom: 10,
              left: mq.width / 2 - 40,
              child: GestureDetector(
                onTap: captureImage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(80),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.6),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Processing indicator
          if (isProcessing)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),

          // Flash effect
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
}
