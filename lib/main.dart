import 'dart:io';

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
import 'package:path/path.dart' as path;

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

  if (Platform.isWindows) {
    final appDirectory = path.dirname(Platform.resolvedExecutable);

    print("appdirectory $appDirectory");
    final biroPosPrinterPath =
        path.join(appDirectory, 'BiroPOSPrintServer.exe');

    Process.start(biroPosPrinterPath, []).then((process) {
      print("aplikacija je zagnana");
    }).catchError((e) {
      print("napaka pri zagonu $e");
    });
  }
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
