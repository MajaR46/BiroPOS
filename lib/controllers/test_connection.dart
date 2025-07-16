import 'dart:async';

import 'package:BiroPOS/controllers/klic.dart';

Future<bool> testConnection(String userId) async {
  try {
    List<String> responseList =
        await sendRequest(userId, "echo").timeout(const Duration(seconds: 2));

    return responseList.isNotEmpty;
  } on TimeoutException {
    return false;
  } catch (e) {
    return false;
  }
}
