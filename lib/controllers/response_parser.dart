enum ResponseCategory { izdelki, dodatki, osebje }

class ResponseItem {
  final String ime;
  final ResponseCategory kategorija;

  ResponseItem(this.ime, this.kategorija);

  @override
  String toString() {
    return ime;
  }
}

class Izdelek extends ResponseItem {
  final String cena;
  final String podkategorija;
  final String eanKoda;

  Izdelek(String ime, this.cena, this.podkategorija, this.eanKoda)
      : super(ime, ResponseCategory.izdelki);
}

class Dodatki extends ResponseItem {
  final String cena;

  Dodatki(String ime, this.cena) : super(ime, ResponseCategory.dodatki);
}

class Osebje extends ResponseItem {
  Osebje(String ime) : super(ime, ResponseCategory.osebje);
}

class ResponseParser {
  static Map<String, List<dynamic>> categorizeItems(List<String> items) {
    Map<String, List<dynamic>> categorizedItems = {
      'osebje': [],
      'izdelki': [],
      'dodatki': [],
    };

    for (String item in items) {
      if (item.startsWith('1')) {
        // Izdelek category
        String imeIzdelka = item.split('|')[2];
        String cena = item.split('|')[3];
        String podkategorija = item.split('|')[5];
        String eanKoda = item.split('|')[6];

        categorizedItems['izdelki']?.add(
          Izdelek(imeIzdelka, cena, podkategorija, eanKoda),
        );
      } else if (item.startsWith('2')) {
        // Dodatki category
        String imeDodatka = item.split('|')[2];
        String cena = item.split('|')[3];

        categorizedItems['dodatki']?.add(
          Dodatki(imeDodatka, cena),
        );
      } else if (item.startsWith('3')) {
        // Osebje category
        String imeOsebja = item.split('|')[2];

        categorizedItems['osebje']?.add(
          Osebje(imeOsebja),
        );
      }
    }

    return categorizedItems;
  }
}
