import 'package:flutter/material.dart';

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
