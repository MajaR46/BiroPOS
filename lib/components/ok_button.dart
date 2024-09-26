import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';

class OKButton extends StatelessWidget {
  final VoidCallback onPressed;
  const OKButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppStyles.blue,
        ),
        child: Text(
          'OK',
          style: AppStyles.button1.copyWith(color: AppStyles.white),
        ),
      ),
    );
  }
}
