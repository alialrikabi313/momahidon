// ignore_for_file: depend_on_referenced_packages
// lib/screens/CompetitionsPage.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:momahidon/colors.dart';

import 'package:momahidon/data/Dummy%20Data.dart';
import 'CompetitionQuestionsPage.dart';

/// ---------------------------------------------------------------------------
///                        Competition  View-Model
/// ---------------------------------------------------------------------------
class CompetitionVM {
  final String id;
  final Competition base;
  final DateTime endTime;
  final int pointsPerQuestion;

  CompetitionVM({
    required this.id,
    required this.base,
    required this.endTime,
    required this.pointsPerQuestion,
  });

  int get questionsCount => base.questions.length;
  int get totalPoints    => pointsPerQuestion * questionsCount;
}

CompetitionVM _vmFromDoc(DocumentSnapshot doc) {
  final d      = doc.data()! as Map<String, dynamic>;
  final rawEnd = d['endTime'];
  final end    = rawEnd is Timestamp ? rawEnd.toDate() : (rawEnd as DateTime);

  return CompetitionVM(
    id: doc.id,
    base: Competition.fromMap(d),
    endTime: end,
    pointsPerQuestion: d['pointsPerQuestion'] ?? 1,
  );
}

/// ---------------------------------------------------------------------------
///                       صفحة  المسابقات  +  المتصدِّرين
/// ---------------------------------------------------------------------------
class CompetitionsPage extends StatefulWidget {
  const CompetitionsPage({Key? key}) : super(key: key);

  @override
  State<CompetitionsPage> createState() => _CompetitionsPageState();
}

class _CompetitionsPageState extends State<CompetitionsPage> {
  final List<CompetitionVM> _comps = [];
  late final StreamSubscription<QuerySnapshot> _sub;

  @override
  void initState() {
    super.initState();
    _sub = FirebaseFirestore.instance
        .collection('competitions')
        .snapshots()
        .listen(_onSnapshot);
  }

  Future<void> _onSnapshot(QuerySnapshot snap) async {
    final now  = DateTime.now();
    final List<CompetitionVM> fresh = [];

    for (final doc in snap.docs) {
      final vm = _vmFromDoc(doc);
      if (vm.endTime.isBefore(now)) {
        await FirebaseFirestore.instance
            .collection('archive')
            .doc(vm.id)
            .set(doc.data() as Map<String, dynamic>);
        await doc.reference.delete();
      } else {
        fresh.add(vm);
      }
    }

    setState(() {
      _comps
        ..clear()
        ..addAll(fresh);
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  /// -----------------------------------------------------------------
  ///   تحقّق إنْ كان المستخدم قد شارك سابقًا
  /// -----------------------------------------------------------------
  Future<void> _openIfNotPlayed(CompetitionVM vm) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance
        .collection('competitions')
        .doc(vm.id)
        .collection('participants')
        .doc(uid);

    if ((await ref.get()).exists) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: const AlertDialog(
            title: Text('تنبيه'),
            content: Text('لقد شاركت في هذه المسابقة من قبل.'),
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompetitionQuestionsPage(
          competitionId: vm.id,
          competition: vm.base,
          pointsPerQuestion: vm.pointsPerQuestion,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: secondaryColor,
        appBar: AppBar(
          backgroundColor: mainColor,
          elevation: 0,
          centerTitle: true,
          // يمنع إضافة سهم الرجوع تلقائياً
          automaticallyImplyLeading: false,
          title: const Text(
            'المسابقات',
            style: TextStyle(color: Colors.white),
          ),
          bottom: TabBar(
            labelColor: secondaryColor,
            unselectedLabelColor: secondaryColor.withOpacity(.6),
            indicatorColor: secondaryColor,
            tabs: const [
              Tab(text: 'المسابقات'),
              Tab(text: 'المتصدرون'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ----------------- تبويب المسابقات
            Directionality(
              textDirection: TextDirection.rtl,
              child: SafeArea(
                child: _comps.isEmpty
                    ? const Center(
                  child: Text(
                    'لا توجد مسابقات حاليًّا',
                    style: TextStyle(fontSize: 18),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _comps.length,
                  itemBuilder: (_, i) => _CompetitionCard(
                    vm: _comps[i],
                    onTap: () => _openIfNotPlayed(_comps[i]),
                  ),
                ),
              ),
            ),
            // ----------------- تبويب المتصدّرين
            const _LeaderboardTab(),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
///                              بطاقة  المسابقة
/// ---------------------------------------------------------------------------
class _CompetitionCard extends StatefulWidget {
  final CompetitionVM vm;
  final VoidCallback  onTap;

  const _CompetitionCard({
    required this.vm,
    required this.onTap,
    Key?   key,
  }) : super(key: key);

  @override
  State<_CompetitionCard> createState() => _CompetitionCardState();
}

class _CompetitionCardState extends State<_CompetitionCard> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(_tick));
  }

  void _tick() {
    final diff = widget.vm.endTime.difference(DateTime.now());
    _remaining = diff.isNegative ? Duration.zero : diff;
  }

  String _fmt(Duration d) {
    final d0 = d.inDays.toString().padLeft(2, '0');
    final h  = d.inHours.remainder(24).toString().padLeft(2, '0');
    final m  = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s  = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$d0:$h:$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w         = MediaQuery.of(context).size.width;
    final cardH     = math.min(w * .55, 260.0);
    final titleSize = math.max(w * .07, 18.0).clamp(18.0, 26.0);
    final smallFs   = math.max(w * .045, 12.0);

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: cardH,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              mainColor.withOpacity(.65),
              mainColor,
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // -------------------- اسم المسابقة
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.vm.base.title,
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Tajawal',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const Spacer(),
            // -------------------- الإحصاءات
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.help_outline,
                      color: secondaryColor, size: w * .07),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text('عدد الأسئلة: ${widget.vm.questionsCount}',
                        style: TextStyle(
                            color: secondaryColor, fontSize: smallFs)),
                  ),
                  const Spacer(),
                  Icon(Icons.star, color: Colors.yellow, size: w * .07),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text('الدرجات: ${widget.vm.totalPoints}',
                        style: TextStyle(
                            color: secondaryColor, fontSize: smallFs)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // -------------------- شريط الوقت
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: w * .03,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: secondaryColor.withOpacity(.20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time,
                        color: secondaryColor,
                        size: math.max(w * .08, 20)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'الوقت المتبقي',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: math.max(w * .045, 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _fmt(_remaining),
                        style: TextStyle(
                          color: secondaryColor,
                          fontFamily: 'Digital-7',
                          fontSize: math.max(w * .07, 16),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
///                              تبويب المتصدرين
/// ---------------------------------------------------------------------------
class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('points', isGreaterThan: 0)
            .orderBy('points', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('خطأ: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('لا يوجد متصدرون بعد'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final data   = docs[i].data() as Map<String, dynamic>;
              final name   = data['username'] ?? data['name'] ?? 'مستخدم بدون اسم';
              final points = data['points'] ?? 0;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: secondaryColor.withOpacity(.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: mainColor,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: secondaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.yellow),
                        const SizedBox(width: 4),
                        Text(points.toString(),
                            style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
