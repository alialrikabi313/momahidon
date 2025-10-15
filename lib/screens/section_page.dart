import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../colors.dart';
import 'full_screen_image.dart';
import 'post_details.dart';

class SectionPage extends StatelessWidget {
  final String sectionName;
  const SectionPage({super.key, required this.sectionName});

  // ─────────────── مرادفات الأقسام (حرّر حسب حاجتك) ───────────────
  static const Map<String, List<String>> aliases = {
    'فقهية': ['فقه', 'الفقه', 'فقهية'],
    'عقائدية': ['عقائد', 'العقائد', 'عقائدية'],
    'مهدوية': ['المهدوية', 'مهدوية'],
    'حسينية': ['الحسينية', 'حسينية'],
    'سيرة': ['السيرة', 'سيرة'],
    'أخرى': ['أخرى'],
  };

  bool _matchCategory(String fromDb) {
    final norm = fromDb.trim();
    final list = aliases[sectionName] ?? [sectionName];
    return list.contains(norm);
  }

  // ─────────────── أزرار التفاعل (نفس Home) ───────────────
  Future<void> _copyPost(BuildContext ctx, String text) async {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(ctx)
        .showSnackBar(const SnackBar(content: Text('تم النسخ')));
  }

  Future<ShareResult> _sharePost(String text, String imageUrl) async {
    if (imageUrl.isEmpty) return Share.share(text);

    try {
      final rsp = await http.get(Uri.parse(imageUrl));
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(rsp.bodyBytes);
      return Share.shareXFiles([XFile(file.path)], text: text);
    } catch (_) {
      return Share.share(text);
    }
  }

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
            'likeCount': count - 1
          }
              : {
            'likedBy': FieldValue.arrayUnion([uid]),
            'likeCount': count + 1
          });
    });
  }

  // ─────────────────────────── واجهة الصفحة ───────────────────────────
  @override
  Widget build(BuildContext context) {
    final postsStream =
    FirebaseFirestore.instance.collection('posts').snapshots();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(sectionName, style: TextStyle(color: Colors.white),), backgroundColor: mainColor),
        body: StreamBuilder<QuerySnapshot>(
          stream: postsStream,
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data!.docs
                .where((d) =>
                _matchCategory((d['category'] ?? '').toString()))
                .toList()
              ..sort((a, b) => (b['createdAt'] as Timestamp)
                  .compareTo(a['createdAt'] as Timestamp));

            if (docs.isEmpty) {
              return const Center(child: Text('لا توجد منشورات بعد'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: docs.length,
              itemBuilder: (ctx, i) {
                final d = docs[i];
                final data = d.data() as Map<String, dynamic>;

                final text = data['text'] ?? '';
                final imageUrl = data['imageUrl'] ?? '';
                final likeCount = data['likeCount'] ?? 0;
                final likedBy = List<String>.from(data['likedBy'] ?? []);
                final uid = FirebaseAuth.instance.currentUser?.uid;
                final isLiked = uid != null && likedBy.contains(uid);

                return Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                              PostDetailsPage(postId: d.id, postData: data),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ـــــــــــ محتوى المنشور ـــــــــــ
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(text,
                                    maxLines: 6,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.justify,
                                    style: const TextStyle(
                                        fontSize: 15, height: 1.6)),
                                if (imageUrl.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                FullScreenImagePage(
                                                    url: imageUrl)),
                                      ),
                                      child: Image.network(imageUrl,
                                          width: double.infinity,
                                          height: 200,
                                          fit: BoxFit.cover),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // ـــــــــــ شريط التفاعل ـــــــــــ
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                                border: Border(
                                    top: BorderSide(
                                        color: Colors.grey.shade300))),
                            child: Row(
                              children: [
                                // like
                                GestureDetector(
                                  onTap: () => _toggleLike(d.id),
                                  child: Row(
                                    children: [
                                      Icon(
                                          isLiked
                                              ? Icons.thumb_up_alt
                                              : Icons.thumb_up_alt_outlined,
                                          size: 24,
                                          color: mainColor),
                                      const SizedBox(width: 6),
                                      Text('$likeCount',
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                // copy
                                GestureDetector(
                                  onTap: () => _copyPost(ctx, text),
                                  child: const Icon(Icons.copy,
                                      size: 24, color: Colors.black54),
                                ),
                                const SizedBox(width: 16),
                                // share
                                GestureDetector(
                                  onTap: () => _sharePost(text, imageUrl),
                                  child: const Icon(Icons.share,
                                      size: 24, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
