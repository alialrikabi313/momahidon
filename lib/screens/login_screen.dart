import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../colors.dart';
import '../widgets/header_clipper.dart';
import '../widgets/rounded_text_field.dart';
import '../widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _showError('يجب ملء كل الحقول.');
      return;
    }

    setState(() => _isLoading = true);

    // حوار تحميل يمنع التفاعل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      if (mounted) {
        Navigator.pop(context); // إغلاق مؤشر التحميل
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      _showError(_firebaseErrorToArabic(e.code));
    } catch (e) {
      Navigator.pop(context);
      _showError('حدث خطأ غير متوقّع:\n$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ترجمة سريعة لأهم أخطاء FirebaseAuth
  String _firebaseErrorToArabic(String code) {
    switch (code) {
      case 'user-not-found':
        return 'لا يوجد مستخدم بهذا البريد.';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة.';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح.';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب.';
      default:
        return 'خطأ أثناء تسجيل الدخول ($code).';
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('خطأ'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // رأس منحني ملوّن
            ClipPath(
              clipper: HeaderClipper(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.3,
                color: mainColor,
                child: const Center(
                  child: Icon(Icons.person, size: 80, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  RoundedTextField(
                    hintText: 'البريد الإلكتروني',
                    controller: _emailController,
                  ),
                  const SizedBox(height: 20),
                  RoundedTextField(
                    hintText: 'كلمة المرور',
                    obscureText: true,
                    controller: _passwordController,
                  ),
                  const SizedBox(height: 40),
                  CustomButton(
                    text: _isLoading ? 'جاري الدخول...' : 'تسجيل الدخول',
                    // ⬇️ لاحظ أنّنا نستخدم قوسين مع جسم دالة يُعيد void
                    onPressed: () {
                      if (_isLoading) return;        // متوقف مؤقتاً
                      _login();                      // تنفيذ تسجيل الدخول
                    },
                    color: mainColor,
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/forgot_password'),
                    child: const Text(
                      'هل نسيت الرمز؟',
                      style: TextStyle(color: mainColor, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => Navigator.pushNamed(context, '/signup'),
                    child: const Text(
                      'إنشاء حساب',
                      style: TextStyle(color: mainColor, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
