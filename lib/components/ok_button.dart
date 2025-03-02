import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';
import 'package:flutter/services.dart';

class OKButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const OKButton({super.key, required this.onPressed, required this.text});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        HapticFeedback.vibrate();
        onPressed();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppStyles.blue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      child: Text(
        text,
        style: AppStyles.button1.copyWith(color: AppStyles.white),
      ),
    );
  }
}
