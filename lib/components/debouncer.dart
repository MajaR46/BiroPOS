import 'dart:async';

import 'package:flutter/material.dart';

class Debouncer {
  final int miliseconds;
  Timer? _timer;

  Debouncer({required this.miliseconds});

  void debouce(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: miliseconds), action);
  }

  void dispose() {
    _timer?.cancel(); // Cancel the timer when the debouncer is disposed
  }
}
