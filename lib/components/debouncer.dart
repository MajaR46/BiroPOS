import 'dart:async';

import 'package:flutter/material.dart';

class Debouncer {
  final int seconds;
  Timer? _timer;

  Debouncer({required this.seconds});

  void debouce(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(seconds: seconds), action);
  }
}
