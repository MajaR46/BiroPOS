import 'package:biro_pos/controllers/sessionmanager.dart';
import 'package:biro_pos/hive_adaprters/osebje.dart';
import 'package:biro_pos/hive_adaprters/podjetje.dart';
import 'package:biro_pos/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(OsebjeAdapter());
  Hive.registerAdapter(PodjetjeAdapter());
  await Hive.openBox('sessionBox');
  await Hive.openBox('biroposData');

  Hive.box('sessionBox').clear();

  WidgetsBinding.instance.addObserver(_SystemUiObserver());

  // Set to immersive sticky mode
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class _SystemUiObserver with WidgetsBindingObserver {
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
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
