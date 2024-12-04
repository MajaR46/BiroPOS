import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<String>> sendRequest(String userSifra, String txtData) async {
  final prefs = await SharedPreferences.getInstance();
  String apiKey = prefs.getString('apiKey') ?? '';
  String ip = prefs.getString('IP') ?? '';
  String port = prefs.getString('Port') ?? '';

  String url = 'http://$ip:$port/api/biropos';

  final Map<String, String> headers = {
    'api-key': apiKey,
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'BiroPOS URI Client/2.0'
  };

  final String formattedDate =
      DateFormat('yyyyMMdd_HHmmss_SSS').format(DateTime.now());
  final String uniqueUid = 'android_${userSifra}_abcdef_$formattedDate';

  final String body = '{"uid":"$uniqueUid","txt_data":"$txtData"}';

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

      // Process the response as before
      final RegExp resultRegex =
          RegExp(r'"result"\s*:\s*"(.*?)"', dotAll: true);
      final match = resultRegex.firstMatch(responseBody);

      if (match != null) {
        String result = match.group(1) ?? "";
        result = result.replaceAll('\t', '|').replaceAll('\n', '_');
        var splittedResult = result.split('_');

        // Save the result in SharedPreferences based on txtData
        prefs.setStringList(txtData, splittedResult);

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
    return ['Error occurred: $e'];
  }
}
