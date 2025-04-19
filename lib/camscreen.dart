import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';


class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  static const MethodChannel _channel = MethodChannel('object_detector');
  String _status = "Initializing...";
  bool _alarm = false;

  @override
  void initState() {
    super.initState();
    _initDetection();
  }

  Future<void> _initDetection() async {
    await _requestCameraPermission();
    try {
      final result = await _channel.invokeMethod('startObjectDetection');
      setState(() {
        _status = "Camera Active. Scanning...";
        _alarm = true; // Simulate object detection for now
      });
    } on PlatformException catch (e) {
      setState(() {
        _status = "Error: ${e.message}";
      });
    }
  }

  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Object Scanner"),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Center(
                child: Text(
                  "Camera Preview Placeholder",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
          if (_alarm)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Text(
                  "Object Detected!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _status,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
