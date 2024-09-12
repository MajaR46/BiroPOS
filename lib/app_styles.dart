import 'package:flutter/material.dart';

class AppStyles {
  static const Color black = Color(0xff282828);
  static const Color white = Color(0xfffcfcfc);
  static const Color grey = Color(0xffF7F7F7);
  static const Color blue = Color(0xff2D70F4);
  static const Color silver = Color(0xFFBFBFBF);

  static const TextStyle heading1 = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.bold,
    fontSize: 32,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.bold,
    fontSize: 24,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: 'Helvetica',
    fontWeight: FontWeight.bold,
    fontSize: 20,
  );

  static const TextStyle heading4 = TextStyle(
    fontFamily: 'Helvetica',
    fontWeight: FontWeight.w600, // Semi Bold
    fontSize: 18,
  );

  static const TextStyle paragraph1 = TextStyle(
    fontFamily: 'Helvetica',
    fontWeight: FontWeight.normal,
    fontSize: 16,
  );

  static const TextStyle paragraph2 = TextStyle(
    fontFamily: 'Helvetica',
    fontWeight: FontWeight.normal,
    fontSize: 14,
  );

  static const TextStyle paragraph3 = TextStyle(
    fontFamily: 'Helvetica',
    fontWeight: FontWeight.normal,
    fontSize: 12,
  );

  static const TextStyle button1 = TextStyle(
    fontFamily: 'Helvetica',
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  static const TextStyle button2 = TextStyle(
    fontFamily: 'Helvetica',
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );
}
