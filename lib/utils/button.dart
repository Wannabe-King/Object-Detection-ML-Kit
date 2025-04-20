import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final TextStyle? textStyle;
  final ButtonStyle? style;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor = Colors.white,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.borderRadius = 8.0,
    this.textStyle,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: _buildButtonStyle(context),
      child: Text(text, style: _buildTextStyle(context)),
    );
  }

  ButtonStyle _buildButtonStyle(BuildContext context) {
    final defaultStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color>(
        (states) => _getBackgroundColor(states, context),
      ),
      foregroundColor: WidgetStateProperty.all(textColor),
      padding: WidgetStateProperty.all(padding),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      elevation: WidgetStateProperty.all(0),
    );

    return defaultStyle.merge(style);
  }

  Color _getBackgroundColor(Set<WidgetState> states, BuildContext context) {
    if (states.contains(WidgetState.disabled)) {
      return Theme.of(context).disabledColor;
    }
    return backgroundColor ?? Theme.of(context).primaryColor;
  }

  TextStyle _buildTextStyle(BuildContext context) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ).merge(textStyle);
  }
}
