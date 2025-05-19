import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, dynamic>> callBesteron(double finalSum) async {
  final prefs = await SharedPreferences.getInstance();
  final roundedFinalSum = double.parse(finalSum.toStringAsFixed(2));

  String? posUrlNastavitve = prefs.getString('POS');

  if (posUrlNastavitve == null || posUrlNastavitve.isEmpty) {
    throw Exception("Ni nastavitev POS.");
  }

  List<String> posurl = posUrlNastavitve.split(';');
  if (posurl.length < 3) {
    throw Exception("POS nastavitve so nepravilne.");
  }

  String baseUrl = posurl[1];
  String path = posurl[0];
  String authCredentials = posurl[2];

  String? TID = prefs.getString('TID');
  String? podjetjeDavcna = prefs.getString('podjetjeDavcna');

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
          "AmountsReq": {"Currency": "EUR", "RequestedAmount": roundedFinalSum},
          "ProprietaryTags": {"PrintReceipt": false}
        },
        "PaymentData": {"PaymentType": "Normal"}
      }
    }
  };

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authorizationHeader,
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception(
          "POS terminal error: HTTP ${response.statusCode} - ${response.reasonPhrase}");
    }

    var decodedJson = jsonDecode(response.body);

    var saleToPOIResponse = decodedJson['SaleToPOIResponse'];
    if (saleToPOIResponse == null) {
      throw Exception("Invalid POS response: SaleToPOIResponse missing");
    }

    var paymentResponse = saleToPOIResponse['PaymentResponse'];
    if (paymentResponse == null) {
      throw Exception("Invalid POS response: PaymentResponse missing");
    }

    var result = paymentResponse['Response']?['Result'] ?? 'Failure';

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
    throw Exception("Besteron napaka: $e");
  }
}

Future<List<String>> besteronPorocilo() async {
  final prefs = await SharedPreferences.getInstance();
  String? podjetjeDavcna = prefs.getString('podjetjeDavcna');
  String? TID = prefs.getString('TID');
  String guid = DateTime.now().millisecondsSinceEpoch.toString();

  String? posUrlNastavitve = prefs.getString('POS');

  if (posUrlNastavitve == null || posUrlNastavitve.isEmpty) {
    throw Exception("Ni nastavitev POS.");
  }

  List<String> posurl = posUrlNastavitve.split(';');
  if (posurl.length < 3) {
    throw Exception("POS nastavitve so nepravilne.");
  }

  String baseUrl = posurl[1];
  String path = posurl[0];
  String authCredentials = posurl[2];

  String authorizationHeader = 'Basic $authCredentials';

  Map<String, dynamic> requestBody = {
    "SaleToPOIRequest": {
      "MessageHeader": {
        "MessageType": "Request",
        "MessageClass": "Service",
        "MessageCategory": "Reconciliation",
        "SaleID": podjetjeDavcna,
        "POIID": TID,
        "ProtocolVersion": "3.1",
        "ServiceID": guid
      },
      "ReconciliationRequest": {"ReconciliationType": "AcquirerReconciliation"}
    }
  };

  try {
    final response = await http.post(Uri.parse('$baseUrl/$path'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authorizationHeader
        },
        body: jsonEncode(requestBody));

    if (response.statusCode != 200) {
      throw Exception(
          "POS terminal error: HTTP ${response.statusCode} - ${response.reasonPhrase}");
    }

    List<String> porocilo = [];
    var decodedResponse = jsonDecode(response.body);

    DateTime currentDate = DateTime.now();
    String formattedDate = DateFormat("dd.MM.yyyy").format(currentDate);
    String formattedTime = DateFormat("HH:mm").format(currentDate);

    List<dynamic> paymentTotals = decodedResponse["SaleToPOIResponse"]
        ["ReconciliationResponse"]["TransactionTotals"][0]["PaymentTotals"];

    porocilo.add("Datum: $formattedDate  $formattedTime");

    for (var transaction in paymentTotals) {
      porocilo.add("Tip: ${transaction["TransactionType"]}");
      porocilo.add("Znesek: ${transaction["TransactionAmount"]}");
      porocilo.add("Stevilo: ${transaction["TransactionCount"]}");
      porocilo.add("--------------------------------");
    }
    return porocilo;
  } catch (e, stackTrace) {
    throw Exception("Besteron napaka: $e");
  }
}

Future<Map<String, dynamic>> besteronVracilo(double vraciloAmount) async {
  final prefs = await SharedPreferences.getInstance();

  String? podjetjeDavcna = prefs.getString('podjetjeDavcna');
  String? TID = prefs.getString('TID');
  String guid = DateTime.now().millisecondsSinceEpoch.toString();
  final roundedVracilo = double.parse(vraciloAmount.toStringAsFixed(2));

  String? posUrlNastavitve = prefs.getString('POS');

  if (posUrlNastavitve == null || posUrlNastavitve.isEmpty) {
    throw Exception("Ni nastavitev POS.");
  }

  List<String> posurl = posUrlNastavitve.split(';');
  if (posurl.length < 3) {
    throw Exception("POS nastavitve so nepravilne.");
  }

  String baseUrl = posurl[1];
  String path = posurl[0];
  String authCredentials = posurl[2];
  String authorizationHeader = 'Basic $authCredentials';

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
          "AmountsReq": {"Currency": "EUR", "RequestedAmount": roundedVracilo},
          "ProprietaryTags": {"PrintReceipt": false}
        },
        "PaymentData": {"PaymentType": "Refund"}
      }
    }
  };

  try {
    final response = await http.post(Uri.parse('$baseUrl/$path'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authorizationHeader
        },
        body: jsonEncode(requestBody));

    if (response.statusCode != 200) {
      throw Exception(
          "POS terminal error: HTTP ${response.statusCode} - ${response.reasonPhrase}");
    }

    var decodedJson = jsonDecode(response.body);

    var saleToPOIResponse = decodedJson['SaleToPOIResponse'];
    if (saleToPOIResponse == null) {
      throw Exception("Invalid POS response: SaleToPOIResponse missing");
    }

    var paymentResponse = saleToPOIResponse['PaymentResponse'];
    if (paymentResponse == null) {
      throw Exception("Invalid POS response: PaymentResponse missing");
    }

    var result = paymentResponse['Response']?['Result'] ?? 'Failure';

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
    throw Exception("Besteron napaka: $e");
  }
}
