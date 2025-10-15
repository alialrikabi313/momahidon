
import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage show FirebaseStorage;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../colors.dart';
import '../data/model.dart' show CategoryInfo;
import 'section_page.dart';
import 'post_details.dart';
import 'full_screen_image.dart';
import 'lesson_topics_screen.dart';
import 'qa_details_page.dart';
import 'package:rxdart/rxdart.dart';   // RxDart لدمج الـ Streams

/*────────────────────────  نموذج الدرس  ────────────────────────*/
class _LessonInfo {
final String id;
final String imagePath;
const _LessonInfo({required this.id, required this.imagePath});
}

class Home extends StatefulWidget {
const Home({Key? key}) : super(key: key);
/* ـــــــــــــــ كاش لروابط الـ banner ــــــــــــــ */

@override
State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  void _purgeImageFromCache(String url) {
    if (url.isEmpty) return;

    // 1) يمسح الملف المحفوظ في القرص (CacheManager)
    DefaultCacheManager().removeFile(url);

    // 2) يمسح النسخة الموجودة في ذاكرة تطبيق Flutter
    CachedNetworkImage.evictFromCache(url);
  }

  /// ستريم واحد مدموج بين posts و questions_answers
  late final Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _mergedStream =
  Rx.combineLatest2<
      QuerySnapshot<Map<String, dynamic>>,
      QuerySnapshot<Map<String, dynamic>>,
      List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
    FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots(),
    FirebaseFirestore.instance
        .collection('questions_answers')
        .orderBy('createdAt', descending: true)
        .snapshots(),
        (postsSnap, qaSnap) => <QueryDocumentSnapshot<Map<String, dynamic>>>[
      ...postsSnap.docs,
      ...qaSnap.docs,
    ],
  );

/*───────────────────── متحكم السلايدر ─────────────────────*/
late final PageController _bannerController;
late Timer _bannerTimer;
int _currentBanner = 0;
int _bannerCount = 0;
late SharedPreferences _prefs;
Future<void> _initPrefs() async {
_prefs = await SharedPreferences.getInstance();
}

/// ستريم واحد مدموج لكلٍ من posts و questions_answers

@override
void initState() {
super.initState();
_initPrefs();                 // <-- ①
_bannerController = PageController();
// استمع إلى كل تغيّر فى كولكشن posts
  FirebaseFirestore.instance
      .collection('posts')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .listen((snap) {
    for (final change in snap.docChanges) {
      if (change.type == DocumentChangeType.removed) {
        final String imgUrl = change.doc['imageUrl'] ?? '';
        _purgeImageFromCache(imgUrl);           // ❶ امسح صورة المنشور
        // لا يوجد SharedPreferences للمنشورات العادية
      }
    }
  });

  /*──────── مستمع حذف سؤال/جواب ────────*/
  FirebaseFirestore.instance
      .collection('questions_answers')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .listen((snap) {
    for (final change in snap.docChanges) {
      if (change.type == DocumentChangeType.removed) {
        // إذا كان لديك صور داخل الأسئلة
        final String imgUrl = change.doc['imageUrl'] ?? '';
        _purgeImageFromCache(imgUrl);
      }
    }
  });

  /*──────── مستمع حذف Banner (دروس) ────────*/
  FirebaseFirestore.instance
      .collection('lessons')
      .snapshots()
      .listen((snap) {
    for (final change in snap.docChanges) {
      if (change.type == DocumentChangeType.removed) {
        final String path = change.doc['imagePath'] ?? '';

        // 1) احذف الملف من CacheManager / CachedNetworkImage
        final String? cachedUrl = _prefs.getString('url_$path');
        if (cachedUrl != null) _purgeImageFromCache(cachedUrl);

        // 2) احذف المفتاح من SharedPreferences
        _prefs.remove('url_$path');
      }
    }
  });
// تقليب تلقائي كل 10 ثوانٍ
_bannerTimer = Timer.periodic(const Duration(seconds: 10), (_) {
if (_bannerController.hasClients && _bannerCount > 1) {
_currentBanner = (_currentBanner + 1) % _bannerCount;
_bannerController.animateToPage(
_currentBanner,
duration: const Duration(milliseconds: 500),
curve: Curves.easeInOut,
);
}
});
}
static final Map<String, String> _bannerUrlCache = {};

