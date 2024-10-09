import 'package:flutter/material.dart';
import 'package:biro_pos/app_styles.dart';

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

  void _increase() {
    setState(() {
      _currentQuantity++;
      widget.onQuantityChanged(_currentQuantity);
    });
  }

  void _decrease() {
    setState(() {
      if (widget.quantity > 1) {
        _currentQuantity--;
        widget.onQuantityChanged(_currentQuantity);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppStyles.silver.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 32,
              width: 32,
              child: IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: AppStyles.white),
                iconSize: 16,
                onPressed: _decrease,
                icon: const Icon(
                  Icons.remove,
                  color: AppStyles.black,
                ),
              ),
            ),
          ),
          Text(
            '$_currentQuantity',
            style: AppStyles.heading4.copyWith(fontWeight: FontWeight.normal),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 32,
              width: 32,
              child: IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: AppStyles.white),
                iconSize: 16,
                onPressed: _increase,
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
