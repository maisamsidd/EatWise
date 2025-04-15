import 'dart:io';
import 'package:camera/camera.dart';
import 'package:eat_wise/Utils/Apis_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

import 'output.dart';

class ScanPage extends StatefulWidget {
  final String name;
  final Map<String, bool> healthConditions;
  final String userId;
  const ScanPage(
      {super.key,
      required this.name,
      required this.healthConditions,
      required this.userId});

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

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
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
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> captureImage() async {
    if (!_cameraController.value.isInitialized) return;

    try {
      setState(() => isFlashEffect = true);
      XFile image = await _cameraController.takePicture();
      setState(() {
        capturedImage = image;
        isFlashEffect = false;
      });
      showConfirmationDialog(image.path);
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  void showConfirmationDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Image"),
        content: Image.file(File(imagePath)),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Retake", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              processImage(imagePath);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Output(
                      dishes: [],
                      healthConditions: {},
                    ),
                  ));
            },
            child: const Text("Confirm", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  void toggleFlash() async {
    if (!isCameraInitialized) return;
    setState(() {
      isFlashOn = !isFlashOn;
    });
    await _cameraController
        .setFlashMode(isFlashOn ? FlashMode.torch : FlashMode.off);
  }

  Future<void> processImage(String imagePath) async {
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    List<String> extractedDishes = [];
    final List<String> ignoreKeywords = [
      "rolls",
      "burgers",
      "drinks",
      "beverages",
      "menu",
      "deals",
      "snacks",
      "fries",
      "appetizers",
      "desserts",
      "specials",
      "combo",
      "platter",
      "wraps",
      "grill",
      "sides",
      "rice",
      "pasta",
      "noodles",
      "biryani",
      "pizza",
      "sandwiches"
    ];

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        String text = line.text.trim();

        // Lowercase for comparison
        String lowerText = text.toLowerCase();

        // Filter rules
        if (text.length > 3 &&
                text.length < 40 &&
                !text.contains(RegExp(r'\d')) && // Avoid prices and item codes
                !ignoreKeywords.any((kw) => lowerText.contains(kw)) &&
                text != text.toUpperCase() // Avoid headings in all caps
            ) {
          extractedDishes.add(text);
        }
      }
    }

    textRecognizer.close();

    _updateExtractedDishes(extractedDishes);
  }

  void _updateExtractedDishes(List<String> dishes) async {
    try {
      await ApisUtils.users
          .doc(ApisUtils.auth.currentUser!.uid)
          .collection("userDetails")
          .doc(widget.userId)
          .update({
        'extractedDishes': dishes,
        'healthConditions': widget.healthConditions,
      });
    } catch (e) {
      print("Error updating dishes: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black.withOpacity(0.8),
        actions: [
          IconButton(
            icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white),
            onPressed: toggleFlash,
          )
        ],
      ),
      body: Stack(
        children: [
          isCameraInitialized
              ? CameraPreview(_cameraController)
              : const Center(child: CircularProgressIndicator()),
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
                child: Text("Align the menu card here",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center),
              ),
            ),
          ),
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
                        spreadRadius: 3),
                  ],
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    size: 40, color: Colors.white),
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
}