@override
void dispose() {
_bannerTimer.cancel();
_bannerController.dispose();
super.dispose();
}

/*════════════════════ Like (Posts) ════════════════════*/
Future<void> _toggleLike(String postId) async {
final uid = FirebaseAuth.instance.currentUser?.uid;
if (uid == null) return;
final ref = FirebaseFirestore.instance.collection('posts').doc(postId);

await FirebaseFirestore.instance.runTransaction((tx) async {
final snap = await tx.get(ref);
if (!snap.exists) return;
final data = snap.data()!;
final likedBy = List<String>.from(data['likedBy'] ?? []);
final count = data['likeCount'] ?? 0;

tx.update(
ref,
likedBy.contains(uid)
? {
'likedBy': FieldValue.arrayRemove([uid]),
'likeCount': count - 1,
}
    : {
'likedBy': FieldValue.arrayUnion([uid]),
'likeCount': count + 1,
},
);
});
}

/*════════════════════ Like (Q&A) ════════════════════*/
Future<void> _toggleLikeQA(String qaId) async {
final uid = FirebaseAuth.instance.currentUser?.uid;
if (uid == null) return;
final ref =
FirebaseFirestore.instance.collection('questions_answers').doc(qaId);

await FirebaseFirestore.instance.runTransaction((tx) async {
final snap = await tx.get(ref);
if (!snap.exists) return;
final data = snap.data()!;
final likedBy = List<String>.from(data['likedBy'] ?? []);
final count = data['likeCount'] ?? 0;

tx.update(
ref,
likedBy.contains(uid)
? {
'likedBy': FieldValue.arrayRemove([uid]),
'likeCount': count - 1,
}
    : {
'likedBy': FieldValue.arrayUnion([uid]),
'likeCount': count + 1,
},
);
});
}

/*════════════════════ أدوات مساعدة ════════════════════*/
Map<String, String> _splitLines(String txt) {
final lines = txt.split('\n');
return {
'title': lines.isNotEmpty ? lines.first.trim() : '',
'body': lines.length > 1
? txt.substring(txt.indexOf('\n') + 1).trim()
    : '',
};
}

void _copyPost(String text) {
Clipboard.setData(ClipboardData(text: text));
ScaffoldMessenger.of(context)
    .showSnackBar(const SnackBar(content: Text('تم النسخ')));
}

Future<ShareResult> _sharePost(String text, String imageUrl) async {
if (imageUrl.isEmpty) return Share.share(text);
try {
final rsp = await http.get(Uri.parse(imageUrl));
final dir = await getTemporaryDirectory();
final file =
File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
await file.writeAsBytes(rsp.bodyBytes);
return Share.shareXFiles([XFile(file.path)], text: text);
} catch (_) {
return Share.share(text);
}
}

/*──────────────────────────  الدروس  ──────────────────────────*/
Stream<List<_LessonInfo>> get _lessons async* {
yield* FirebaseFirestore.instance
    .collection('lessons')
    .orderBy('createdAt', descending: true)
    .snapshots()
    .map((qs) => qs.docs
    .map((d) => _LessonInfo(id: d.id, imagePath: d['imagePath']))
    .toList());
}

Future<String> _downloadBannerUrl(String path) async {
// ① ابحث أوّلاً فى الـ Shared-Preferences
final cachedUrl = _prefs.getString('url_$path');
if (cachedUrl != null) return cachedUrl;      // عند العمل أوفلاين

// ② لم نجده → اجلب الرابط من Firebase-Storage
final url = await firebase_storage.FirebaseStorage.instance
    .ref(path)
    .getDownloadURL();

// ③ نزّل الملف واحفظه فى Cache-Manager (ملف محلى)
await DefaultCacheManager().downloadFile(url);

// ④ احفظ الرابط فى Shared-Preferences للمرّات القادمة
await _prefs.setString('url_$path', url);

return url;
}

