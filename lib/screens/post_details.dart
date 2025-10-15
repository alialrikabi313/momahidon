// -----------------------------------------------------------------------------
// post_details_page.dart   🌟  واجهة تفصيل المنشور (بتنسيق أجمل + نسخ المحتوى)
// -----------------------------------------------------------------------------
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import '../colors.dart';
import 'full_screen_image.dart';
import 'section_page.dart';

class PostDetailsPage extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const PostDetailsPage({
    super.key,
    required this.postId,
    required this.postData,
  });

  void _copyPost(BuildContext ctx, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(content: Text('تم نسخ النص إلى الحافظة')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String category = postData['category'] as String? ?? 'أخرى';
    final String fullText = (postData['text'] ?? '').toString().trim();
    final String imageUrl = postData['imageUrl'] ?? '';

    // السطر الأول بخطّ أكبر
    final lines = fullText.split('\n');
    final firstLine = lines.isNotEmpty ? lines.first : '';
    final restText  = lines.length > 1
        ? fullText.substring(fullText.indexOf('\n') + 1).trim()
        : '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المنشور', style: TextStyle(color: Colors.white),),
          actions: [
            IconButton(
              tooltip: 'نسخ المنشور',
              icon: const Icon(Icons.copy),
              onPressed: () => _copyPost(context, fullText),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الفئة كـ Chip أنيق
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SectionPage(sectionName: category),
                  ),
                ),
                child: Chip(
                  backgroundColor: mainColor.withOpacity(.15),
                  label: Text(
                    category,
                    style: const TextStyle(
                      color: mainColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 8,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // السطر الأول
              Text(
                firstLine,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.8,
                ),
                textAlign: TextAlign.justify,
              ),
              if (restText.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  restText,
                  style: const TextStyle(fontSize: 17, height: 1.8),
                  textAlign: TextAlign.justify,
                ),
              ],

              // الصورة (إن وُجدت)
              if (imageUrl.isNotEmpty) ...[
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImagePage(url: imageUrl),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const SizedBox(
                        height: 250,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.image_not_supported,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),
              const Text(
                'منشورات مشابهة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),

              // منشورات مقترحة بنفس الفئة
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .where('category', isEqualTo: category)
                    .limit(6)
                    .snapshots(),
                builder: (_, snap) {
                  if (snap.hasError) {
                    return const Center(
                      child: Icon(Icons.wifi_off, size: 40, color: Colors.grey),
                    );
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs =
                  snap.data!.docs.where((d) => d.id != postId).toList();
                  if (docs.isEmpty) return const SizedBox();

                  return Column(
                    children: docs.map((d) {
                      final dt = d.data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 2,
                        child: ListTile(
                          title: Text(
                            dt['text'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PostDetailsPage(postId: d.id, postData: dt),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
