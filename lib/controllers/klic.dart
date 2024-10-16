import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

Future<List<String>> sendRequest(String userSifra, String txtData) async {
  final String url = 'http://84.255.204.40:8443/api/biropos';

  final Map<String, String> headers = {
    'api-key': '176FCBFB',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'BiroPOS URI Client/2.0'
  };

  final String formattedDate =
      DateFormat('yyyyMMdd_HHmmss_SSS').format(DateTime.now());
  final String uniqueUid = 'android_${userSifra}_abcdef_$formattedDate';

  final Map<String, dynamic> data = {
    'uid': uniqueUid,
    'txt_data': txtData,
  };

  final String body = jsonEncode(data);

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    var newHeader = response.headers
      ..["content-type"] = "application/json; text=plain; *=*";

    if (response.statusCode == 200) {
      String responseBody = response.body;

      // extract vrednost result fielda
      final RegExp resultRegex =
          RegExp(r'"result"\s*:\s*"(.*?)"', dotAll: true);
      final match = resultRegex.firstMatch(responseBody);

      if (match != null) {
        // Pridobi result field
        String result = match.group(1) ?? "";

        // Clean up the result value (trim or process as needed)
        result = result.replaceAll('\t', '|').replaceAll('\n', '_');
        var splittedResult = result.split('_');

        return splittedResult;
      } else {
        return ['Result field not found in response'];
      }
    } else {
      return [
        'Request failed with status: ${response.statusCode} - Body: ${response.body}'
      ];
    }
  } catch (e) {
    print('Error occurred: $e');
    return ['Error occurred: $e'];
  }
}
