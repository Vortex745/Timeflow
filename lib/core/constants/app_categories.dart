import 'package:flutter/material.dart';

class AppCategories {
  AppCategories._();

  // --- 1. 定义分类列表 ---
  // 支出分类
  static const List<String> expenseList = [
    "餐饮",
    "购物",
    "交通",
    "娱乐",
    "生活",
    "房租",
    "医疗",
    "学习",
    "零食",
    "日用",
  ];

  // 收入分类
  static const List<String> incomeList = ["工资", "奖金", "理财", "兼职", "礼金"];

  // --- 2. 获取图标 ---
  static IconData getIcon(String category) {
    switch (category) {
      // 支出
      case "餐饮":
        return Icons.restaurant;
      case "购物":
        return Icons.shopping_bag;
      case "交通":
        return Icons.directions_car;
      case "娱乐":
        return Icons.videogame_asset;
      case "生活":
        return Icons.local_florist;
      case "房租":
        return Icons.home;
      case "医疗":
        return Icons.local_hospital;
      case "学习":
        return Icons.school;
      case "零食":
        return Icons.cake;
      case "日用":
        return Icons.cleaning_services;

      // 收入
      case "工资":
        return Icons.account_balance_wallet;
      case "奖金":
        return Icons.emoji_events;
      case "理财":
        return Icons.trending_up;
      case "兼职":
        return Icons.work;
      case "礼金":
        return Icons.card_giftcard;

      default:
        return Icons.category;
    }
  }

  // --- 3. 获取颜色 (配合绿色主题优化) ---
  static Color getColor(String category) {
    // 简单的哈希算法，让不同分类有固定且好看的颜色
    final colors = [
      Color(0xFF00B894), // 绿
      Color(0xFF0984E3), // 蓝
      Color(0xFF6C5CE7), // 紫
      Color(0xFFE17055), // 橘红
      Color(0xFFFD79A8), // 粉
      Color(0xFF00CEC9), // 青
      Color(0xFFFDCB6E), // 黄
    ];
    // 根据文字长度取余数，保证同一个分类颜色固定
    return colors[category.hashCode % colors.length];
  }
}
