import 'package:biro_pos/components/blagajna_banner.dart';
import 'package:biro_pos/components/klic.dart';
import 'package:flutter/material.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  String response = "";

  Future<void> _handleData() async {
    List<String> apiResponseList = await sendRequest("1", "BiroPOS.txt");
    String apiResponse = apiResponseList.join(', ');

    setState(() {
      response = apiResponse;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              ElevatedButton(
                onPressed: _handleData, // Call _handleData when pressed
                child: const Text("Show"),
              ),
              const SizedBox(height: 20), // Add some spacing
              Text(response), // Display the response
            ],
          ),
        ),
      ),
    );
  }
}
