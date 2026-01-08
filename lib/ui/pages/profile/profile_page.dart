import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../controllers/weather_controller.dart';

import '../../../providers/task_provider.dart';
import '../../../providers/finance_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart'; // 引入 ThemeProvider
import '../../common/bouncing_widget.dart';
import '../../widgets/custom_dialog.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // Predefined random avatars
  final List<String> _avatarList = const [
    "https://api.dicebear.com/7.x/notionists/png?seed=Felix",
    "https://api.dicebear.com/7.x/notionists/png?seed=Aneka",
    "https://api.dicebear.com/7.x/notionists/png?seed=Zoe",
    "https://api.dicebear.com/7.x/notionists/png?seed=Jack",
    "https://api.dicebear.com/7.x/notionists/png?seed=Coco",
    "https://api.dicebear.com/7.x/notionists/png?seed=Bella",
  ];

  String _getAvatar(String username) {
    if (username.isEmpty) return _avatarList[0];
    int hash = username.codeUnits.fold(0, (a, b) => a + b);
    return _avatarList[hash % _avatarList.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // 1. 头部用户信息 (监听 AuthProvider)
          Consumer<AuthProvider>(
            builder: (context, auth, _) => _buildHeader(context, auth),
          ),

          // 2. 核心数据卡片
          _buildDashboard(context),

          // 3. 功能菜单列表
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 120.h),
              children: [
                _buildMenuItem(
                  context,
                  Icons.data_usage_rounded,
                  "数据管理",
                  () => _showClearDataDialog(context),
                ),
                SizedBox(height: 12.h),
                _buildMenuItem(
                  context,
                  Icons.palette_rounded,
                  "主题风格",
                  () => _showThemeSheet(context),
                ),
                SizedBox(height: 12.h),
                _buildMenuItem(
                  context,
                  Icons.feedback_outlined,
                  "意见反馈",
                  () => _showFeedbackDialog(context),
                ),
                SizedBox(height: 12.h),
                _buildMenuItem(
                  context,
                  Icons.info_outline_rounded,
                  "关于我们",
                  () => _showAboutDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. 头部组件 ---
  // --- 1. 头部组件 ---
  Widget _buildHeader(BuildContext context, AuthProvider auth) {
    // 获取当前是否深色模式 (兼容 System 跟随)
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 60.h, 20.w, 20.h),
      child: Column(
        children: [
          // 第一行：深浅色切换 (右上角)
          Align(
            alignment: Alignment.centerRight,
            child: Consumer<ThemeProvider>(
              builder: (context, theme, _) {
                return GestureDetector(
                  onTap: () => theme.toggleThemeMode(),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          size: 16.sp,
                          color: isDark ? Colors.yellow : Colors.orange,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          isDark ? "深色" : "浅色",
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 10.h),

          // 第二行：用户登录区块
          GestureDetector(
            onTap: () {
              if (auth.isGuest) {
                _showLoginDialog(context);
              } else {
                _confirmLogout(context, auth);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: EdgeInsets.all(auth.isGuest ? 10.w : 20.w),
              decoration: BoxDecoration(
                color: auth.isGuest
                    ? Colors.transparent
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: auth.isGuest
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  // 头像
                  Hero(
                    tag: 'avatar',
                    child: Container(
                      width: 64.w,
                      height: 64.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).scaffoldBackgroundColor,
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.1),
                          width: 2,
                        ),
                        image: auth.isGuest
                            ? null
                            : DecorationImage(
                                image: NetworkImage(_getAvatar(auth.userName)),
                              ),
                      ),
                      child: auth.isGuest
                          ? Icon(
                              Icons.account_circle_rounded,
                              size: 40.sp,
                              color: Theme.of(
                                context,
                              ).disabledColor.withOpacity(0.3),
                            )
                          : null,
                    ),
                  ),
                  SizedBox(width: 16.w),

                  // 文本区域
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (auth.isGuest)
                          Text(
                            "请登录",
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.titleLarge?.color,
                            ),
                          )
                        else ...[
                          Text(
                            "欢迎回来",
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            auth.userName,
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.titleLarge?.color,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 箭头提示 (仅登录态显示，或引导登录)
                  if (!auth.isGuest)
                    Icon(
                      Icons.logout_rounded,
                      color: Colors.red.withOpacity(0.5),
                      size: 24.sp,
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).disabledColor,
                      size: 24.sp,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. 仪表盘卡片 ---
  Widget _buildDashboard(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withOpacity(0.8),
                  theme.primaryColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Consumer<TaskProvider>(
                  builder: (_, provider, __) => _buildStatItem(
                    provider.tasks.where((t) => t.isDone).length.toString(),
                    "已完成",
                  ),
                ),
                Container(
                  width: 1,
                  height: 30.h,
                  color: Colors.white.withOpacity(0.3),
                ),
                Consumer<FinanceProvider>(
                  builder: (_, provider, __) {
                    final remainingBudget = provider.monthlyBudget > 0
                        ? provider.monthlyBudget - provider.totalExpense
                        : 0.0;
                    return _buildStatItem(
                      remainingBudget.toInt().toString(),
                      "剩余预算",
                    );
                  },
                ),
                Container(
                  width: 1,
                  height: 30.h,
                  color: Colors.white.withOpacity(0.3),
                ),
                Builder(
                  builder: (context) {
                    try {
                      final weatherCtrl = Get.find<WeatherController>();
                      return Obx(() {
                        final data = weatherCtrl.weatherData.value;
                        if (data == null) {
                          return _buildStatItem("--", "获取中");
                        }
                        final code = data.current.weatherCode;
                        final temp = data.current.temperature.round();
                        final desc = _getWeatherDesc(code);
                        final emoji = _getWeatherEmoji(
                          code,
                          data.current.isDay == 1,
                        );

                        return _buildStatItem("$emoji $temp°", desc);
                      });
                    } catch (e) {
                      return _buildStatItem("--", "无数据");
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getWeatherDesc(int code) {
    if (code == 0) return "晴";
    if (code == 1 || code == 2 || code == 3) return "多云";
    if (code >= 45 && code <= 48) return "雾";
    if (code >= 51 && code <= 67) return "雨";
    if (code >= 71 && code <= 77) return "雪";
    if (code >= 80 && code <= 99) return "雷雨";
    return "未知";
  }

  String _getWeatherEmoji(int code, bool day) {
    if (code == 0) return day ? "☀️" : "🌙";
    if (code == 1 || code == 2 || code == 3) return day ? "⛅" : "☁️";
    if (code >= 45 && code <= 48) return "🌫️";
    if (code >= 51 && code <= 67) return "🌧️";
    if (code >= 71 && code <= 77) return "❄️";
    if (code >= 95) return "⚡";
    return "🌡️";
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  // --- 3. 菜单项 ---
  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return BouncingWidget(
      scaleFactor: 0.98,
      onPress: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Theme.of(context).iconTheme.color,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).disabledColor,
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }

  // --- 交互逻辑 ---

  // 1. 登录弹窗 (Unified and Animated)
  void _showLoginDialog(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final lastUser = await auth.getLastLoginUser();
    final TextEditingController userController = TextEditingController(
      text: lastUser,
    );

    if (!context.mounted) return;

    showCustomDialog(
      context: context,
      builder: (ctx) => CustomDialog(
        title: "登录 / 注册",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: TextField(
                controller: userController,
                maxLength: 8,
                decoration: const InputDecoration(
                  hintText: "请输入用户名",
                  border: InputBorder.none,
                  icon: Icon(Icons.person_outline),
                  counterText: "",
                ),
              ),
            ),
          ],
        ),
        confirmText: "立即登录",
        onConfirm: () {
          if (userController.text.isNotEmpty) {
            auth.login(userController.text, "password");
            Navigator.pop(ctx);
          }
        },
      ),
    );
  }

  // 3. 退出确认
  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showCustomDialog(
      context: context,
      builder: (ctx) => CustomDialog(
        title: "退出登录",
        content: const Text("确定要退出当前账号吗？"),
        confirmText: "退出",
        confirmColor: Colors.red,
        onConfirm: () {
          auth.logout();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  // 3. 主题选择面板
  void _showThemeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) => Consumer<ThemeProvider>(
        builder: (context, theme, child) {
          return Container(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "选择主题",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20.h),
                Wrap(
                  spacing: 16.w,
                  runSpacing: 16.h,
                  children: ThemeProvider.themeColors.entries.map((entry) {
                    final isSelected = entry.key == theme.currentThemeName;
                    return GestureDetector(
                      onTap: () {
                        theme.setTheme(entry.key);
                        Navigator.pop(ctx);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60.w,
                            height: 60.w,
                            decoration: BoxDecoration(
                              color: entry.value,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge!.color!,
                                      width: 2,
                                    )
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: entry.value.withOpacity(0.4),
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 4. 清除数据弹窗 (Styled)
  void _showClearDataDialog(BuildContext context) {
    showCustomDialog(
      context: context,
      builder: (ctx) => CustomDialog(
        title: "清除数据",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48.sp),
            SizedBox(height: 16.h),
            const Text(
              "确定要清空【当前用户】的所有任务和账单吗？\n此操作不可恢复！",
              textAlign: TextAlign.center,
            ),
          ],
        ),
        confirmText: "确认清空",
        confirmColor: Colors.red,
        onConfirm: () {
          context.read<TaskProvider>().clearAllTasks();
          context.read<FinanceProvider>().clearAllRecords();
          Navigator.pop(ctx);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("数据已清空")));
        },
      ),
    );
  }

  // 5. 关于我们
  void _showAboutDialog(BuildContext context) {
    showCustomDialog(
      context: context,
      builder: (ctx) => CustomDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "TimeFlow",
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            Text("v1.0.0", style: TextStyle(color: Colors.grey)),
            SizedBox(height: 16.h),
            const Text("一款集待办事项与记账于一体的极简应用。\n\n让每一分钟和每一分钱都有意义。"),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showUpdateLogDialog(context);
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              child: const Text("查看更新日志"),
            ),
          ],
        ),
        showCancelButton: false,
        confirmText: "关闭",
        onConfirm: () => Navigator.pop(ctx),
      ),
    );
  }

  void _showUpdateLogDialog(BuildContext context) {
    showCustomDialog(
      context: context,
      builder: (c) => CustomDialog(
        title: "更新日志",
        content: SizedBox(
          height: 200.h,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "v1.0.0 (2025-01-07)",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("- 首次发布"),
                Text("- 实现待办事项分组管理"),
                Text("- 实现收支记录与统计"),
                Text("- 新增多用户登录与数据隔离"),
                Text("- 新增主题切换功能"),
              ],
            ),
          ),
        ),
        showCancelButton: false,
        confirmText: "关闭",
        onConfirm: () => Navigator.pop(c),
      ),
    );
  }

  // 6. 意见反馈
  void _showFeedbackDialog(BuildContext context) {
    showCustomDialog(
      context: context,
      builder: (ctx) => CustomDialog(
        title: "意见反馈",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_unread_outlined,
                size: 32.sp,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              "如果您有任何建议或发现Bug，\n欢迎随时联系作者：",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.8),
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
              child: SelectableText(
                "zijinn123@outlook.com",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  fontFamily: 'Roboto',
                ),
                toolbarOptions: const ToolbarOptions(
                  copy: true,
                  selectAll: true,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "（长按上方邮箱可复制）",
              style: TextStyle(
                fontSize: 10.sp,
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
        showCancelButton: false,
        confirmText: "我知道了",
        onConfirm: () => Navigator.pop(ctx),
      ),
    );
  }
}
