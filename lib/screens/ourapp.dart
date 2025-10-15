import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../colors.dart';

class AppsScreen extends StatelessWidget {
  const AppsScreen({Key? key}) : super(key: key);

  // قائمة التطبيقات وروابطها
  final List<Map<String, String>> apps = const [
    {
      "name": "موجز الأحكام",
      "url": "https://play.google.com/store/apps/details?id=com.alialrikabi313.mojazahkam"
    },
    {
      "name": "مكتبة الحديث",
      "url": "https://play.google.com/store/apps/details?id=com.alialrikabi313.hadithlibrary313.hadithbook"
    },
    {
      "name": "مكتبة الفقه الشيعي",
      "url": "https://play.google.com/store/apps/details?id=com.alialrikabi313.fiqahbook"
    },
    {
      "name": "مكتبة أصول الفقه",
      "url": "https://play.google.com/store/apps/details?id=com.alialrikabi313.osoolbook"
    },
    {
      "name": "مكتبة العقائد",
      "url": "https://play.google.com/store/apps/details?id=com.alialrikabi313.aqaedbook.aqaedbook"
    },
    {
      "name": "مكتبة الرجال",
      "url": "https://play.google.com/store/apps/details?id=com.alialrikabi313.rijalbook"
    },
    {
      "name": "المكتبة الحسينية",
      "url": "https://play.google.com/store/apps/details?id=com.alialrikabi313.imamhussenbook"
    },
    {
      "name": "مكتبة التفسير الشيعي",
      "url": "https://play.google.com/store/apps/details?id=com.alialrikabi313.tafsirbook"
    },
    {
      "name": "المكتبة المهدوية",
      "url": "https://play.google.com/store/apps/details?id=com.alialrikabi313.mahdawiabook"
    },
    {
      "name": "مكتبة السيرة",
      "url": "https://play.google.com/store/apps/details?id=com.alialrikabi313.sirabook"
    },
    {
      "name": "مكتبة اللغة العربية",
      "url": "https://play.google.com/store/apps/details?id=com.alialrikabi313.lughabook"
    },
    {
      "name": "مكتبة النحو",
      "url": "https://play.google.com/store/apps/details?id=com.alialrikabi313.nahwbook"
    },
  ];

  @override
  Widget build(BuildContext context) {
    // دالة لفتح الرابط مع التحقق باستخدام canLaunchUrl
    Future<void> _launchURL(String url) async {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح الرابط: $url')),
        );
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("تطبيقاتنا", style: TextStyle(color: Colors.white),),
          automaticallyImplyLeading: false,
          centerTitle: true,
          backgroundColor: mainColor,
        ),
        body: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: apps.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final app = apps[index];
            return InkWell(
              onTap: () => _launchURL(app["url"]!),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: mainColor, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      app["name"]!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(Icons.arrow_forward, color: mainColor),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
