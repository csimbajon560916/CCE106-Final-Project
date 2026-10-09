import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PryceHatidApp());
}

class PryceHatidApp extends StatelessWidget {
  const PryceHatidApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PryceHatid',
      debugShowCheckedModeBanner: false,
      theme: PryceTheme.lightTheme,
      home: const AuthWrapper(), // Hands over routing to AuthWrapper
    );
  }
}