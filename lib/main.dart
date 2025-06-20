import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Firebase/App Checkを初期化する ※Geminiの呼び出しに必要
  await FirebaseAppCheck.instance.activate(androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity, appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck);

  // Sign in anonymously at app startup
  try {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();

      print('Anonymous sign-in successful at startup');
    } else {
      print('User already signed in: ${auth.currentUser!.uid}');
    }
  } catch (e) {
    print('Error during initial sign-in: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'よみあげくん',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 78, 165, 112)), useMaterial3: true),
        home: const HomeScreen(),
      ),
    );
  }
}
