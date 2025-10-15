
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import 'topic_content_screen.dart';

class LessonTopicsScreen extends StatelessWidget {
  final String lessonId;
  const LessonTopicsScreen({super.key, required this.lessonId});

  /// جلب بيانات الدرس (نحتاج العنوان فقط الآن)
  Future<Map<String, dynamic>?> _fetchLessonInfo() async {
    final doc = await FirebaseFirestore.instance
        .collection('lessons')
        .doc(lessonId)
        .get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: FutureBuilder<Map<String, dynamic>?>( // عنوان الدرس
        future: _fetchLessonInfo(),
        builder: (_, lessonSnap) {
          if (lessonSnap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (!lessonSnap.hasData || lessonSnap.data == null) {
            return const Scaffold(
              body: Center(child: Text('تعذّر جلب بيانات الدرس')),
            );
          }

          final lessonTitle = lessonSnap.data!['title'] as String? ?? 'عنوان غير متوفر';

          // رف فرعي: topics داخل الدرس
          final topicsRef = FirebaseFirestore.instance
              .collection('lessons')
              .doc(lessonId)
              .collection('topics')
              .orderBy('createdAt');

          return Scaffold(
            appBar: AppBar(
              title: Text(
                lessonTitle,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              backgroundColor: colors.primary,
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: topicsRef.snapshots(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد عناوين بعد',
                      style: GoogleFonts.cairo(fontSize: 18, color: colors.primary),
                    ),
                  );
                }

                // تحويل المستندات إلى List<Map<String, String>> لاستخدامها لاحقًا
                final topicsList = docs
                    .map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return {
                    'title': data['title']   as String? ?? '',
                    'content': data['content'] as String? ?? '',
                  };
                })
                    .toList();

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  itemCount: topicsList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final title = topicsList[i]['title']!;
                    return Hero(
                      tag: 'topic_$i',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) => TopicContentScreen(
                                  topics: topicsList,
                                  initialIndex: i,
                                  heroTagPrefix: 'topic_',
                                ),
                                transitionsBuilder: (_, anim, __, child) =>
                                    FadeTransition(opacity: anim, child: child),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [colors.primary, colors.secondary],
                                    ),
                                  ),
                                  child: const Icon(Icons.menu_book_rounded, color: Colors.white),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.cairo(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xff333333),
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    size: 18, color: Color(0xff999999)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
