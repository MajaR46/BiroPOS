import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';

class OKButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const OKButton({super.key, required this.onPressed, required this.text});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppStyles.blue,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
      child: Text(
        text,
        style: AppStyles.button1.copyWith(color: AppStyles.white),
      ),
    );
  }
}
