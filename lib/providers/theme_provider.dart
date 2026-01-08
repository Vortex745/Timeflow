import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_colors.dart';

class ThemeProvider with ChangeNotifier {
  static const String _keyThemeColor = 'theme_color';
  static const String _keyThemeMode = 'theme_mode';

  // 预定义的主题颜色
  static const Map<String, Color> themeColors = {
    'Mint Green': AppColors.primary,
    'Ocean Blue': Color(0xFF2E86DE),
    'Sunset Orange': Color(0xFFFF9F43),
    'Royal Purple': Color(0xFF5F27CD),
  };

  // 默认颜色
  Color _primaryColor = AppColors.primary;
  String _currentThemeName = 'Mint Green';

  Color get primaryColor => _primaryColor;
  String get currentThemeName => _currentThemeName;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Color
    final colorValue = prefs.getInt(_keyThemeColor);
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
      _currentThemeName = themeColors.entries
          .firstWhere(
            (element) => element.value.value == colorValue,
            orElse: () => MapEntry('Custom', _primaryColor),
          )
          .key;
    }

    // Load Theme Mode
    final modeIndex = prefs.getInt(_keyThemeMode);
    if (modeIndex != null &&
        modeIndex >= 0 &&
        modeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[modeIndex];
    }

    notifyListeners();
  }

  // 2. 深色模式管理
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Future<void> toggleThemeMode() async {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, _themeMode.index);
  }

  Future<void> setTheme(String name) async {
    if (themeColors.containsKey(name)) {
      _currentThemeName = name;
      _primaryColor = themeColors[name]!;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyThemeColor, _primaryColor.value);

      notifyListeners();
    }
  }
}
