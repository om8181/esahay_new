import 'package:flutter/material.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'signup_page.dart';

/// 🌍 App Language Enum
enum AppLanguage { en, hi, mr }

/// 🌍 Global Language Controller
ValueNotifier<AppLanguage> appLanguage =
ValueNotifier<AppLanguage>(AppLanguage.en);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, lang, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'GovScheme Connect',

          // ✅ AUTO LOGIN
          home: const LoginPage(),

          // ✅ ROUTES
          routes: {
            '/home': (context) => const HomePage(),
            '/login': (context) => const LoginPage(),
            '/signup': (context) => const SignupPage(),
          },
        );
      },
    );
  }
}