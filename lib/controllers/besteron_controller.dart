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
        "POIID": TID,
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

  // Log request details
  print("Sending request to Besteron...");
  print("Request URL: $baseUrl/$path");
  print("Request Body: ${jsonEncode(requestBody)}");
  print("Authorization Header: $authorizationHeader");

  try {
    // Sending the HTTP request
    final response = await http.post(
      Uri.parse('$baseUrl/$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authorizationHeader,
      },
      body: jsonEncode(requestBody),
    );

    // Log response status and body
    print("Response Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    // Parse the response
    var decodedJson = jsonDecode(response.body);

    var paymentReceipt =
        decodedJson['SaleToPOIResponse']?['PaymentResponse']?['PaymentReceipt'];

    if (paymentReceipt != null && paymentReceipt.isNotEmpty) {
      var outputContent = paymentReceipt[0]['OutputContent'];
      if (outputContent != null && outputContent['OutputText'] != null) {
        List<String> textList = List<String>.from(
            outputContent['OutputText'].map((item) => item['Text']));

        String receiptText = textList.join('\n');
        return receiptText;
      }
    } else {
      print("Payment receipt is empty or not found in the response.");
    }
  } catch (e) {
    print("Error occurred while calling Besteron: $e");
    return "";
  }

  return "";
}
