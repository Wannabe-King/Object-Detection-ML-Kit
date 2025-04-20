import 'package:flutter/material.dart';
import 'package:object_dection_flutter/camscreen.dart';
import 'package:object_dection_flutter/utils/button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 86, 184, 250),
      appBar: AppBar(title: (Text("HomeSceen"))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Object Detection using Native ML Kit',
              style: TextStyle(
                fontSize: 32,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            CustomButton(
              text: "Scan Now",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CameraScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
