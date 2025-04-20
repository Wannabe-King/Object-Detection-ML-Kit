import 'package:flutter/material.dart';
import 'package:object_dection_flutter/utils/statustext.dart';

enum DetectionState { initializing, active, permissionDenied, error }

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
