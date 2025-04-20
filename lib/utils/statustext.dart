import 'package:flutter/material.dart';

class StatusText extends StatelessWidget {
  final String text;
  final Color color;

  const StatusText(this.text, {super.key, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(color: color, fontSize: 16));
  }
}
