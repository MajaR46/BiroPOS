import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

Future<Map<String, String>> inetisCall(String davcnaSt) async {
  String url = 'https://ddv.inetis.com/Iskalnik2.asmx?';

  var envelope = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
               xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
               xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <Isci xmlns="http://ddv.inetis.com/">
      <iskalni_niz>$davcnaSt</iskalni_niz>
    </Isci>
  </soap:Body>
</soap:Envelope>''';

  final Map<String, String> headers = {
    'Content-Type': 'text/xml',
    'SOAPAction': '"http://ddv.inetis.com/Isci"'
  };

  try {
    final response = await http
        .post(Uri.parse(url), headers: headers, body: envelope)
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      // Parsiranje XML
      var document = xml.XmlDocument.parse(response.body);
      var naziv = document.findAllElements('xmlNaziv').first.text;

      var naslov = document.findAllElements('xmlNaslov').first.text;

      Map<String, String> rezultat = {'naziv': naziv, 'naslov': naslov};

      return rezultat;
    } else {
      print('Napaka: ${response.statusCode}');
      return {'naziv': 'Ni podatka o nazivu', 'naslov': 'Ni podatka o naslovu'};
    }
  } catch (e) {
    return {'naziv': 'Ni podatka o nazivu', 'naslov': 'Ni podatka o naslovu'};
  }
}
