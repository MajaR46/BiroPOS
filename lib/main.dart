import 'dart:io';

import 'package:BiroPOS/components/narocilo.dart';
import 'package:BiroPOS/hive_adaprters/blagajna.dart';
import 'package:BiroPOS/hive_adaprters/dummy.dart';

import 'package:BiroPOS/hive_adaprters/osebje.dart';
import 'package:BiroPOS/hive_adaprters/podjetje.dart';
import 'package:BiroPOS/models/item.dart';
import 'package:BiroPOS/models/narociloitem.dart';
import 'package:BiroPOS/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final prefs = await SharedPreferences.getInstance();
  final firstRun = prefs.getBool('first_run') ?? true;

  if (firstRun) {
    await Hive.deleteBoxFromDisk('biroposData');
    await Hive.deleteBoxFromDisk('sessionBox');
    await Hive.deleteBoxFromDisk('narociloBox');

    // Označi, da aplikacija ni več "prvi zagon"
    await prefs.setBool('first_run', false);
  }

  Hive.registerAdapter(OsebjeAdapter());
  Hive.registerAdapter(PodjetjeAdapter());
  Hive.registerAdapter(BlagajnaAdapter());
  Hive.registerAdapter(ItemAdapter());
  Hive.registerAdapter(NarociloItemAdapter());

  await Hive.openBox('sessionBox');
  await Hive.openBox('biroposData');
  await Hive.openBox('narociloBox');
  Hive.box('sessionBox').clear();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  if (Platform.isWindows) {
    final appDirectory = path.dirname(Platform.resolvedExecutable);

    final biroPosPrinterPath =
        path.join(appDirectory, 'BiroPOSPrintServer.exe');

    Process.start(biroPosPrinterPath, []).then((process) {}).catchError((e) {});
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
