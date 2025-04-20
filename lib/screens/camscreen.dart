import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:object_dection_flutter/utils/statustext.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  static const MethodChannel _objectDetectionChannel = MethodChannel(
    'object_detector',
  );

  DetectionState _detectionState = DetectionState.initializing;
  bool _isObjectDetected = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeObjectDetection();
  }

  Future<void> _initializeObjectDetection() async {
    try {
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) {
        _updateDetectionState(DetectionState.permissionDenied);
        return;
      }

      await _objectDetectionChannel.invokeMethod('ObjectDetection');
      _updateDetectionState(DetectionState.active);

      // Temporary simulation - replace with actual detection callback
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _isObjectDetected = true);
    } on PlatformException catch (e) {
      _handleDetectionError(e.message ?? 'Unknown platform error');
    } catch (e) {
      _handleDetectionError('Failed to initialize detection: $e');
    }
  }

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  void _updateDetectionState(DetectionState state) {
    setState(() => _detectionState = state);
  }

  void _handleDetectionError(String message) {
    setState(() {
      _detectionState = DetectionState.error;
      _errorMessage = message;
    });
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
          const Center(child: CameraPreviewPlaceholder()),
          if (_isObjectDetected) const ObjectDetectedBanner(),
          DetectionStatusOverlay(
            detectionState: _detectionState,
            errorMessage: _errorMessage,
          ),
        ],
      ),
    );
  }
}

enum DetectionState { initializing, active, permissionDenied, error }

class CameraPreviewPlaceholder extends StatelessWidget {
  const CameraPreviewPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class ObjectDetectedBanner extends StatelessWidget {
  const ObjectDetectedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: 40),
        child: Text(
          "Object Detected!",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
      ),
    );
  }
}

class DetectionStatusOverlay extends StatelessWidget {
  final DetectionState detectionState;
  final String errorMessage;

  const DetectionStatusOverlay({
    super.key,
    required this.detectionState,
    this.errorMessage = '',
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _buildStatusContent(),
      ),
    );
  }

  Widget _buildStatusContent() {
    switch (detectionState) {
      case DetectionState.initializing:
        return const StatusText('Initializing...');
      case DetectionState.active:
        return const StatusText('Camera Active. Scanning...');
      case DetectionState.permissionDenied:
        return const StatusText(
          'Camera permission required',
          color: Colors.orange,
        );
      case DetectionState.error:
        return StatusText('Error: $errorMessage', color: Colors.red);
    }
  }
}
