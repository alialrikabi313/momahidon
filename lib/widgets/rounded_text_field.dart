import 'package:flutter/material.dart';

import '../colors.dart';

class RoundedTextField extends StatelessWidget {


  final String hintText;
  final bool obscureText;
  final TextEditingController controller;

  const RoundedTextField({
    super.key,
    required this.hintText,
    this.obscureText = false,
    required this.controller,  TextInputType? keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // استخدام اللون الرئيسي للحدود
        border: Border.all(color: mainColor, width: 1.5),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}
