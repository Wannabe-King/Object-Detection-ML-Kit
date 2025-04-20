import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  static const _methodChannel = MethodChannel('object_detector');
  static const _eventChannel = EventChannel('object_detector_events');
  
  StreamSubscription? _detectionSubscription;
  List<Map<String, dynamic>> _detectedObjects = [];
  bool _isDetecting = false;
  bool _cameraInitialized = false;
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCameraSystem();
    _setupDetectionListener();
  }

  @override
  void dispose() {
    _stopDetection();
    _controller?.dispose();
    _detectionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeCameraSystem() async {
    try {
      await _requestCameraPermission();
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw Exception('No cameras available');
      await _initializeCamera();
      await _methodChannel.invokeMethod('initialize');
      setState(() => _cameraInitialized = true);
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.high,
    );
    
    try {
      await _controller!.initialize();
      if (mounted) setState(() {});
    } on CameraException catch (e) {
      debugPrint('Camera error: ${e.code}\n${e.description}');
    }
  }

  void _setupDetectionListener() {
    _detectionSubscription = _eventChannel.receiveBroadcastStream().listen(
      (data) => _handleDetectionResults(data),
      onError: (error) => debugPrint('Detection error: $error'),
    );
  }

  void _handleDetectionResults(dynamic data) {
    if (!mounted || !_isDetecting) return;
    
    final results = (data as List<dynamic>).cast<Map<dynamic, dynamic>>();
    final objects = results.map((item) => _parseDetection(item)).toList();

    setState(() => _detectedObjects = objects);
  }

  Map<String, dynamic> _parseDetection(Map<dynamic, dynamic> item) {
    return {
      'label': item['label'] as String? ?? 'Unknown',
      'confidence': (item['confidence'] as num?)?.toDouble() ?? 0.0,
      'boundingBox': _parseBoundingBox(item['boundingBox']),
      'trackingId': item['trackingId'] as int? ?? -1,
    };
  }

  Map<String, double> _parseBoundingBox(dynamic boxData) {
    final box = (boxData as Map<dynamic, dynamic>).cast<String, dynamic>();
    return {
      'left': (box['left'] as num).toDouble(),
      'top': (box['top'] as num).toDouble(),
      'right': (box['right'] as num).toDouble(),
      'bottom': (box['bottom'] as num).toDouble(),
    };
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) throw Exception('Camera permission denied');
  }

  Future<void> _toggleDetection() async {
    if (!_isDetecting) {
      await _methodChannel.invokeMethod('startDetection');
    } else {
      await _methodChannel.invokeMethod('stopDetection');
    }
    setState(() => _isDetecting = !_isDetecting);
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    
    setState(() => _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length);
    await _controller?.dispose();
    await _initializeCamera();
  }

  Future<void> _stopDetection() async {
    if (_isDetecting) {
      await _methodChannel.invokeMethod('stopDetection');
      setState(() => _isDetecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraInitialized || _controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Object Scanner"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showDetectionInfo(),
          ),
        ],
      ),
      body: Stack(
        children: [
          CameraPreview(_controller!),
          _buildDetectionOverlay(),
          _buildControlPanel(),
        ],
      ),
    );
  }

  Widget _buildDetectionOverlay() {
    return Positioned.fill(
      child: CustomPaint(
        painter: ObjectDetectionPainter(
          detectedObjects: _detectedObjects,
          previewSize: _controller!.value.previewSize!,
          imageRotation: _controller!.description.sensorOrientation,
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton(
              onPressed: _toggleDetection,
              backgroundColor: _isDetecting ? Colors.red : Colors.green,
              child: Icon(_isDetecting ? Icons.stop : Icons.play_arrow),
            ),
            if (_cameras.length > 1)
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: FloatingActionButton(
                  onPressed: _switchCamera,
                  child: const Icon(Icons.switch_camera),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDetectionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detection Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Objects detected: ${_detectedObjects.length}'),
            ..._detectedObjects.take(3).map((obj) => ListTile(
              title: Text(obj['label']),
              subtitle: Text('Confidence: ${(obj['confidence'] * 100).toStringAsFixed(1)}%'),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class ObjectDetectionPainter extends CustomPainter {
  final List<Map<String, dynamic>> detectedObjects;
  final Size previewSize;
  final int imageRotation;

  ObjectDetectionPainter({
    required this.detectedObjects,
    required this.previewSize,
    required this.imageRotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final obj in detectedObjects) {
      final box = obj['boundingBox'] as Map<String, double>;
      final rect = Rect.fromLTRB(
        box['left']! * size.width,
        box['top']! * size.height,
        box['right']! * size.width,
        box['bottom']! * size.height,
      );

      paint.color = _getColorForLabel(obj['label'] as String);
      canvas.drawRect(rect, paint);

      // Draw label text
      final textSpan = TextSpan(
        text: '${obj['label']} ${(obj['confidence'] * 100).toStringAsFixed(1)}%',
        style: TextStyle(
          color: paint.color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(rect.left, rect.top - 20));
    }
  }

  Color _getColorForLabel(String label) {
    const colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.orange,
    ];
    final index = label.hashCode % colors.length;
    return colors[index];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DetectedObject {
  final String label;
  final double confidence;
  final Rect bounds;
  final int trackingId;

  DetectedObject({
    required this.label,
    required this.confidence,
    required this.bounds,
    required this.trackingId,
  });
}