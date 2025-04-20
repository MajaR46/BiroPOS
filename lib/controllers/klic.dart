import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<String>> sendRequest(String userSifra, String txtData) async {
  final prefs = await SharedPreferences.getInstance();
  String apiKey = prefs.getString('apiKey') ?? '';
  String ip = prefs.getString('IP') ?? '';
  String port = prefs.getString('Port') ?? '';
  String podjetjeDavcna = prefs.getString('podjetjeDavcna') ?? '';

  print("podjetje davcna $podjetjeDavcna");

  String url = 'http://$ip:$port/api/biropos';

  final Map<String, String> headers = {
    'api-key': apiKey,
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'BiroPOS URI Client/2.0',
    'company-tax': podjetjeDavcna
  };

  final String formattedDate =
      DateFormat('yyyyMMdd_HHmmss_SSS').format(DateTime.now());
  final String uniqueUid = 'android_${userSifra}_abcdef_$formattedDate';

  final String body = '{"uid":"$uniqueUid","txt_data":"$txtData"}';
  print("body $body");

  try {
    final response = await http
        .post(
      Uri.parse(url),
      headers: headers,
      body: body,
    )
        .timeout(Duration(seconds: 5), onTimeout: () {
      throw TimeoutException("Connection timed out: ni povezave");
    });

    print("response $response");
    var newHeader = response.headers
      ..["content-type"] = "application/json; text=plain; *=*";

    if (response.statusCode == 200) {
      String responseBody = response.body;

      // Process the response as before
      final RegExp resultRegex =
          RegExp(r'"result"\s*:\s*"(.*?)"', dotAll: true);
      final match = resultRegex.firstMatch(responseBody);

      if (match != null) {
        String result = match.group(1) ?? "";
        result = result
            .replaceAll('\t', '|')
            .replaceAll('\n', '_')
            .replaceAll('#tb#', '|')
            .replaceAll('#nl#', '_');
        var splittedResult = result.split('_');

        // Save the result in SharedPreferences based on txtData
        prefs.setStringList(txtData, splittedResult);

        return splittedResult;
      } else {
        return ['Result field not found in response'];
      }
    } else if (response.statusCode == 400) {
      print("bad request");
      throw Exception('Request failed with status 400: Bad Request');
    } else {
      return [
        'Request failed with status: ${response.statusCode} - Body: ${response.body}'
      ];
    }
  } on SocketException catch (e) {
    throw Exception(
        'Težava pri vzpostavljanju povezave s strežnikom. Ni vzpostavljene internetne povezave ${e.message}');
  } on TimeoutException catch (e) {
    throw Exception('Timeout Error: ${e.message}');
  } catch (e) {
    rethrow;
  }
}
