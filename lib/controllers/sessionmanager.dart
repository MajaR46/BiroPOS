import 'package:hive/hive.dart';

class SessionManager {
  final Box _box = Hive.box('sessionBox');

  void saveSession(String username, String sifra) {
    _box.put('loggedInUserName', username);
    _box.put('loggedInUserSifra', sifra);
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

  void clearSession() {
    _box.delete('loggedInUserName');
    _box.delete('loggedInUserSifra');
  }
}
