import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart'; // 引入 provider 包
import 'package:timeflow/providers/finance_provider.dart';
import 'package:timeflow/ui/pages/main/main_page.dart';

// 引入我们写的 provider
import 'providers/task_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
// 引入常量配置
import 'core/constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 强制竖屏
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    // 关键点：使用 MultiProvider 包裹整个 App
    MultiProvider(
      providers: [
        // 1. 基础 Provider
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // 2. 依赖 AuthProvider 的数据 Provider
        // 当 AuthProvider 的 userId 变化时，自动更新 TaskProvider 里的 userId
        ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
          create: (_) => TaskProvider(),
          update: (_, auth, tasks) => tasks!..updateUserId(auth.userId),
        ),
        ChangeNotifierProxyProvider<AuthProvider, FinanceProvider>(
          create: (_) => FinanceProvider(),
          update: (_, auth, finance) => finance!..updateUserId(auth.userId),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ScreenUtil 初始化，用于屏幕适配
    return ScreenUtilInit(
      designSize: const Size(375, 812), // 设计稿尺寸，通常用 iPhone X 的尺寸
      minTextAdapt: true,
      builder: (context, child) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            // 动态设置系统状态栏和导航栏样式
            final isDark =
                themeProvider.themeMode == ThemeMode.dark ||
                (themeProvider.themeMode == ThemeMode.system &&
                    MediaQuery.platformBrightnessOf(context) ==
                        Brightness.dark);

            SystemChrome.setSystemUIOverlayStyle(
              SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: isDark
                    ? Brightness.light
                    : Brightness.dark,
                systemNavigationBarColor: isDark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                systemNavigationBarIconBrightness: isDark
                    ? Brightness.light
                    : Brightness.dark,
              ),
            );

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'TimeFlow',
              themeMode: themeProvider.themeMode, // 👈 接入深色模式切换
              theme: ThemeData(
                // 使用动态的主题色
                primaryColor: themeProvider.primaryColor,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: themeProvider.primaryColor,
                ),
                scaffoldBackgroundColor: AppColors.background,
                useMaterial3: true,
                fontFamily: 'Roboto',
              ),
              darkTheme: ThemeData.dark().copyWith(
                primaryColor: themeProvider.primaryColor,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: themeProvider.primaryColor,
                  brightness: Brightness.dark,
                ),
                scaffoldBackgroundColor: const Color(0xFF121212),
                cardColor: const Color(0xFF1E1E1E), // Dark card surface
                useMaterial3: true,
                // Ensure text is white in dark mode
                textTheme: ThemeData.dark().textTheme
                    .copyWith(
                      bodyLarge: const TextStyle(color: Colors.white),
                      bodyMedium: const TextStyle(color: Colors.white70),
                      bodySmall: const TextStyle(color: Colors.white54),
                      titleLarge: const TextStyle(color: Colors.white),
                    )
                    .apply(fontFamily: 'Roboto'),
                iconTheme: const IconThemeData(color: Colors.white70),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF1E1E1E),
                  foregroundColor: Colors.white,
                ),
                dialogBackgroundColor: const Color(0xFF1E1E1E),
              ),
              home: const MainPage(),
            );
          },
        );
      },
    );
  }
}
