
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart' show CachedNetworkImage;
import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart' show GallerySaver;
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';

class FullScreenImagePage extends StatelessWidget {
  final String url; // نفس التوقيع المستعمل فى Home & PostDetails
  const FullScreenImagePage({super.key, required this.url});

  /*────────────────── حفظ الصورة ──────────────────*/
  Future<void> _saveImage(BuildContext context) async {
    // Android 13+ يتطلّب صلاحية صور بدلاً من التخزين
    final isApi33Plus = Platform.isAndroid &&
        (await DeviceInfoPlugin().androidInfo).version.sdkInt >= 33;
    // طلب الصلاحية الملائمة
    final PermissionStatus status = isApi33Plus
        ? await Permission.photos.request()
        : await Permission.storage.request();

    if (!status.isGranted) {
      if (status.isPermanentlyDenied) await openAppSettings();
      return;
    }

    try {
      // نزّل الملف مؤقتاً ثم خزّنه بالمعرض
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Dio().download(url, filePath);
      final saved = await GallerySaver.saveImage(filePath);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(saved == true ? '✅ تم حفظ الصورة في المعرض' : 'فشل حفظ الصورة')));
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء تنزيل الصورة')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () => _saveImage(context),
          )
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(          // ⬅️ بدّل Image.network
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (_, __) =>
            const Center(child: CircularProgressIndicator()),
            errorWidget: (_, __, ___) =>
            const Icon(Icons.wifi_off, size: 60, color: Colors.white70),
          ),
        ),
      ),     );
  }
}