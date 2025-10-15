import 'package:flutter/material.dart';

class BannerInfo {
  final String imagePath; // Firebase Storage path
  final String link;      // external link
  const BannerInfo({required this.imagePath, required this.link});
}

class CategoryInfo {
  final String uiName;
  final String fsName;
  final String asset;
  final Color bg;
  const CategoryInfo(this.uiName, this.fsName, this.asset, this.bg);
}