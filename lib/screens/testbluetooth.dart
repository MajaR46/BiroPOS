import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({Key? key}) : super(key: key);

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  final FocusNode _focusNode = FocusNode();

  String _controller = '';

  String? _message;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).requestFocus(_focusNode);
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: DefaultTextStyle(
        style: TextStyle(color: Colors.amber),
        child: RawKeyboardListener(
          focusNode: _focusNode,
          onKey: (RawKeyEvent event) {
            if (event is RawKeyDownEvent) {
              if (event.physicalKey == PhysicalKeyboardKey.enter) {
                setState(() {
                  _message = _controller;
                  _controller = '';
                });
              } else {
                print(
                    '_handleKeyEvent Event data keyLabel ${event.data.keyLabel}');
                _controller += event.data.keyLabel;
              }
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _message ?? 'Press a key',
              ),
              Text(
                '${_message?.length}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
