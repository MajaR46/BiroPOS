import 'dart:async';

import 'package:BiroPOS/controllers/klic.dart';

Future<bool> testConnection(String userId) async {
  try {
    List<String> responseList =
        await sendRequest(userId, "echo").timeout(const Duration(seconds: 2));
    if (responseList.isEmpty ||
        responseList.any((line) => line.contains("Napaka"))) {
      return false;
    }
    return true;
  } on TimeoutException {
    return false;
  } catch (e) {
    return false;
  }
}
