import 'dart:async';

import 'package:BiroPOS/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ClockWidget extends StatefulWidget {
  const ClockWidget({super.key});

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  String _formattedTime = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime(); // Takoj nastavimo čas
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _formattedTime = DateFormat("HH:mm").format(DateTime.now());
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Uporabite isti stil, kot ste ga imeli prej v AppBaru
    return Text(
      _formattedTime,
      style: AppStyles.paragraph3
          .copyWith(color: AppStyles.blue, fontWeight: FontWeight.bold),
    );
  }
}
