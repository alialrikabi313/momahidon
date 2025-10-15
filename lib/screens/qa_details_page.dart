// lib/screens/qa_details_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;   // ⬅️ للنسخ
import '../colors.dart';

class QuestionAnswerDetailsPage extends StatelessWidget {
  final String               qaId;
  final Map<String, dynamic> qaData;
  const QuestionAnswerDetailsPage({
    super.key,
    required this.qaId,
    required this.qaData,
  });

  @override
  Widget build(BuildContext context) {
    final username = qaData['username']     ?? 'مستخدم مجهول';
    final age      = qaData['age']?.toString() ?? '';
    final country  = qaData['country']      ?? '';
    final qText    = qaData['questionText'] ?? '';
    final ansText  = qaData['answerText']   ?? '';

    // الدالة المساعدة لنسخ السؤال + الجواب
    void _copyBoth() {
      Clipboard.setData(ClipboardData(text: '$qText\n\n$ansText'));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ السؤال والجواب')),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: mainColor,
          title: const Text('تفاصيل السؤال'),
          actions: [
            IconButton(
              tooltip: 'نسخ السؤال والجواب',
              icon: const Icon(Icons.copy),
              onPressed: _copyBoth,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            /*──────── رأس البطاقة ────────*/
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xffeeeeee),
                  child: Icon(Icons.person, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(username,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
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
            const SizedBox(height: 24),

            /*──────── كلمة "سؤال" + نص السؤال ────────*/
            Text('سؤال',
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
            const SizedBox(height: 6),
            Text(
              qText,
              textAlign: TextAlign.justify,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.7),
            ),

            const SizedBox(height: 24),
            const Divider(thickness: 1.2),
            const SizedBox(height: 12),

            /*──────── كلمة "جواب" + نص الجواب ────────*/
            Text('جواب',
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
            const SizedBox(height: 6),
            Text(
              ansText,
              textAlign: TextAlign.justify,
              style: const TextStyle(fontSize: 16, height: 1.7),
            ),
          ],
        ),
      ),
    );
  }
}