/*──────────────────────────  الواجهة  ──────────────────────────*/
@override
Widget build(BuildContext context) {
final sz = MediaQuery.of(context).size;

return Directionality(
textDirection: TextDirection.rtl,
child: Scaffold(
backgroundColor: const Color(0xfff7f7f9),
appBar: PreferredSize(
preferredSize: const Size.fromHeight(60),
child: AppBar(
backgroundColor: Colors.white,
elevation: 0,
automaticallyImplyLeading: false,
title: Align(
alignment: Alignment.centerRight,
child: Text(
'الممهد',
style: TextStyle(
color: mainColor,
fontSize: 33,
fontWeight: FontWeight.bold),
),
),
),
),
body: CustomScrollView(
slivers: [
/*──────── سلايدر الدروس ────────*/
SliverToBoxAdapter(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
SizedBox(
height: sz.height * .30,
child: StreamBuilder<List<_LessonInfo>>(
stream: _lessons,
builder: (_, snap) {
if (!snap.hasData) {
return const Center(
child: CircularProgressIndicator());
}
final lessons = snap.data!;
_bannerCount = lessons.length;

return PageView.builder(
controller: _bannerController,
itemCount: lessons.length,
onPageChanged: (i) =>
setState(() => _currentBanner = i),
itemBuilder: (_, i) {
final info = lessons[i];
return FutureBuilder<String>(
future: _downloadBannerUrl(info.imagePath),
builder: (_, imgSnap) {
if (!imgSnap.hasData) {
return const Center(
child: CircularProgressIndicator());
}
return Material(
color: Colors.transparent,
child: InkWell(
onTap: () => Navigator.push(
context,
MaterialPageRoute(
builder: (_) => LessonTopicsScreen(
lessonId: info.id)),
),
child: CachedNetworkImage(
imageUrl: imgSnap.data!,
cacheKey: info.imagePath,          // ← السطر المهم

fit: BoxFit.cover,
placeholder: (_, __) =>
const Center(child: CircularProgressIndicator()),
errorWidget: (_, __, ___) => const Icon(
Icons.image_not_supported),
),
),
);
},
);
},
);
},
),
),
const SizedBox(height: 10),
SmoothPageIndicator(
controller: _bannerController,
count: _bannerCount,
effect: const ExpandingDotsEffect(
dotHeight: 10,
dotWidth: 10,
activeDotColor: mainColor,
dotColor: Colors.grey),
),
],
),
),

/*──────── تصنيفات (الشريط الأفقي) ────────*/
SliverToBoxAdapter(
child: SizedBox(
height: 150,
child: ListView.separated(
padding:
const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
scrollDirection: Axis.horizontal,
separatorBuilder: (_, __) => const SizedBox(width: 14),
itemCount: _categories.length,
itemBuilder: (_, i) {
final cat = _categories[i];
final thumb = _catThumbs[i];
final w = MediaQuery.of(context).size.width * .28;
return GestureDetector(
onTap: () => Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
SectionPage(sectionName: cat.fsName)),
),
child: Column(
children: [
ClipRRect(
borderRadius: BorderRadius.circular(5),
child: Image.asset(
thumb,
width: w,
height: 110,
fit: BoxFit.cover,
),
),
const SizedBox(height: 6),
],
),
);
},
),
),
),

/*──────── الـ Feed الموحّد (Posts + Q&A) ────────*/
/*──────── الـ Feed الموحَّد (Posts + Q&A) ────────*/
  StreamBuilder<
      List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
    stream: _mergedStream,
    builder: (_, snap) {
      if (!snap.hasData) {
        return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final feed = snap.data!;

      // فرز نزولي حسب createdAt
      feed.sort((a, b) =>
          (b['createdAt'] as Timestamp)
              .compareTo(a['createdAt'] as Timestamp));

      return SliverList.builder(
        itemCount: feed.length,
        itemBuilder: (_, i) {
          final doc = feed[i];

          // إذا أتى من كولكشن posts
          if (doc.reference.parent.id == 'posts') {
            return _buildPostCard(context, doc.id, doc.data());
          }

          // وإلا فهو من questions_answers
          return _buildQACard(context, doc.id, doc.data());
        },
      );
    },
  ),
],
),
),
);
}

