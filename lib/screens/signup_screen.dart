// lib/screens/sign_up_screen.dart
// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../colors.dart';
import '../widgets/header_clipper.dart';
import '../widgets/rounded_text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  /*────────────────────────── Controllers ──────────────────────────*/
  final _usernameController     = TextEditingController();
  final _emailController        = TextEditingController();
  final _passwordController     = TextEditingController();
  final _confirmPassController  = TextEditingController();

  /*────────────────────────── Dropdown data ────────────────────────*/
  // الجنس
  final List<String> _genders  = ['ذكر', 'أنثى'];
  String? _selectedGender;

  // الأعمار من 10 إلى 80
  late final List<String> _ages =
  List.generate(71, (i) => (i + 10).toString());
  String? _selectedAge;

  // بعض البلدان الإسلامية + خيار آخر
// القائمة المحدَّثة حسب المطلوب
  final List<String> _countries = [
    // ➊ اجعل العراق وإيران في البداية
    'العراق',
    'إيران',

    // ➋ بقيّة الدول ذات الأغلبية المسلمة (مرتَّبة أبجديًّا تقريبًا)
    'السعودية',
    'الإمارات',
    'أفغانستان',
    'ألبانيا',
    'أذربيجان',
    'الأردن',
    'الجزائر',
    'البحرين',
    'البوسنة والهرسك',
    'بنغلاديش',
    'بروناي',
    'باكستان',
    'تشاد',
    'تركيا',
    'تركمانستان',
    'تونس',
    'جزر القمر',
    'جيبوتي',
    'سيراليون',
    'الصومال',
    'غامبيا',
    'غينيا',
    'غينيا بيساو',
    'فلسطين',
    'قطر',
    'قرغيزستان',
    'كازاخستان',
    'كوسوفو',
    'الكويت',
    'لبنان',
    'ليبيا',
    'مالي',
    'المغرب',
    'المالديف',
    'موريتانيا',
    'ماليزيا',
    'مصر',
    'نيجيريا',
    'النيجر',
    'أوزبكستان',
    'إندونيسيا',
    'اليمن',
    'السنغال',
    'سوريا',
    'طاجيكستان',
    'عمان',
    'السودان',

    // ➌ الدول غير الإسلامية المطلوبة
    'أمريكا',
    'بريطانيا',
    'فرنسا',
    'ألمانيا',

    // ➍ الخيار الافتراضي
    'بلد آخر',
  ];

  String? _selectedCountry;

  /*────────────────────────── Sign-Up logic ────────────────────────*/
  Future<void> _signUp() async {
    // التحقق من كلمة المرور
    if (_passwordController.text.trim() !=
        _confirmPassController.text.trim()) {
      _showError('كلمة المرور غير متطابقة');
      return;
    }
    // التحقق من القوائم المنسدلة
    if (_selectedGender == null ||
        _selectedAge     == null ||
        _selectedCountry == null) {
      _showError('يرجى اختيار الجنس والعمر والبلد');
      return;
    }

    try {
      // إنشاء حساب في FirebaseAuth
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email   : _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // حفظ البيانات في Firestore  ➜  collection: users
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'username'   : _usernameController.text.trim(),
        'email'      : _emailController.text.trim(),
        'country'    : _selectedCountry,  // ← اسم الحقل: country
        'age'        : int.parse(_selectedAge!), // ← age (int)
        'gender'     : _selectedGender,   // ← gender
        'createdAt'  : DateTime.now(),
      });

      // نجاح ➜ الرجوع لشاشة تسجيل الدخول
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'حدث خطأ أثناء إنشاء الحساب');
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  /*────────────────────────── UI ───────────────────────────────────*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            /*────────── رأس بظل مائل ──────────*/
            ClipPath(
              clipper: HeaderClipper(),
              child: Container(
                height: MediaQuery.of(context).size.height * .30,
                color : mainColor,
                child : const Center(
                  child: Icon(Icons.person, size: 80, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 40),
            /*────────── حقول الإدخال ──────────*/
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  RoundedTextField(
                    hintText  : 'اسم المستخدم',
                    controller: _usernameController,
                  ),
                  const SizedBox(height: 20),
                  RoundedTextField(
                    hintText  : 'الإيميل',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  /*────────── قائمة الجنس ──────────*/
                  DropdownButtonFormField<String>(
                    decoration: _dropDecoration(label: 'الجنس'),
                    value     : _selectedGender,
                    items     : _genders
                        .map((g) => DropdownMenuItem(
                      value: g,
                      child: Text(g),
                    ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedGender = v),
                  ),
                  const SizedBox(height: 20),
                  /*────────── قائمة العمر ──────────*/
                  DropdownButtonFormField<String>(
                    decoration: _dropDecoration(label: 'العمر'),
                    value     : _selectedAge,
                    items     : _ages
                        .map((a) => DropdownMenuItem(
                      value: a,
                      child: Text(a),
                    ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedAge = v),
                  ),
                  const SizedBox(height: 20),
                  /*────────── قائمة البلد ──────────*/
                  DropdownButtonFormField<String>(
                    decoration: _dropDecoration(label: 'البلد'),
                    value     : _selectedCountry,
                    items     : _countries
                        .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c),
                    ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCountry = v),
                  ),
                  const SizedBox(height: 20),
                  /*────────── كلمة المرور ──────────*/
                  RoundedTextField(
                    hintText   : 'كلمة المرور',
                    obscureText: true,
                    controller : _passwordController,
                  ),
                  const SizedBox(height: 20),
                  RoundedTextField(
                    hintText   : 'تأكيد كلمة المرور',
                    obscureText: true,
                    controller : _confirmPassController,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            /*────────── زر إنشاء الحساب ──────────*/
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width : double.infinity,
                height: 50,
                child : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    foregroundColor: secondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: _signUp,
                  child: const Text('إنشاء حساب', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /*────────── ديكور موحَّد للقوائم المنسدلة ──────────*/
  InputDecoration _dropDecoration({required String label}) => InputDecoration(
    labelText : label,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    border    : OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );
}
