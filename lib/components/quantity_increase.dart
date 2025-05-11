import 'package:flutter/material.dart';
import 'package:BiroPOS/app_styles.dart';
import 'package:flutter/services.dart';

class QuantityIncrease extends StatefulWidget {
  final double quantity;
  final Function(double) onQuantityChanged;

  const QuantityIncrease(
      {super.key, required this.quantity, required this.onQuantityChanged});

  @override
  QuantityIncreaseState createState() => QuantityIncreaseState();
}

class QuantityIncreaseState extends State<QuantityIncrease> {
  late double _currentQuantity;

  @override
  void initState() {
    super.initState();
    _currentQuantity = widget.quantity;
  }

  @override
  void didUpdateWidget(covariant QuantityIncrease oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quantity != _currentQuantity) {
      _currentQuantity = widget.quantity;
    }
  }

  void _increase() {
    if (_currentQuantity % 1 == 0) {
      setState(() {
        _currentQuantity++;
        widget.onQuantityChanged(_currentQuantity);
      });
    }
  }

  void _decrease() {
    if (_currentQuantity > 1 && _currentQuantity % 1 == 0) {
      setState(() {
        _currentQuantity =
            double.parse((_currentQuantity - 1).toStringAsFixed(2));
        widget.onQuantityChanged(_currentQuantity);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppStyles.silver.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 32,
              width: 32,
              child: IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: AppStyles.white),
                iconSize: 16,
                onPressed: () {
                  _decrease();
                  HapticFeedback.vibrate();
                },
                icon: const Icon(
                  Icons.remove,
                  color: AppStyles.black,
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${_currentQuantity.toStringAsFixed(1)}',
                style:
                    AppStyles.heading4.copyWith(fontWeight: FontWeight.normal),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 32,
              width: 32,
              child: IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: AppStyles.white),
                iconSize: 16,
                onPressed: () {
                  _increase();
                  HapticFeedback.vibrate();
                },
                icon: const Icon(
                  Icons.add,
                  color: AppStyles.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
