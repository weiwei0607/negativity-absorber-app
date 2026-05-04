import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/session_provider.dart';
import 'providers/memory_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/goal_provider.dart';
import 'screens/chat_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/pin_lock_screen.dart';
import 'services/notification_service.dart';
import 'services/pin_service.dart';

class NegativityAbsorberApp extends ConsumerWidget {
  const NegativityAbsorberApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    return MaterialApp(
      title: '負能量吸收器',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(theme),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme(AppTheme theme) {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: theme.scaffoldBg,
      colorScheme: ColorScheme.dark(
        primary: theme.primary,
        secondary: theme.secondary,
        surface: theme.surface,
        error: const Color(0xFFFF6B6B),
      ),
      textTheme: GoogleFonts.notoSansTcTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: theme.scaffoldBg,
        elevation: 0,
        titleTextStyle: GoogleFonts.notoSansTc(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: theme.surface,
        selectedItemColor: theme.primary,
        unselectedItemColor: const Color(0xFF888888),
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: theme.surface.withValues(alpha: 0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: theme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF333355)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF333355)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primary),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await NotificationService.init();
    await ref.read(sessionProvider.notifier).init();
    await ref.read(memoryProvider.notifier).init();
    await ref.read(goalProvider.notifier).init();
    await ref.read(settingsProvider.notifier).load();
    await ref.read(themeProvider.notifier).load();

    final pinEnabled = await PinService.isPinEnabled();
    if (pinEnabled && mounted) {
      setState(() => _isLocked = true);
    }
  }

  void _onUnlock() {
    setState(() => _isLocked = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return PinLockScreen(onUnlock: _onUnlock);
    }

    final screens = [
      const ChatScreen(),
      const JournalScreen(),
      const StatsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: '吸收'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: '日記'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '統計'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }
}
