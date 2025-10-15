import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../colors.dart';
import '../widgets/header_clipper.dart';
import '../widgets/rounded_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _sending = false;               // لعرض مؤشّر تحميل صغير

  //————————————————— إرسال رابط إعادة التعيين
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    // تحقّق سريع من أنّ الحقل غير فارغ
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رجاءً أدخل بريدك الإلكتروني')),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني'),
        ),
      );

      // الرجوع للشاشة السابقة بعد نجاح الإرسال (اختياري)
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      // التعامل مع بعض الأخطاء الشائعة من Firebase
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'لا يوجد مستخدم بهذا البريد';
          break;
        case 'invalid-email':
          msg = 'تنسيق البريد الإلكتروني غير صالح';
          break;
        default:
          msg = 'حدث خطأ: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }

    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,          // خلفية خفيفة
      body: SingleChildScrollView(
        child: Column(
          children: [
            /*---------------- رأس الصفحة المُمَوج ----------------*/
            ClipPath(
              clipper: HeaderClipper(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.3,
                color: mainColor,
                alignment: Alignment.center,
                child: const Icon(Icons.lock_reset,
                    size: 90, color: Colors.white),
              ),
            ),

            const SizedBox(height: 40),

            /*---------------- حقل البريد ----------------*/
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: RoundedTextField(
                hintText: 'أدخل بريدك الإلكتروني',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
            ),

            const SizedBox(height: 40),

            /*---------------- زر الإرسال ----------------*/
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: _sending ? null : _resetPassword,
                  child: _sending
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'إرسال رابط إعادة التعيين',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
