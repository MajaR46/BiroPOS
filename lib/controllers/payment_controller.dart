import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart'; // For Base64 encoding/decoding

Future<String> callBesteron(double finalSum) async {
  final prefs = await SharedPreferences.getInstance();
  String? posUrlNastavitve = prefs.getString('POS') ?? "";

  List<String> posurl = posUrlNastavitve.split(';');

  String baseUrl = posurl[1];
  String path = posurl[0];

  String authCredentials = posurl[2];

  String TID = prefs.getString('TID') ?? '';

  String authorizationHeader = 'Basic $authCredentials';

  String podjetjeDavcna = prefs.getString('podjetjeDavcna') ?? '';

  String guid = DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> requestBody = {
    "SaleToPOIRequest": {
      "MessageHeader": {
        "MessageType": "Request",
        "MessageClass": "Service",
        "MessageCategory": "Payment",
        "SaleID": podjetjeDavcna,
        "POIID": TID, //
        "ProtocolVersion": "3.1",
        "ServiceID": guid
      },
      "PaymentRequest": {
        "SaleData": {
          "SaleTransactionID": {
            "TransactionID": guid,
            "TimeStamp": DateTime.now().toIso8601String()
          }
        },
        "PaymentTransaction": {
          "AmountsReq": {"Currency": "EUR", "RequestedAmount": finalSum},
          "ProprietaryTags": {"PrintReceipt": false}
        },
        "PaymentData": {"PaymentType": "Normal"}
      }
    }
  };

  try {
    // Make the POST request
    final response = await http.post(
      Uri.parse('$baseUrl/$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authorizationHeader,
      },
      body: jsonEncode(requestBody), // Convert the body to JSON
    );

    // Print the raw response body for debugging
    print('Response Body: ${response.body}');

    var decodedJson = jsonDecode(response.body);

    // Check if 'PaymentResponse' and 'PaymentReceipt' exist in the response
    var paymentReceipt =
        decodedJson['SaleToPOIResponse']?['PaymentResponse']?['PaymentReceipt'];

    if (paymentReceipt != null && paymentReceipt.isNotEmpty) {
      // Extracting OutputText if available
      var outputContent = paymentReceipt[0]['OutputContent'];
      if (outputContent != null && outputContent['OutputText'] != null) {
        List<String> textList = List<String>.from(
            outputContent['OutputText'].map((item) => item['Text']));

        // Join the list into a single string for display in the modal
        String receiptText = textList.join('\n');
        return receiptText; // Return the receipt text
      }
    }
  } catch (e) {
    print("napaka: $e");
    return ""; // Return empty string in case of error
  }

  return ""; // Return empty string if no receipt text is found
}
