import 'package:flutter/material.dart';
import 'package:momahidon/screens/CompetitionsPage.dart';
import 'package:momahidon/screens/SearchPage.dart';
import 'package:momahidon/screens/home.dart';
import 'package:momahidon/screens/contact.dart';
import 'package:momahidon/screens/ourapp.dart';

import '../colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // ⬅️ يمنع الرجوع تمامًا (زر الجهاز أو الإيماءة)
    return WillPopScope(
      onWillPop: () async => false,
      child: DefaultTabController(
        length: 5,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: secondaryColor,

            // AppBar مخفية (ارتفاع صفر)
            appBar: AppBar(
              backgroundColor: mainColor,
              elevation: 0,
              toolbarHeight: 0,
            ),

            // محتوى كل تبويب
            body: const SafeArea(
              child: TabBarView(
                children: [
                  Home(),
                  AppsScreen(),
                  CompetitionsPage(),
                  SearchPage(),
                  AccountSettingsPage(),
                ],
              ),
            ),

            // شريط التبويب بالأسفل
            bottomNavigationBar: Material(
              color: mainColor,
              child: TabBar(
                indicatorColor: secondaryColor,
                labelColor: secondaryColor,
                unselectedLabelColor: secondaryColor.withOpacity(0.5),
                tabs: [
                  _buildTab(Icons.home, "الرئيسية"),
                  _buildTab(Icons.apps, "تطبيقاتنا"),
                  _buildTab(Icons.emoji_events, "المسابقات"),
                  _buildTab(Icons.search, "البحث"),
                  _buildTab(Icons.account_circle, "الحساب"),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Tab _buildTab(IconData icon, String label) {
    return Tab(
      icon: Icon(icon, size: 24),
      text: label,
    );
  }
}
