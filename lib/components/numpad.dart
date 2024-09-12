import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';

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
            NumpadNumber(number: "1", controller: controller),
            NumpadNumber(number: "2", controller: controller),
            NumpadNumber(number: "3", controller: controller)
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
            NumpadNumber(number: "7", controller: controller),
            NumpadNumber(number: "8", controller: controller),
            NumpadNumber(number: "9", controller: controller)
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NumpadDelete(controller: controller),
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
            backgroundColor: AppStyles.silver.withOpacity(0.1),
            elevation: 0,
          ),
          onPressed: () {
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

  const NumpadDelete({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return (SizedBox(
      width: 80,
      height: 60,
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppStyles.silver.withOpacity(0.1),
            elevation: 0,
          ),
          onPressed: () {
            if (controller.text.isNotEmpty) {
              controller.text =
                  controller.text.substring(0, controller.text.length - 1);
            }
          },
          child: const Center(
            child: Icon(
              Icons.arrow_back,
              color: AppStyles.black,
              size: 24,
            ),
          )),
    ));
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
        onPressed: onOKPressed,
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
