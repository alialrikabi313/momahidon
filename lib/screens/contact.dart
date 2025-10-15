// lib/screens/account_settings_page.dart
// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:momahidon/screens/login_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../colors.dart';
import 'my_questions_page.dart';

/// ---------------------------------------------------------------------------
/// صفحة إعدادات الحساب + كل الصفحات الفرعية المرتبطة بها
/// جميع الألوان موحَّدة عبر المتغيّرين:
///   • mainColor      -> اللون البنفسجي الأساسي
///   • secondaryColor -> الأبيض
/// ---------------------------------------------------------------------------

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({Key? key}) : super(key: key);

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  bool _isLoggingOut = false;

  /*──────────────────── عنصر موحَّد لبناء بنود القائمة ────────────────────*/
  Widget buildSettingsItem({
    required IconData     icon,
    required String       title,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: mainColor.withOpacity(.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: mainColor),
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          trailing: Icon(Icons.arrow_forward_ios,
              size: 18, color: mainColor.withOpacity(.7)),
          onTap: onTap,
        ),
        if (!isLast)
          Divider(height: 1, color: secondaryColor.withOpacity(.3)),
      ],
    );
  }

  /*──────────────────── جلب بيانات المستخدم من Firestore ──────────────────*/
  Future<Map<String, dynamic>> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return doc.data() ?? {};
  }

  /*──────────────────────────── تسجيل الخروج ─────────────────────────────*/
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: secondaryColor,
          title  : Text('تأكيد الخروج', style: TextStyle(color: mainColor)),
          content: Text('هل أنت متأكد أنك تريد تسجيل الخروج؟',
              style: TextStyle(color: mainColor)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('إلغاء', style: TextStyle(color: mainColor)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('خروج', style: TextStyle(color: mainColor)),
            ),
          ],
        ),
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoggingOut = true);

    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
    );
  }

  /*────────────────────────── هيكل الصفحة الرئيسة ─────────────────────────*/
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserData(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError || snap.data == null || snap.data!.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title      : const Text('إعدادات الحساب', style: TextStyle(color: Colors.white),),
              automaticallyImplyLeading: false,
              centerTitle: true,
              backgroundColor: mainColor,
            ),
            body: Center(
              child: Text('تعذّر جلب بيانات المستخدم.',
                  style: TextStyle(color: mainColor)),
            ),
          );
        }

        final data  = snap.data!;
        final name  = data['username'] ?? 'اسم المستخدم';
        final email = data['email']    ?? 'user@email.com';

        return Scaffold(
          appBar: AppBar(
            backgroundColor: mainColor,
            centerTitle: true,
            elevation  : 0,
            title: const Text(
              'إعدادات الحساب',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
            ),
            automaticallyImplyLeading: false,

          ),
          body: Column(
            children: [
              _buildHeader(name, email),
              if (_isLoggingOut) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 20),
                  children: [
                    buildSettingsItem(
                      icon : Icons.question_answer,
                      title: 'أرسل سؤالك',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AskQuestionPage()),
                      ),
                    ),
                    buildSettingsItem(
                      icon : Icons.question_answer,
                      title: 'أسئلتي',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyQuestionsPage()),
                      ),
                    ),
                    buildSettingsItem(
                      icon : Icons.person,
                      title: 'المعلومات الشخصية',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PersonalInfoPage()),
                      ),
                    ),
                    buildSettingsItem(
                      icon : Icons.help_outline,
                      title: 'حول التطبيق',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => HelpPage()),
                      ),
                    ),
                    buildSettingsItem(
                      icon : Icons.person_add_alt_1,
                      title: 'دعوة صديق',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => InviteFriendPage()),
                      ),
                    ),
                    buildSettingsItem(
                      icon   : Icons.exit_to_app,
                      title  : 'تسجيل الخروج',
                      isLast : true,
                      onTap  : _logout,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /*──────────────────────────── رأس الصفحة ───────────────────────────────*/
  Widget _buildHeader(String userName, String userEmail) => Container(
    height: 140,
    width : double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [mainColor, secondaryColor],
        begin : Alignment.topCenter,
        end   : Alignment.bottomCenter,
      ),
      borderRadius: BorderRadius.only(
        bottomLeft : Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(userName,
            style: TextStyle(
                color: secondaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(userEmail,
            style: TextStyle(
                color: secondaryColor.withOpacity(.7), fontSize: 14)),
      ],
    ),
  );
}

/*============================================================================*/
/*                         الصفحات الفرعية                                     */
/*============================================================================*/

/*──────────────────── صفحة المعلومات الشخصية ──────────────────────────────*/
// ---------------------------------------------------------------------------



