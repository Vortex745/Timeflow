import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../providers/finance_provider.dart';
import '../../../data/models/finance_record.dart';
import '../../common/bouncing_widget.dart';
import 'widgets/add_record_sheet.dart';
import '../../../core/constants/app_categories.dart';

import '../../widgets/custom_dialog.dart';
import 'ledger_page.dart'; // 引入账本页

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceProvider>().loadRecords();
    });
  }

  // --- 弹出预算设置 ---
  void _showBudgetDialog(FinanceProvider provider) async {
    final TextEditingController controller = TextEditingController(
      text: provider.monthlyBudget > 0
          ? provider.monthlyBudget.toStringAsFixed(0)
          : '',
    );

    final result = await showCustomDialog<double>(
      context: context,
      builder: (ctx) => CustomDialog(
        title: "本月预算",
        content: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          child: Row(
            children: [
              Text(
                "¥",
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: "设定预算金额...",
                    hintStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withOpacity(0.5),
                      fontSize: 16.sp,
                    ),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ],
          ),
        ),
        confirmText: "保存",
        onConfirm: () {
          final val = double.tryParse(controller.text);
          Navigator.pop(ctx, val);
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );

    if (result != null) {
      provider.setBudget(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // 1. 头部区域 (加大顶部间距适配刘海屏)
          SizedBox(height: MediaQuery.of(context).padding.top + 10.h),
          _buildHeader(context),

          // 2. 核心资产卡片
          _buildAssetCard(),

          // 3. 最近记录列表 (分组展示)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(top: 24.h), // 拉开一点距离
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? theme.scaffoldBackgroundColor
                    : Colors.grey[50], // Light theme: use soft grey background
                borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      theme.brightness == Brightness.dark ? 0.02 : 0.08,
                    ),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Consumer<FinanceProvider>(
                builder: (context, provider, child) {
                  if (provider.records.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  // --- 数据分组逻辑 ---
                  final Map<String, List<FinanceRecord>> grouped = {};
                  for (var record in provider.records) {
                    final dateKey = DateFormat('yyyy-MM-dd').format(
                      DateTime.fromMillisecondsSinceEpoch(record.dateMs),
                    );
                    if (grouped[dateKey] == null) grouped[dateKey] = [];
                    grouped[dateKey]!.add(record);
                  }

                  final sortedKeys = grouped.keys.toList()
                    ..sort((a, b) => b.compareTo(a)); // 日期倒序

                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(20.w, 25.h, 20.w, 110.h),
                    itemCount: sortedKeys.length,
                    itemBuilder: (context, index) {
                      final dateKey = sortedKeys[index];
                      final records = grouped[dateKey]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 日期头
                          Padding(
                            padding: EdgeInsets.only(
                              left: 4.w,
                              bottom: 12.h,
                              top: index == 0 ? 0 : 16.h,
                            ),
                            child: Text(
                              _formatDateHeader(dateKey),
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                          // 当日记录列表
                          ...records.map(
                            (record) => Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: _buildTransactionItem(context, record),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(String dateKey) {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final yesterday = DateFormat(
      'yyyy-MM-dd',
    ).format(now.subtract(const Duration(days: 1)));

    if (dateKey == today) return "今天";
    if (dateKey == yesterday) return "昨天";

    final date = DateTime.parse(dateKey);
    return DateFormat("MM月dd日").format(date);
  }

  // --- 顶部问候与按钮 ---
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
      margin: EdgeInsets.only(bottom: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: BouncingWidget(
              onPress: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const LedgerPage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOut;
                          var tween = Tween(
                            begin: begin,
                            end: end,
                          ).chain(CurveTween(curve: curve));
                          return SlideTransition(
                            position: animation.drive(tween),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.cardColor.withOpacity(0.5)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.04 : 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "本月支出",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: theme.textTheme.bodySmall?.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10.sp,
                          color: theme.iconTheme.color?.withOpacity(0.5),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Consumer<FinanceProvider>(
                      builder: (_, provider, __) => FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "¥ ${provider.totalExpense.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          // 记一笔按钮
          BouncingWidget(
            onPress: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false,
                  barrierDismissible: true,
                  barrierColor: Colors.black.withOpacity(0.5),
                  transitionDuration: const Duration(milliseconds: 350),
                  reverseTransitionDuration: const Duration(milliseconds: 300),
                  pageBuilder: (_, __, ___) => const AddRecordSheet(),
                  transitionsBuilder: (_, anim, __, child) {
                    return SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 1),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: child,
                    );
                  },
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor.withOpacity(0.1),
                    theme.primaryColor.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle,
                    color: theme.primaryColor,
                    size: 18.sp,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    "记一笔",
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 资产概览卡片 ---
  Widget _buildAssetCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Consumer<FinanceProvider>(
        builder: (context, provider, _) {
          final hasBudget = provider.monthlyBudget > 0;
          final mainValue = hasBudget
              ? (provider.monthlyBudget - provider.totalExpense)
              : (provider.totalIncome - provider.totalExpense);

          final title = hasBudget ? "剩余预算" : "资产结余";

          // --- 胶囊条相关计算 ---
          double percent = 0;
          Color barColor = Colors.grey;
          String statusText = "";

          if (hasBudget) {
            double remaining = provider.monthlyBudget - provider.totalExpense;
            percent = remaining / provider.monthlyBudget;
            if (percent > 0.5) {
              barColor = const Color(0xFF00B894); // Green
              statusText = "${(percent * 100).toStringAsFixed(0)}%";
            } else if (percent > 0.2) {
              barColor = Colors.orange;
              statusText = "${(percent * 100).toStringAsFixed(0)}%";
            } else if (percent > 0) {
              barColor = Colors.redAccent;
              statusText = "${(percent * 100).toStringAsFixed(0)}%";
            } else {
              barColor = Colors.transparent; // Empty
              percent = 0;
              statusText = "已超支";
            }
          }

          return BouncingWidget(
            onPress: () => _showBudgetDialog(provider), // 点击弹出预算设置
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                // Use primaryGradient from AppColors but ideally should adapt?
                // Creating a simplified gradient from theme primaryColor
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.8),
                    Theme.of(context).primaryColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28.r),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14.sp,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          if (hasBudget)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                "总预算 ${provider.monthlyBudget.toStringAsFixed(0)}",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Icon(
                        Icons.settings_outlined,
                        color: Colors.white.withOpacity(0.8),
                        size: 20.sp,
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    "¥ ${mainValue.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // --- 底部：收入显示 OR 余额胶囊 ---
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_downward_rounded,
                              color: Colors.white,
                              size: 16.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              "收入 ¥${provider.totalIncome.toStringAsFixed(0)}",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasBudget) ...[
                        SizedBox(width: 12.w),
                        // 余额提醒胶囊
                        Expanded(
                          child: Container(
                            height: 32.h,
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Row(
                              children: [
                                // 进度条部分
                                Expanded(
                                  flex: (percent * 100).toInt(),
                                  child: percent > 0
                                      ? Container(
                                          margin: EdgeInsets.symmetric(
                                            vertical: 4.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: barColor,
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                          ),
                                        )
                                      : SizedBox(),
                                ),
                                // 空白部分
                                Expanded(
                                  flex: 100 - (percent * 100).toInt(),
                                  child: SizedBox(),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: 6.w,
                                    right: 8.w,
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- 单条交易记录 ---
  Widget _buildTransactionItem(BuildContext context, FinanceRecord record) {
    final theme = Theme.of(context);
    final date = DateTime.fromMillisecondsSinceEpoch(record.dateMs);
    final timeStr = DateFormat('HH:mm').format(date);

    final iconData = AppCategories.getIcon(record.category);
    final iconColor = AppCategories.getColor(record.category);

    return BouncingWidget(
      onPress: () {},
      scaleFactor: 0.98,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? theme.cardColor
              : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                theme.brightness == Brightness.dark ? 0.01 : 0.06,
              ),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: theme.brightness == Brightness.dark
                ? theme.dividerColor.withOpacity(0.05)
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // 1. 分类图标
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 22.sp),
            ),
            SizedBox(width: 14.w),

            // 2. 信息区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.category,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleMedium?.color,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 12.sp,
                        ),
                      ),
                      // 如果有备注，显示备注
                      if (record.note.isNotEmpty) ...[
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            record.note,
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 12.sp,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // 3. 金额
            Text(
              "${record.isExpense ? '-' : '+'} ${record.amount.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
                color: record.isExpense
                    ? theme.textTheme.titleMedium?.color
                    : const Color(0xFF00B894), // 收入用绿色
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 空状态 ---
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.savings_outlined,
            size: 60.sp,
            color: Theme.of(context).disabledColor.withOpacity(0.3),
          ),
          SizedBox(height: 10.h),
          Text(
            "本月还没有记账哦",
            style: TextStyle(
              color: Theme.of(context).disabledColor,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }
}
