import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class ScanMenuCard extends StatefulWidget {
  final String name;
  const ScanMenuCard({super.key, required this.name});

  @override
  State<ScanMenuCard> createState() => _ScanMenuCardState();
}

class _ScanMenuCardState extends State<ScanMenuCard> {
  late CameraController _cameraController;
  late List<CameraDescription> cameras;
  XFile? capturedImage;
  bool isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    _cameraController = CameraController(cameras[0], ResolutionPreset.medium);

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
    if (!_cameraController.value.isInitialized ||
        !_cameraController.value.isTakingPicture) {
      XFile image = await _cameraController.takePicture();
      setState(() {
        capturedImage = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Container(
              width: 390,
              height: 390,
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(10),
              ),
              child: capturedImage != null
                  ? Image.file(
                      File(capturedImage!.path),
                      fit: BoxFit.cover,
                    )
                  : isCameraInitialized
                      ? CameraPreview(_cameraController)
                      : const Center(
                          child: CircularProgressIndicator(),
                        ),
            ),
          ),
          SizedBox(
            height: mq.height * 0.15,
          ),
          Center(
            child: GestureDetector(
              onTap: captureImage,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(80),
                ),
                child: const Center(
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
