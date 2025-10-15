// lib/screens/my_questions_page.dart
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

import '../colors.dart';
import 'full_screen_image.dart';
import 'qa_details_page.dart';

class MyQuestionsPage extends StatefulWidget {
  const MyQuestionsPage({super.key});

  @override
  State<MyQuestionsPage> createState() => _MyQuestionsPageState();
}

class _MyQuestionsPageState extends State<MyQuestionsPage> {
  //------------------------------------------------------------
  // 1) stream مدموج لأسئلة المستخدم (مُجاب / غير مُجاب)
  //------------------------------------------------------------
  // 🔄  استبدل بما يلي
  late final Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _stream =
  (() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // أسئلتى غير المُجابة
    final unanswered = FirebaseFirestore.instance
        .collection('questions')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    // أسئلتى المُجابة
    final answered = FirebaseFirestore.instance
        .collection('questions_answers')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    // دمج + إزالة التكرار
    return Rx.combineLatest2(
      unanswered,
      answered,
          (QuerySnapshot<Map<String, dynamic>> q1,
          QuerySnapshot<Map<String, dynamic>> q2) {

        /// نستخدم Map مفاتيحها هى document-id
        /// إذا وُجدت نسختان لنفس id تبقى الأخيرة (وهى التى تحتوى answerText)
        final map = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

        for (final doc in q1.docs) {
          map[doc.id] = doc;          // نسخة بلا جواب
        }
        for (final doc in q2.docs) {
          map[doc.id] = doc;          // تُكتب فوق السابقة إن وُجدت
        }

        // حوّل القيم إلى قائمة ثم فرّغها بالأحدث
        final list = map.values.toList()
          ..sort((a, b) =>
              (b['createdAt'] as Timestamp)
                  .compareTo(a['createdAt'] as Timestamp));

        return list;
      },
    );
  })();


  //------------------------------------------------------------
  // 2) Like للسؤال/الجواب
  //------------------------------------------------------------
  Future<void> _toggleLike(String qaId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ref =
    FirebaseFirestore.instance.collection('questions_answers').doc(qaId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data     = snap.data()!;
      final likedBy  = List<String>.from(data['likedBy'] ?? []);
      final likeCnt  = data['likeCount'] ?? 0;

      tx.update(ref,
          likedBy.contains(uid)
              ? {
            'likedBy'  : FieldValue.arrayRemove([uid]),
            'likeCount': likeCnt - 1,
          }
              : {
            'likedBy'  : FieldValue.arrayUnion([uid]),
            'likeCount': likeCnt + 1,
          });
    });
  }

  //------------------------------------------------------------
  // 3) أدوات مساعدة
  //------------------------------------------------------------
  Map<String, String> _splitLines(String txt) {
    final lines = txt.split('\n');
    return {
      'title': lines.isNotEmpty ? lines.first.trim() : '',
      'body' : lines.length > 1
          ? txt.substring(txt.indexOf('\n') + 1).trim()
          : '',
    };
  }

  void _copyPost(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('تم النسخ')));
  }

  Future<ShareResult> _sharePost(String text, String imgUrl) async {
    if (imgUrl.isEmpty) return Share.share(text);
    try {
      final rsp = await http.get(Uri.parse(imgUrl));
      final dir = await getTemporaryDirectory();
      final file =
      File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(rsp.bodyBytes);
      return Share.shareXFiles([XFile(file.path)], text: text);
    } catch (_) {
      return Share.share(text);
    }
  }

  //------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('أسئلتي'),
          backgroundColor: mainColor,
          foregroundColor: secondaryColor,
        ),
        body: StreamBuilder<
            List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          stream: _stream,
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data!;
            if (docs.isEmpty) {
              return const Center(child: Text('لم تُرسل أى أسئلة بعد'));
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final doc  = docs[i];
                return _buildQACard(context, doc.id, doc.data());
              },
            );
          },
        ),
      ),
    );
  }

  //------------------------------------------------------------
  // 4) بطاقة سؤال/جواب (نفس تصميم الصفحة الرئيسية)
  //------------------------------------------------------------
  Widget _buildQACard(
      BuildContext context, String qaId, Map<String, dynamic> data) {
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
              /*──────── رأس البطاقة ────────*/
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
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500)),
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

              /*──────── نص السؤال ────────*/
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
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w500)),
                ),

              /*──────── نص الجواب ────────*/
              if (ansText.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(ansText,
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w500)),
                ),
              ],
              const SizedBox(height: 12),

              /*──────── شريط الإجراءات ────────*/
              _actionBar(
                likeCount: likeCnt,
                isLiked: isLiked,
                onLike : () => _toggleLike(qaId),
                onCopy : () => _copyPost('$qText\n\n$ansText'),
                onShare: () => _sharePost('$qText\n\n$ansText', ''),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //------------------------------------------------------------
  // 5) شريط الإجراءات الموحّد
  //------------------------------------------------------------
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
                Icon(isLiked
                    ? Icons.thumb_up_alt
                    : Icons.thumb_up_alt_outlined,
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
}
