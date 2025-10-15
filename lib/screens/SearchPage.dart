// -----------------------------------------------------------------------------
// search_page.dart   ✨ بحث + بطاقات منشورات وأسئلة/أجوبة بنفس تنسيق الصفحة الرئيسة ✨
// -----------------------------------------------------------------------------
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../colors.dart';
import 'post_details.dart';
import 'section_page.dart';
import 'full_screen_image.dart';
import 'qa_details_page.dart';                     // ⬅️ لعرض السؤال/الجواب

/*════════════ أداة مساعدة لتقسيم السطر الأوّل ════════════*/
Map<String, String> _splitLines(String text) {
  final lines = text.split('\n');
  return {
    'title': lines.isNotEmpty ? lines.first : '',
    'body' : lines.length > 1
        ? text.substring(text.indexOf('\n') + 1).trim()
        : '',
  };
}

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String  _searchTerm = '';
  final   double _fontSize = 23;

  /*────────────────────  وظائف مساعدة  ────────────────────*/
  Future<void> _toggleLikePost(String postId, List<String> likedBy) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ref = FirebaseFirestore.instance.collection('posts').doc(postId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;
      final cnt  = data['likeCount'] ?? 0;
      tx.update(
        ref,
        likedBy.contains(uid)
            ? {
          'likedBy'  : FieldValue.arrayRemove([uid]),
          'likeCount': cnt - 1,
        }
            : {
          'likedBy'  : FieldValue.arrayUnion([uid]),
          'likeCount': cnt + 1,
        },
      );
    });
  }

  Future<void> _toggleLikeQA(String qaId, List<String> likedBy) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ref = FirebaseFirestore.instance
        .collection('questions_answers')
        .doc(qaId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;
      final cnt  = data['likeCount'] ?? 0;
      tx.update(
        ref,
        likedBy.contains(uid)
            ? {
          'likedBy'  : FieldValue.arrayRemove([uid]),
          'likeCount': cnt - 1,
        }
            : {
          'likedBy'  : FieldValue.arrayUnion([uid]),
          'likeCount': cnt + 1,
        },
      );
    });
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('تم النسخ')));
  }

  Future<ShareResult> _shareText(String text, [String imageUrl = '']) async {
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

  /*────────────────────  واجهة البحث  ────────────────────*/
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: secondaryColor.withOpacity(.1),
        body: Column(
          children: [
            /*──────── حقل البحث ────────*/
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 50, 8, 8),
              child: TextField(
                decoration: InputDecoration(
                  labelText : 'ابحث عن كلمة أو نص...',
                  prefixIcon: const Icon(Icons.search, color: mainColor),
                  border          : OutlineInputBorder(
                    borderRadius   : BorderRadius.circular(10),
                    borderSide     : const BorderSide(color: mainColor),
                  ),
                  enabledBorder    : OutlineInputBorder(
                    borderRadius   : BorderRadius.circular(10),
                    borderSide     : const BorderSide(color: mainColor),
                  ),
                  focusedBorder    : OutlineInputBorder(
                    borderRadius   : BorderRadius.circular(10),
                    borderSide     : const BorderSide(color: mainColor),
                  ),
                ),
                onChanged: (val) => setState(() => _searchTerm = val.trim().toLowerCase()),
              ),
            ),

            /*──────── النتائج ────────*/
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // نراقب posts كبوابة (حتى تتحدّث تلقائياً) ثم نجلب Q&A مرّة كل تغيير
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, postSnap) {
                  if (postSnap.hasError) {
                    return Center(child: Text('خطأ: ${postSnap.error}'));
                  }
                  if (!postSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('questions_answers')
                        .orderBy('createdAt', descending: true)
                        .get(),
                    builder: (context, qaSnap) {
                      if (!qaSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      /* دمج القائمتين ثمّ التصفية طبقاً لعبارة البحث */
                      final List<dynamic> list = [
                        ...postSnap.data!.docs,                          // DocumentSnapshot
                        ...qaSnap.data!.docs
                            .map((d) => {'id': d.id, 'data': d.data()}), // كائن مميز لـ Q&A
                      ];

                      list.sort((a, b) {
                        final Timestamp ta = a is DocumentSnapshot
                            ? a['createdAt']
                            : (a['data'] as Map)['createdAt'];
                        final Timestamp tb = b is DocumentSnapshot
                            ? b['createdAt']
                            : (b['data'] as Map)['createdAt'];
                        return tb.compareTo(ta);
                      });

                      final term = _searchTerm;
                      final results = list.where((item) {
                        if (item is DocumentSnapshot) {
                          final data = item.data() as Map<String, dynamic>;
                          final text = (data['text'] ?? '').toString().toLowerCase();
                          return text.contains(term);
                        }
                        final d  = item['data'] as Map<String, dynamic>;
                        final q  = (d['questionText'] ?? '').toString().toLowerCase();
                        final an = (d['answerText']   ?? '').toString().toLowerCase();
                        return q.contains(term) || an.contains(term);
                      }).toList();

                      if (results.isEmpty && term.isNotEmpty) {
                        return const Center(child: Text('لا توجد نتائج مطابقة.'));
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: results.length,
                        itemBuilder: (_, i) {
                          final item = results[i];

                          /*──── بطاقة منشور ────*/
                          if (item is DocumentSnapshot) {
                            final data = item.data() as Map<String, dynamic>;
                            return _postCard(item.id, data);
                          }

                          /*──── بطاقة سؤال/جواب ────*/
                          final qaData = item['data'] as Map<String, dynamic>;
                          final qaId   = item['id']   as String;
                          return _qaCard(qaId, qaData);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /*════════════ بطاقة منشور في البحث ════════════*/
  Widget _postCard(String postId, Map<String, dynamic> data) {
    final category  = data['category'] as String? ?? 'أخرى';
    final text      = data['text'] ?? '';
    final imageUrl  = data['imageUrl'] ?? '';
    final likeCount = data['likeCount'] ?? 0;
    final likedBy   = List<String>.from(data['likedBy'] ?? []);
    final uid       = FirebaseAuth.instance.currentUser?.uid;
    final isLiked   = uid != null && likedBy.contains(uid);

    final parts = _splitLines(text);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostDetailsPage(postId: postId, postData: data),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /* المحتوى */
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الفئة
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SectionPage(sectionName: category),
                        ),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: mainColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(parts['title']!,
                        style: TextStyle(
                            fontSize: _fontSize + 3,
                            fontWeight: FontWeight.w800,
                            height: 1.6)),
                    if (parts['body']!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(parts['body']!,
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.justify,
                          style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w600)),
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
                                  FullScreenImagePage(url: imageUrl),
                            ),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                            const Center(child: CircularProgressIndicator()),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.image_not_supported,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              /* شريط الإجراءات */
              _actionBar(
                likeCount: likeCount,
                isLiked  : isLiked,
                onLike   : () => _toggleLikePost(postId, likedBy),
                onCopy   : () => _copyText(text),
                onShare  : () => _shareText(text, imageUrl),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /*════════════ بطاقة سؤال/جواب في البحث ════════════*/
  Widget _qaCard(String qaId, Map<String, dynamic> data) {
    final username = data['username'] ?? 'مستخدم مجهول';
    final age      = data['age']?.toString() ?? '';
    final country  = data['country'] ?? '';
    final qText    = data['questionText'] ?? '';
    final ansText  = data['answerText'] ?? '';

    final likeCnt  = data['likeCount'] ?? 0;
    final likedBy  = List<String>.from(data['likedBy'] ?? []);
    final uid      = FirebaseAuth.instance.currentUser?.uid;
    final isLiked  = uid != null && likedBy.contains(uid);

    final parts = _splitLines(qText);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  QuestionAnswerDetailsPage(qaId: qaId, qaData: data),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /* الرأس */
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                child: Row(
                  children: [
                    const CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xffeeeeee),
                        child: Icon(Icons.person, color: Colors.grey)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(username,
                              style:
                              const TextStyle(fontWeight: FontWeight.w600)),
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
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              if (parts['body']!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(parts['body']!,
                      textAlign: TextAlign.justify,
                      style: const TextStyle(height: 1.6)),
                ),
              if (ansText.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(ansText,
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                          color: Colors.grey.shade800, height: 1.6)),
                ),
              ],
              const SizedBox(height: 12),
              /* شريط الإجراءات */
              _actionBar(
                likeCount: likeCnt,
                isLiked  : isLiked,
                onLike   : () => _toggleLikeQA(qaId, likedBy),
                onCopy   : () => _copyText('$qText\n\n$ansText'),
                onShare  : () => _shareText('$qText\n\n$ansText'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /*════════════ شريط الإجراءات الموحّد ════════════*/
  Widget _actionBar({
    required int    likeCount,
    required bool   isLiked,
    required VoidCallback onLike,
    required VoidCallback onCopy,
    required VoidCallback onShare,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onLike,
              child: Row(
                children: [
                  Icon(
                    isLiked
                        ? Icons.thumb_up_alt
                        : Icons.thumb_up_alt_outlined,
                    size: 24,
                    color: mainColor,
                  ),
                  const SizedBox(width: 6),
                  Text('$likeCount',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Spacer(),
            GestureDetector(
                onTap: onCopy,
                child: const Icon(Icons.copy,
                    size: 24, color: Colors.black54)),
            const SizedBox(width: 16),
            GestureDetector(
                onTap: onShare,
                child: const Icon(Icons.share,
                    size: 24, color: Colors.black54)),
          ],
        ),
      );
}
