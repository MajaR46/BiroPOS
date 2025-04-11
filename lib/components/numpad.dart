import 'package:flutter/material.dart';
import 'package:BiroPOS/app_styles.dart';
import 'package:flutter/services.dart';

class Numpad extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onOKPressed;

  const Numpad(
      {super.key, required this.controller, required this.onOKPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NumpadNumber(number: "7", controller: controller),
            NumpadNumber(number: "8", controller: controller),
            NumpadNumber(number: "9", controller: controller)
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NumpadNumber(number: "4", controller: controller),
            NumpadNumber(number: "5", controller: controller),
            NumpadNumber(number: "6", controller: controller)
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NumpadNumber(number: "1", controller: controller),
            NumpadNumber(number: "2", controller: controller),
            NumpadNumber(number: "3", controller: controller)
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NumpadDelete(
              height: 60,
              controller: controller,
              fontSize: 24,
              borderRadius: 40,
            ),
            NumpadNumber(number: "0", controller: controller),
            NumpadOK(onOKPressed: onOKPressed)
          ],
        )
      ],
    );
  }
}

class NumpadNumber extends StatelessWidget {
  final String number;
  final TextEditingController controller;

  const NumpadNumber(
      {super.key, required this.number, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: SizedBox(
        width: 80,
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppStyles.lightGrey,
            elevation: 0,
          ),
          onPressed: () {
            HapticFeedback.vibrate();
            controller.text += number.toString();
          },
          child: Center(
            child: Text(
              style: AppStyles.heading3.copyWith(color: AppStyles.black),
              number.toString(),
            ),
          ),
        ),
      ),
    );
  }
}

class NumpadDelete extends StatelessWidget {
  final TextEditingController controller;
  final int fontSize;
  final int borderRadius;
  final int height;

  const NumpadDelete(
      {super.key,
      required this.controller,
      required this.fontSize,
      required this.borderRadius,
      required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: height.toDouble(),
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.lightGrey,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(borderRadius.toDouble()))),
          onPressed: () {
            HapticFeedback.vibrate();

            if (controller.text.isNotEmpty) {
              controller.text =
                  controller.text.substring(0, controller.text.length - 1);
            }
          },
          child: Center(
            child: Icon(
              Icons.arrow_back,
              color: AppStyles.black,
              size: fontSize.toDouble(),
            ),
          )),
    );
  }
}

class NumpadOK extends StatelessWidget {
  final VoidCallback onOKPressed;

  const NumpadOK({super.key, required this.onOKPressed});

  @override
  Widget build(BuildContext context) {
    return (SizedBox(
      width: 80,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppStyles.blue,
          elevation: 0,
        ),
        onPressed: () {
          HapticFeedback.vibrate();

          onOKPressed();
        },
        child: Center(
          child: Text(
            "OK",
            style: AppStyles.heading3.copyWith(color: AppStyles.white),
          ),
        ),
      ),
    ));
  }
}
