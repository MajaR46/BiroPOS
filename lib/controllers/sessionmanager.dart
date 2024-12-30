import 'package:hive/hive.dart';

class SessionManager {
  final Box _box = Hive.box('sessionBox');

  void saveSession(String username, String sifra, String? pravicaStorno,
      String? pravicaPregledPorocil) {
    _box.put('loggedInUserName', username);
    _box.put('loggedInUserSifra', sifra);
    _box.put('pravicaStorno', pravicaStorno);
    _box.put('pravicaPregledPorocil', pravicaPregledPorocil);
  }

  String? getLoggedInUserName() {
    return _box.get('loggedInUserName');
  }

  String? getLoggedInUserSifra() {
    return _box.get('loggedInUserSifra');
  }

  bool isLoggedIn() {
    return _box.containsKey('loggedInUserSifra');
  }

  String? pravicaStorno() {
    return _box.get('pravicaStorno');
  }

  String? pravicaPregledPorocil() {
    return _box.get('pravicaPregledPorocil');
  }

  void clearSession() {
    _box.delete('loggedInUserName');
    _box.delete('loggedInUserSifra');
  }
}
