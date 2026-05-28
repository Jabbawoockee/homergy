import 'package:flutter/material.dart';

class AppColors {
  static const background    = Color(0xFFEAEEE6);
  static const surface       = Color(0xFFEAEEE6);
  static const green         = Color(0xFF6B8F6B);
  static const greenDark     = Color(0xFF446B47);
  static const amber         = Color(0xFFB08B5E);
  static const textPrimary   = Color(0xFF2A3B2B);
  static const textSecondary = Color(0xFF7A8E7B);
  static const border        = Color(0xFFD4DDD0);
  static const amberDim      = Color(0x33B08B5E);
  static const error         = Color(0xFFCF6754);

  static List<BoxShadow> neu([double d = 7]) => [
    BoxShadow(
      color: const Color(0xFFFFFFFF).withOpacity(0.90),
      offset: Offset(-d, -d),
      blurRadius: d * 2,
    ),
    BoxShadow(
      color: const Color(0xFFC2CFC0),
      offset: Offset(d, d),
      blurRadius: d * 2,
    ),
  ];
}
