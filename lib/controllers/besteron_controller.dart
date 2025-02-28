import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, dynamic>> callBesteron(double finalSum) async {
  final prefs = await SharedPreferences.getInstance();
  print("Fetching POS settings...");

  String? posUrlNastavitve = prefs.getString('POS');
  print("POS settings: $posUrlNastavitve");

  if (posUrlNastavitve == null || posUrlNastavitve.isEmpty) {
    throw Exception("POS settings are missing or empty.");
  }

  List<String> posurl = posUrlNastavitve.split(';');
  if (posurl.length < 3) {
    throw Exception("POS settings are incorrectly formatted.");
  }

  String baseUrl = posurl[1];
  String path = posurl[0];
  String authCredentials = posurl[2];

  String? TID = prefs.getString('TID');
  String? podjetjeDavcna = prefs.getString('podjetjeDavcna');

  print("TID: $TID");
  print("Podjetje Davčna: $podjetjeDavcna");

  if (TID == null || podjetjeDavcna == null) {
    throw Exception("TID or podjetjeDavcna is missing.");
  }

  String authorizationHeader = 'Basic $authCredentials';
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

  print("Request Body: ${jsonEncode(requestBody)}");

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authorizationHeader,
      },
      body: jsonEncode(requestBody),
    );

    print("Response Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception(
          "POS terminal error: HTTP ${response.statusCode} - ${response.reasonPhrase}");
    }

    var decodedJson = jsonDecode(response.body);
    print("Decoded JSON: $decodedJson");

    var saleToPOIResponse = decodedJson['SaleToPOIResponse'];
    if (saleToPOIResponse == null) {
      throw Exception("Invalid POS response: SaleToPOIResponse missing");
    }

    var paymentResponse = saleToPOIResponse['PaymentResponse'];
    if (paymentResponse == null) {
      throw Exception("Invalid POS response: PaymentResponse missing");
    }

    var result = paymentResponse['Response']?['Result'] ?? 'Failure';
    print("Payment Result: $result");

    var receipt = "";

    var paymentReceipt = paymentResponse['PaymentReceipt'];
    if (paymentReceipt != null && paymentReceipt.isNotEmpty) {
      var outputContent = paymentReceipt[0]['OutputContent'];
      if (outputContent != null && outputContent['OutputText'] != null) {
        receipt =
            outputContent['OutputText'].map((item) => item['Text']).join("\n");
      }
    }

    return {
      "result": result,
      "receipt": receipt,
    };
  } catch (e, stackTrace) {
    print("Error: $e");
    print("StackTrace: $stackTrace");
    throw Exception("Besteron call error: $e");
  }
}
