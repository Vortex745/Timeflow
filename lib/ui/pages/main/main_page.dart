import 'dart:ui'; // 用于 ImageFilter
import 'package:flutter/cupertino.dart'; // 引入 iOS 风格圆润图标
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common/bouncing_widget.dart';
import '../tasks/task_page.dart';
import '../finance/finance_page.dart';
import '../profile/profile_page.dart';
import '../../pages/weather/weather_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // 默认选中第 1 项 "待办" (index 1)，因为记账页还没写
  int _currentIndex = 0;

  // 页面容器
  final List<Widget> _pages = [
    // 0: 记账
    const FinancePage(),
    // 1: 待办 (已完成)
    const TaskPage(),
    // 2: 天气
    const WeatherPage(),
    // 3: 我的
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Stack 使得 Dock 可以悬浮在内容之上
      body: Stack(
        children: [
          // --- 1. 页面内容层 ---
          Positioned.fill(
            child: RepaintBoundary(
              child: IndexedStack(index: _currentIndex, children: _pages),
            ),
          ),

          // 2. 底部 Dock 栏 (固定在底部，像传统导航栏但带有磨砂效果)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildGlassDock(context),
          ),
        ],
      ),
    );
  }

  // --- 磨砂玻璃 Dock ---
  Widget _buildGlassDock(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            top: 10.h,
            bottom: 10.h + MediaQuery.of(context).padding.bottom, // 适配底部安全区
          ),
          decoration: BoxDecoration(
            color: isDark
                ? theme.cardColor.withOpacity(0.9)
                : Colors.white.withOpacity(0.9),
            border: Border(
              top: BorderSide(
                color: theme.dividerColor.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDockItem(
                context,
                0,
                Icons.account_balance_wallet_rounded,
                "记账",
              ),
              _buildDockItem(
                context,
                1,
                Icons.check_circle_outline_rounded,
                "待办",
              ),
              _buildDockItem(context, 2, Icons.wb_sunny_rounded, "天气"),
              _buildDockItem(context, 3, Icons.person_outline_rounded, "我的"),
            ],
          ),
        ),
      ),
    );
  }

  // 构建单个 Dock 按钮
  Widget _buildDockItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final bool isSelected = _currentIndex == index;
    final theme = Theme.of(context);

    return BouncingWidget(
      onPress: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(0, isSelected ? -2 : 0, 0),
              child: Icon(
                icon,
                size: 24.sp,
                color: isSelected
                    ? theme.primaryColor
                    : theme.iconTheme.color?.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                color: isSelected
                    ? theme.primaryColor
                    : theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