/*════════════ بطاقة منشور عادي ════════════*/
Widget _buildPostCard(
BuildContext context, String postId, Map<String, dynamic> data) {
final category = data['category'] ?? 'أخرى';
final text = data['text'] ?? '';
final imageUrl = data['imageUrl'] ?? '';

final likeCount = data['likeCount'] ?? 0;
final likedBy = List<String>.from(data['likedBy'] ?? []);
final uid = FirebaseAuth.instance.currentUser?.uid;
final isLiked = uid != null && likedBy.contains(uid);

final lines = text.split('\n');
final firstLine = lines.isNotEmpty ? lines.first : '';
final rest =
lines.length > 1 ? text.substring(text.indexOf('\n') + 1).trim() : '';

return Padding(
padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
child: Material(
elevation: 3,
borderRadius: BorderRadius.circular(12),
color: Colors.white,
child: InkWell(
borderRadius: BorderRadius.circular(12),
onTap: () => Navigator.push(
context,
MaterialPageRoute(
builder: (_) => PostDetailsPage(postId: postId, postData: data)),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Padding(
padding: const EdgeInsets.all(14),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
GestureDetector(
onTap: () => Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
SectionPage(sectionName: category)),
),
child: Text(category,
style: TextStyle(
fontSize: 18,
color: mainColor,
fontWeight: FontWeight.w700)),
),
const SizedBox(height: 6),
Text(firstLine,
style: const TextStyle(
fontSize: 23,
fontWeight: FontWeight.w700,
height: 1.6)),
if (rest.isNotEmpty) ...[
const SizedBox(height: 2),
Text(rest,
maxLines: 6,
overflow: TextOverflow.ellipsis,
textAlign: TextAlign.justify,
style: const TextStyle( fontSize: 20, fontWeight:FontWeight.w500 )),
],
if (imageUrl.isNotEmpty) ...[
const SizedBox(height: 8),
ClipRRect(
borderRadius: BorderRadius.circular(10),
child: GestureDetector(
onTap: () => Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
FullScreenImagePage(url: imageUrl)),
),
child: CachedNetworkImage(
imageUrl: imageUrl,
width: double.infinity,
height: 200,
fit: BoxFit.cover,
placeholder: (_, __) => const Center(
child: CircularProgressIndicator()),
errorWidget: (_, __, ___) => const Icon(
Icons.image_not_supported,
size: 40,
color: Colors.grey),
),
),
),
],
],
),
),
_actionBar(
likeCount: likeCount,
isLiked: isLiked,
onLike: () => _toggleLike(postId),
onCopy: () => _copyPost(text),
onShare: () => _sharePost(text, imageUrl),
),
],
),
),
),
);
}

