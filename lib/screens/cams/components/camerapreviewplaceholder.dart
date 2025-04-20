import 'package:flutter/material.dart';

class CameraPreviewPlaceholder extends StatelessWidget {
  const CameraPreviewPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: 500,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black38, width: 2),
        borderRadius: BorderRadius.circular(40),
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
