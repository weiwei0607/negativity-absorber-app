import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  final String id;
  final String name;
  final Color primary;
  final Color secondary;
  final Color scaffoldBg;
  final Color surface;

  const AppTheme({
    required this.id,
    required this.name,
    required this.primary,
    required this.secondary,
    required this.scaffoldBg,
    required this.surface,
  });
}

final List<AppTheme> presetThemes = [
  const AppTheme(
    id: 'midnight',
    name: '午夜紅',
    primary: Color(0xFFE94560),
    secondary: Color(0xFF00D9FF),
    scaffoldBg: Color(0xFF0F0F1B),
    surface: Color(0xFF1A1A2E),
  ),
  const AppTheme(
    id: 'ocean',
    name: '寧靜藍',
    primary: Color(0xFF3498DB),
    secondary: Color(0xFF1ABC9C),
    scaffoldBg: Color(0xFF0A1628),
    surface: Color(0xFF14213D),
  ),
  const AppTheme(
    id: 'forest',
    name: '森林綠',
    primary: Color(0xFF27AE60),
    secondary: Color(0xFFF39C12),
    scaffoldBg: Color(0xFF0B1A0B),
    surface: Color(0xFF1A2E1A),
  ),
  const AppTheme(
    id: 'sunset',
    name: '暖陽橘',
    primary: Color(0xFFE67E22),
    secondary: Color(0xFFE74C3C),
    scaffoldBg: Color(0xFF1A120B),
    surface: Color(0xFF2E1A0F),
  ),
  const AppTheme(
    id: 'aurora',
    name: '迷幻紫',
    primary: Color(0xFF9B59B6),
    secondary: Color(0xFF00D9FF),
    scaffoldBg: Color(0xFF120B1A),
    surface: Color(0xFF1E1430),
  ),
  const AppTheme(
    id: 'rose',
    name: '玫瑰粉',
    primary: Color(0xFFFF6B9D),
    secondary: Color(0xFFC44569),
    scaffoldBg: Color(0xFF1A0F14),
    surface: Color(0xFF2E1A22),
  ),
];

class ThemeNotifier extends StateNotifier<AppTheme> {
  ThemeNotifier() : super(presetThemes.first);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('app_theme_id');
    if (id != null) {
      final theme = presetThemes.firstWhere(
        (t) => t.id == id,
        orElse: () => presetThemes.first,
      );
      state = theme;
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme_id', theme.id);
    state = theme;
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppTheme>(
  (ref) => ThemeNotifier(),
);
