import 'package:flutter/material.dart';

import '../colors.dart';

class CustomButton extends StatelessWidget {
  // يمكننا توحيد اللون الافتراضي مع اللون الرئيسي


  final String text;
  final VoidCallback onPressed;
  final Color color;         // في حال أردت تغيير اللون عند الاستخدام
  final double height;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = mainColor,   // نجعل اللون الافتراضي هو اللون الرئيسي
    this.height = 50.0,
    this.borderRadius = 25.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}
