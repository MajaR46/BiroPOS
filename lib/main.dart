import 'package:BiroPOS/controllers/sessionmanager.dart';
import 'package:BiroPOS/hive_adaprters/blagajna.dart';
import 'package:BiroPOS/hive_adaprters/osebje.dart';
import 'package:BiroPOS/hive_adaprters/podjetje.dart';
import 'package:BiroPOS/screens/login.dart';
import 'package:BiroPOS/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(OsebjeAdapter());
  Hive.registerAdapter(PodjetjeAdapter());
  Hive.registerAdapter(BlagajnaAdapter());
  await Hive.openBox('sessionBox');
  await Hive.openBox('biroposData');

  Hive.box('sessionBox').clear();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final bool loggedIn = SessionManager().isLoggedIn();
    print(loggedIn);
    return const MaterialApp(
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
