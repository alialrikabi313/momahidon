// -----------------------------------------------------------------------------
// topic_content_screen.dart  (إضافة السابق/التالي)
// -----------------------------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class TopicContentScreen extends StatefulWidget {
  final List<Map<String, String>> topics; // جميع مواضيع الدرس
  final int initialIndex;                 // فهرس الموضوع الحالي
  final String heroTagPrefix;

  const TopicContentScreen({
    super.key,
    required this.topics,
    required this.initialIndex,
    required this.heroTagPrefix,
  });

  @override
  State<TopicContentScreen> createState() => _TopicContentScreenState();
}

class _TopicContentScreenState extends State<TopicContentScreen> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }

  void _goToNext() {
    if (currentIndex < widget.topics.length - 1) {
      setState(() => currentIndex++);
    }
  }

  void _goToPrevious() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currentTopic = widget.topics[currentIndex];
    final title   = currentTopic['title']!;
    final content = currentTopic['content']!;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => Share.share('$title\n\n$content'),
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xfff2f5f9), Color(0xffe3e7ec)],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 120, 16, 24),
                  child: Hero(
                    tag: '${widget.heroTagPrefix}$currentIndex',
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          content,
                          style: GoogleFonts.cairo(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff333333),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // أزرار السابق / التالي
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: currentIndex > 0 ? _goToPrevious : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,   // نشط
                          disabledBackgroundColor: Colors.grey, // معطَّل
                          foregroundColor: Colors.white,  // لون الأيقونة والنص
                        ),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('السابق', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: currentIndex < widget.topics.length - 1 ? _goToNext : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,   // نشط
                          disabledBackgroundColor: Colors.grey, // معطَّل
                          foregroundColor: Colors.white,  // لون الأيقونة والنص
                        ),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('التالي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
