import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --- 🎨 青春活力绿 (Mint Aurora) ---
  // 主色：清新的薄荷绿，非常有呼吸感
  static const Color primary = Color(0xFF00B894);

  // 渐变：从“嫩草绿”流向“蒂芙尼青”，像极光一样通透
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF42E695), Color(0xFF3BB2B8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 收入/支出颜色
  static const Color expense = Color(0xFFFF7675); // 柔和的西柚红
  static const Color income = Color(0xFF00CEC9);  // 活力的青色

  // 背景色：保持极淡的灰白，突出绿色的鲜艳
  static const Color background = Color(0xFFF7F9FC);

  static const Color surface = Colors.white;

  static const Color textPrimary = Color(0xFF2D3436);   // 深灰
  static const Color textSecondary = Color(0xFF636E72); // 次级灰

  // --- 💡 阴影系统 ---
  // 1. 核心阴影：绿色光晕 (Mint Glow)
  static List<BoxShadow> shadowPrimary = [
    BoxShadow(
      color: const Color(0xFF42E695).withOpacity(0.4), // 绿色投影
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // 2. Dock 阴影
  static List<BoxShadow> shadowDock = [
    BoxShadow(
      color: const Color(0xFF2D3436).withOpacity(0.08),
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
  ];

  // 3. 普通卡片阴影
  static List<BoxShadow> shadowCard = [
    BoxShadow(
      color: const Color(0xFF2D3436).withOpacity(0.04),
      blurRadius: 15,
      offset: const Offset(0, 4),
    ),
  ];
}