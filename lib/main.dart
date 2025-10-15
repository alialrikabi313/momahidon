import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:momahidon/screens/login_screen.dart';
import 'package:momahidon/screens/home_screen.dart';
import 'package:momahidon/screens/signup_screen.dart';
import 'package:momahidon/screens/forgot_password_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // تهيئة Firebase
  await Firebase.initializeApp();

  // قراءة الـ SharedPreferences لمعرفة ما إذا كان المستخدم مسجّل دخوله أم لا
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'الممهد',
      // إذا كان المستخدم مسجل دخول مسبقاً نذهب مباشرة للصفحة الرئيسية، وإلا صفحة تسجيل الدخول
      initialRoute: isLoggedIn ? '/home' : '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
