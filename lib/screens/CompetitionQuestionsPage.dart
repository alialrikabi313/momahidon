// ignore_for_file: depend_on_referenced_packages
// lib/screens/CompetitionQuestionsPage.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:momahidon/data/Dummy%20Data.dart';
import '../colors.dart';

class CompetitionQuestionsPage extends StatefulWidget {
  final String      competitionId;      // ⭐️
  final Competition competition;
  final int         pointsPerQuestion;

  const CompetitionQuestionsPage({
    Key? key,
    required this.competitionId,
    required this.competition,
    required this.pointsPerQuestion,
  }) : super(key: key);

  @override
  State<CompetitionQuestionsPage> createState() =>
      _CompetitionQuestionsPageState();
}

class _CompetitionQuestionsPageState extends State<CompetitionQuestionsPage> {
  int  _current = 0, _selectedIdx = -1;
  bool _answered = false;

  static const _questionSeconds = 30;
  late int _secondsLeft;
  Timer?  _timer;

  int _earnedInComp = 0;

  Question get _q       => widget.competition.questions[_current];
  int      get _totalQs => widget.competition.questions.length;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  //————————————————— المؤقّت
  void _resetTimer() {
    _timer?.cancel();
    _secondsLeft = _questionSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft == 0) {
        _onTimeOut();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _onTimeOut() {
    _timer?.cancel();
    setState(() {
      _answered    = true;
      _selectedIdx = -1;
    });
  }

  //————————————————— إرسال الإجابة
  void _submit(int idx) async {
    if (_answered) return;
    final correct = idx == _q.correctIndex;
    final pts     = _questionPoints(_q);

    setState(() {
      _selectedIdx = idx;
      _answered    = true;
      if (correct) _earnedInComp += pts;
    });

    if (correct) await _addPointsToUser(pts);
    _timer?.cancel();
  }

  Future<void> _addPointsToUser(int pts) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'points': FieldValue.increment(pts)}, SetOptions(merge: true));
  }

  //————————————————— التالي / النتيجة
  void _next() {
    if (_current == _totalQs - 1) {
      _showResult();
    } else {
      setState(() {
        _current     ++;
        _answered     = false;
        _selectedIdx  = -1;
      });
      _resetTimer();
    }
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: mainColor,
          title  : const Text('النتيجة النهائية',
              style: TextStyle(color: secondaryColor)),
          content: Text('حصلت على $_earnedInComp نقطة في هذه المسابقة.',
              style: const TextStyle(color: secondaryColor)),
          actions: [
            TextButton(
              onPressed: () async {
                await _recordParticipation();        // ⭐️
                if (!mounted) return;
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('إغلاق',
                  style: TextStyle(color: secondaryColor)),
            ),
          ],
        ),
      ),
    );
  }

  /// ———  تسجيل أن المستخدم أنهى المسابقة
  Future<void> _recordParticipation() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('competitions')
        .doc(widget.competitionId)
        .collection('participants')
        .doc(uid)
        .set({
      'score'     : _earnedInComp,
      'finishedAt': FieldValue.serverTimestamp(),
    });
  }

  //————————————————— واجهة المستخدم
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: secondaryColor,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // الشريط العلوي
                Row(
                  children: [
                    _timerBox(),
                    const Spacer(),
                    Text(
                      '${_current + 1} من $_totalQs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: mainColor,
                      ),
                    ),
                    const Spacer(),
                    _pointsBox(_questionPoints(_q)),
                  ],
                ),
                const SizedBox(height: 12),
                // صندوق السؤال
                Container(
                  width: double.infinity,
                  height: w * .4,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: mainColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _q.questionText,
                      style: const TextStyle(
                        color: secondaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // الخيارات
                Expanded(
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _q.options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _optionTile(i),
                  ),
                ),
                // زر التالي / النتيجة
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _answered ? _next : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _answered
                          ? mainColor
                          : secondaryColor.withOpacity(.4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _current == _totalQs - 1 ? 'عرض النتيجة' : 'التالي',
                      style: TextStyle(
                        fontSize: 18,
                        color: _answered ? secondaryColor : mainColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //—————————— عناصر واجهة
  Widget _timerBox() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: _roundedBoxStyle(),
    child: Row(
      children: [
        Icon(Icons.access_time, size: 22, color: mainColor),
        const SizedBox(width: 4),
        Text(
          _formatSeconds(_secondsLeft),
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Digital-7',
            color: mainColor,
          ),
        ),
      ],
    ),
  );

  Widget _pointsBox(int pts) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: _roundedBoxStyle(),
    child: Text(
      '$pts درجة',
      style: TextStyle(fontSize: 16, color: mainColor),
    ),
  );

  BoxDecoration _roundedBoxStyle() => BoxDecoration(
    color: secondaryColor,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: mainColor.withOpacity(.3)),
  );

  Widget _optionTile(int idx) {
    Color bg;
    Color txt = mainColor;

    if (!_answered) {
      bg = secondaryColor.withOpacity(.1);
    } else if (idx == _q.correctIndex) {
      bg  = mainColor.withOpacity(.15);
      txt = mainColor;
    } else if (idx == _selectedIdx) {
      bg  = Colors.red.withOpacity(.15);   // لا بأس بالإبقاء على تلوين الخطأ
      txt = Colors.red.shade800;
    } else {
      bg = secondaryColor.withOpacity(.1);
    }

    return InkWell(
      onTap: _answered ? null : () => _submit(idx),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: mainColor.withOpacity(.25)),
        ),
        alignment: Alignment.center,
        child: Text(
          _q.options[idx],
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: txt,
          ),
        ),
      ),
    );
  }

  //—————————— أدوات مساعدة
  int _questionPoints(Question q) {
    try {
      final pts = (q as dynamic).points as int?;
      if (pts != null) return pts;
    } catch (_) {}
    return widget.pointsPerQuestion;
  }

  String _formatSeconds(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