// ---------------------------------------------------------------------------
// lib/screens/personal_info_page.dart   (بدون firstName / lastName)
// ---------------------------------------------------------------------------

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({Key? key}) : super(key: key);

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  //-----------------------------------------------------------------------//
  // 📝  Controllers & state
  //-----------------------------------------------------------------------//
  final _usernameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();

  String? _country;
  int?    _age;
  String? _gender;
  bool    _loading = true;

  final List<String> _countries = [
    'العراق','إيران','السعودية','الإمارات','أفغانستان','ألبانيا','أذربيجان',
    'الأردن','الجزائر','البحرين','البوسنة والهرسك','بنغلاديش','بروناي',
    'باكستان','تشاد','تركيا','تركمانستان','تونس','جزر القمر','جيبوتي',
    'سيراليون','الصومال','غامبيا','غينيا','غينيا بيساو','فلسطين','قطر',
    'قرغيزستان','كازاخستان','كوسوفو','الكويت','لبنان','ليبيا','مالي',
    'المغرب','المالديف','موريتانيا','ماليزيا','مصر','نيجيريا','النيجر',
    'أوزبكستان','إندونيسيا','اليمن','السنغال','سوريا','طاجيكستان','عمان',
    'السودان','أمريكا','بريطانيا','فرنسا','ألمانيا','بلد آخر',
  ];
  final List<int>    _ages    = [for (var i = 10; i <= 80; i++) i];
  final List<String> _genders = ['ذكر', 'أنثى'];

  //-----------------------------------------------------------------------//
  // 🔄  Fetch user data
  //-----------------------------------------------------------------------//
  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (snap.exists) {
      final d = snap.data()!;
      _usernameCtrl.text = d['username'] ?? '';
      _emailCtrl.text    = d['email']    ?? '';
      _country           = d['country'];
      _age               = d['age']    is int ? d['age'] as int : null;
      _gender            = d['gender'];
    }
    setState(() => _loading = false);
  }

  //-----------------------------------------------------------------------//
  // 💾  Save updates
  //-----------------------------------------------------------------------//
  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'username' : _usernameCtrl.text.trim(),
      'email'    : _emailCtrl.text.trim(),
      'country'  : _country,
      'age'      : _age,
      'gender'   : _gender,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('تم التحديث بنجاح'), backgroundColor: mainColor),
    );
    Navigator.pop(context);
  }

  //-----------------------------------------------------------------------//
  // 🖼️  UI
  //-----------------------------------------------------------------------//
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المعلومات الشخصية', style: TextStyle(color: Colors.white)),
        backgroundColor: mainColor,
        centerTitle: true,
        automaticallyImplyLeading: false,

      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField(_usernameCtrl, 'اسم المستخدم', Icons.person),
            const SizedBox(height: 12),
            _buildTextField(_emailCtrl, 'البريد الإلكتروني', Icons.email,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),

            _buildDropdown<String>(Icons.public, 'البلد', _country, _countries,
                    (v) => setState(() => _country = v)),
            const SizedBox(height: 12),

            _buildDropdown<int>(Icons.cake, 'العمر', _age, _ages,
                    (v) => setState(() => _age = v)),
            const SizedBox(height: 12),

            _buildDropdown<String>(Icons.wc, 'الجنس', _gender, _genders,
                    (v) => setState(() => _gender = v)),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('حفظ التعديلات'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  foregroundColor: secondaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //-----------------------------------------------------------------------//
  // 🔧  Widgets helpers
  //-----------------------------------------------------------------------//
  Widget _buildTextField(TextEditingController c, String label, IconData ic,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: c,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(ic, color: mainColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDropdown<T>(
      IconData icon,
      String hint,
      T? value,
      List<T> items,
      ValueChanged<T?> onChanged,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mainColor.withOpacity(.4)),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: const InputDecoration(border: InputBorder.none),
        icon: Icon(Icons.arrow_drop_down, color: mainColor),
        hint: Text(hint),
        items: items
            .map((e) =>
            DropdownMenuItem<T>(value: e, child: Text(e.toString())))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}



/*──────────────────────────── صفحة المساعدة ───────────────────────────────*/
class HelpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: mainColor,
          centerTitle: true,
          title: const Text('حول التطبيق', style: TextStyle(color: Colors.white)),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مرحباً بك في تطبيق الممهد!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: mainColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'تطبيق الممهد هو منصّة معرفية عقائدية، تهدف إلى إيصال المحتوى الديني الموثوق بأسلوب عصري وواجهة استخدام سهلة، مع دمج التفاعل والتشويق في عرض المعارف الإسلامية.',
                style: TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 12),
              Text(
                '🔹 أقسام المحتوى:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: mainColor),
              ),
              const SizedBox(height: 6),
              Text(
                '• القسم المهدوي: يركّز على تعميق الفهم الواعي لقضية الإمام المهدي (عجّل الله فرجه).\n'
                    '• القسم الحسيني: يعرض الدروس والقيم المستخلصة من ثورة الإمام الحسين (عليه السلام).\n'
                    '• القسم العقائدي: يشرح مفاهيم العقيدة الإسلامية وفق منهج أهل البيت.\n'
                    '• القسم الفقهي: يُعنى ببيان الأحكام الشرعية والفتاوى.\n'
                    '• قسم السيرة: يتناول سِيَر المعصومين (عليهم السلام) وأدوارهم التربوية.',
                style: TextStyle(fontSize: 15.5, color: Colors.black87),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 12),
              Text(
                '🔹 الأسئلة والأجوبة:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: mainColor),
              ),
              const SizedBox(height: 6),
              Text(
                'يمكنك إرسال أسئلتك في جميع الأقسام، وسيتم الرد عليها من قبل نخبة من أساتذة الحوزة العلمية، لضمان دقة الجواب وارتباطه بالمصادر المعتمدة.',
                style: TextStyle(fontSize: 15.5, color: Colors.black87),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 12),
              Text(
                '🔹 المسابقات والجوائز:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: mainColor),
              ),
              const SizedBox(height: 6),
              Text(
                'يقدّم التطبيق مسابقات دورية تفاعلية في مواضيع متنوعة، ويتم عرض قوائم المتصدرين بناءً على الدرجات التي يجمعونها. تُمنح جوائز قيّمة للفائزين الأوائل في كل دورة.',
                style: TextStyle(fontSize: 15.5, color: Colors.black87),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 12),
              Text(
                '🔹 من نحن:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: mainColor),
              ),
              const SizedBox(height: 6),
              Text(
                'تطبيق الممهد من برمجة قسم البرمجيات في مؤسسة ممهدون الثقافية العقائدية، وهي مؤسسة تُعنى بنشر الوعي الديني والعقائدي والمهدوي بأساليب حديثة وتواصل فعّال مع المجتمع.',
                style: TextStyle(fontSize: 15.5, color: Colors.black87),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*────────────────────────── صفحة دعوة صديق ───────────────────────────────*/
class InviteFriendPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainColor,
        centerTitle: true,
        title: const Text('دعوة صديق', style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add_alt_1, size: 80, color: mainColor),
              const SizedBox(height: 20),
              Text('شارك التطبيق مع أصدقائك!',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: mainColor)),
              const SizedBox(height: 10),
              Text(
                'يمكنك إرسال رابط التطبيق لأصدقائك عبر شبكات التواصل الاجتماعي',
                textAlign: TextAlign.center,
                style: TextStyle(color: mainColor),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.alialrikabi313.momahid313';
                  Share.share('حمّل التطبيق الآن من هذا الرابط:\n$playStoreUrl');
                },
                icon : const Icon(Icons.share),
                label: const Text('مشاركة الآن'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  foregroundColor: secondaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*────────────────────────── صفحة إرسال سؤال ─────────────────────────────*/


class AskQuestionPage extends StatefulWidget {
  const AskQuestionPage({Key? key}) : super(key: key);

  @override
  State<AskQuestionPage> createState() => _AskQuestionPageState();
}

class _AskQuestionPageState extends State<AskQuestionPage> {
  final _controller = TextEditingController();
  bool  _sending    = false;

  /// تجميع كل بيانات المستخدم (مع استثناء الـ email)
  Future<Map<String, dynamic>> _getUserInfoSansEmail() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!snap.exists) return {};
    final data = Map<String, dynamic>.from(snap.data()!);
    data.remove('email');                       // 🡸 حذف البريد
    return data;
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);

    // جلب بيانات المستخدم (بدون البريد)
    final userInfo = await _getUserInfoSansEmail();
    // ضمان وجود اسم مستخدم افتراضي
    userInfo['username'] ??= 'مستخدم مجهول';

    // إنشاء الوثيقة في مجموعة questions
    await FirebaseFirestore.instance.collection('questions').add({
      'questionText': text,
      'createdAt'   : FieldValue.serverTimestamp(),
      'uid'         : FirebaseAuth.instance.currentUser!.uid,
      ...userInfo,                               // دمج جميع البيانات هنا
    });

    if (!mounted) return;
    setState(() => _sending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إرسال سؤالك بنجاح', style: TextStyle(color: secondaryColor)),
        backgroundColor: mainColor,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: mainColor,
          centerTitle: true,
          title: const Text('أرسل سؤالك', style: TextStyle(color: Colors.white)),
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'اكتب سؤالك هنا...',
                  border  : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : _send,
                  icon : _sending
                      ? const SizedBox(
                      width : 18,
                      height: 18,
                      child : CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: const Text('إرسال'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    foregroundColor: secondaryColor,
                    padding        : const EdgeInsets.symmetric(vertical: 14),
                    shape          : RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