/*════════════ بطاقة سؤال/جواب ════════════*/
Widget _buildQACard(
BuildContext context, String qaId, Map<String, dynamic> data) {
final username = data['username'] ?? 'مستخدم مجهول';
final age = data['age']?.toString() ?? '';
final country = data['country'] ?? '';
final qText = data['questionText'] ?? '';
final ansText = data['answerText'] ?? '';

final likeCnt = data['likeCount'] ?? 0;
final likedBy = List<String>.from(data['likedBy'] ?? []);
final uid = FirebaseAuth.instance.currentUser?.uid;
final isLiked = uid != null && likedBy.contains(uid);

final parts = _splitLines(qText);

return Padding(
padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
child: Material(
elevation: 3,
borderRadius: BorderRadius.circular(12),
color: Colors.white,
child: InkWell(
borderRadius: BorderRadius.circular(12),
onTap: () => Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
QuestionAnswerDetailsPage(qaId: qaId, qaData: data)),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
/* رأس البطاقة */
Padding(
padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
child: Row(
children: [
const CircleAvatar(
radius: 20,
backgroundColor: Color(0xffeeeeee),
child: Icon(Icons.person, color: Colors.grey),
),
const SizedBox(width: 10),
Expanded(
child: Wrap(
spacing: 6,
crossAxisAlignment: WrapCrossAlignment.center,
children: [
Text(username,
style:
const TextStyle(fontWeight: FontWeight.w500)),
if (age.isNotEmpty)
Text('·  $age سنة',
style: const TextStyle(color: Colors.grey)),
if (country.isNotEmpty)
Text('·  $country',
style: const TextStyle(color: Colors.grey)),
],
),
),
],
),
),
/* السؤال */
Padding(
padding: const EdgeInsets.symmetric(horizontal: 14),
child: Text(parts['title']!,
style: const TextStyle(
fontSize: 23, fontWeight: FontWeight.w700)),
),
const SizedBox(height: 6),
if (parts['body']!.isNotEmpty)
Padding(
padding: const EdgeInsets.symmetric(horizontal: 14),
child: Text(parts['body']!,
textAlign: TextAlign.justify,
style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
),
if (ansText.trim().isNotEmpty) ...[
const SizedBox(height: 12),
Padding(
padding: const EdgeInsets.symmetric(horizontal: 14),
child: Text(ansText,
textAlign: TextAlign.justify,
style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),

),
),
],
const SizedBox(height: 12),
_actionBar(
likeCount: likeCnt,
isLiked: isLiked,
onLike: () => _toggleLikeQA(qaId),
onCopy: () => _copyPost('$qText\n\n$ansText'),
onShare: () => _sharePost('$qText\n\n$ansText', ''),
),
],
),
),
),
);
}

/*════════════ شريط الإجراءات الموحد ════════════*/
Widget _actionBar({
required int likeCount,
required bool isLiked,
required VoidCallback onLike,
required VoidCallback onCopy,
required VoidCallback onShare,
}) {
return Container(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
decoration: BoxDecoration(
border: Border(top: BorderSide(color: Colors.grey.shade300))),
child: Row(
children: [
GestureDetector(
onTap: onLike,
child: Row(
children: [
Icon(isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
size: 24, color: mainColor),
const SizedBox(width: 6),
Text('$likeCount',
style: const TextStyle(
fontSize: 15, fontWeight: FontWeight.w500)),
],
),
),
const Spacer(),
GestureDetector(
onTap: onCopy,
child:
const Icon(Icons.copy, size: 24, color: Colors.black54)),
const SizedBox(width: 16),
GestureDetector(
onTap: onShare,
child:
const Icon(Icons.share, size: 24, color: Colors.black54)),
],
),
);
}
/*────────────────────────  البيانات الثابتة  ────────────────────────*/
final List<CategoryInfo> _categories = const [
CategoryInfo('الفقهية', 'الفقهية', 'assets/cat_fqh.png', Color(0xff4361ee)),
CategoryInfo('العقائدية', 'العقائدية', 'assets/cat_aq.png', Color(0xff4895ef)),
CategoryInfo('المهدوية', 'مهدوية', 'assets/cat_mah.png', Color(0xff4cc9f0)),
CategoryInfo('الحسينية', 'حسينية', 'assets/cat_hus.png', Color(0xfff72585)),
CategoryInfo('السيرة', 'سيرة', 'assets/cat_seera.png', Color(0xffb5179e)),
CategoryInfo('أخرى', 'أخرى', 'assets/cat_other.png', Color(0xff7209b7)),
];

final List<String> _catThumbs = const [
'assets/fiqah.png',
'assets/aqaed.png',
'assets/mahdawia.png',
'assets/hussin.png',
'assets/sira.png',
'assets/other.png',
];
}


