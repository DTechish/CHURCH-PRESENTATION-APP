import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/media_screen.dart';
import 'screens/settings_screen.dart';
import 'app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────

void main() => runApp(const ChurchPresentationApp());

/// Root widget — wraps everything in [ThemeNotifierWidget] so every descendant
/// can call [AppTheme.of(context)] or [ThemeNotifier.of(context).toggle()].
class ChurchPresentationApp extends StatelessWidget {
  const ChurchPresentationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeNotifierWidget(child: _ThemedMaterialApp());
  }
}

/// Reads the current [AppTheme] and rebuilds [MaterialApp] whenever it changes.
class _ThemedMaterialApp extends StatelessWidget {
  const _ThemedMaterialApp();

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return MaterialApp(
      title: 'Church Presentation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: t.isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: t.appBg,
        colorScheme: ColorScheme(
          brightness: t.isDark ? Brightness.dark : Brightness.light,
          primary: t.accentBlue,
          onPrimary: t.isDark ? t.appBg : Colors.white,
          secondary: t.accentPurple,
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          surface: t.surface,
          onSurface: t.textPrimary,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: t.surface,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: t.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: t.surfaceHigh,
          textStyle: TextStyle(color: t.textPrimary, fontSize: 13),
        ),
        dividerTheme: DividerThemeData(color: t.border, space: 1),
      ),
      home: const MainScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedTab = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    MediaScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.of(context).appBg,
      body: Column(
        children: [
          const _MenuBar(),
          _TitleBar(
            selectedTab: _selectedTab,
            onTabSelected: (i) => setState(() => _selectedTab = i),
          ),
          Expanded(
            child: IndexedStack(index: _selectedTab, children: _screens),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MENU BAR
// ─────────────────────────────────────────────────────────────────────────────

class _MenuBar extends StatelessWidget {
  const _MenuBar();

  static const Map<String, List<String>> _menus = {
    'File': ['New', 'Open', 'Save', 'Save As', 'Exit'],
    'Edit': ['Undo', 'Redo', 'Cut', 'Copy', 'Paste'],
    'View': ['Zoom In', 'Zoom Out', 'Reset Zoom', 'Fullscreen'],
    'Help': ['About', 'Documentation', 'Keyboard Shortcuts'],
  };

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Container(
      height: 30,
      color: t.menuBarBg,
      child: Row(
        children: _menus.entries
            .map((entry) => _MenuBarItem(name: entry.key, items: entry.value))
            .toList(),
      ),
    );
  }
}

class _MenuBarItem extends StatelessWidget {
  const _MenuBarItem({required this.name, required this.items});

  final String name;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return PopupMenuButton<String>(
      onSelected: (value) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name › $value'),
            duration: const Duration(seconds: 1),
            backgroundColor: t.surfaceHigh,
          ),
        );
      },
      itemBuilder: (_) => items
          .map(
            (item) => PopupMenuItem<String>(
              value: item,
              height: 36,
              child: Text(item, style: TextStyle(fontSize: 13)),
            ),
          )
          .toList(),
      offset: const Offset(0, 30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(
          name,
          style: TextStyle(
            color: t.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TITLE BAR
// ─────────────────────────────────────────────────────────────────────────────

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.selectedTab, required this.onTabSelected});

  final int selectedTab;
  final ValueChanged<int> onTabSelected;

  static const _tabs = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.perm_media_rounded, label: 'Media'),
    (icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // App logo
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: t.accentBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: t.accentBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.church_rounded,
                  size: 16,
                  color: t.accentBlue,
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Church Presenter',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),

          SizedBox(width: 32),

          // Tab pills
          Row(
            children: [
              for (int i = 0; i < _tabs.length; i++)
                _TabPill(
                  icon: _tabs[i].icon,
                  label: _tabs[i].label,
                  isSelected: selectedTab == i,
                  onTap: () => onTabSelected(i),
                ),
            ],
          ),

          const Spacer(),

          // Status + theme toggle
          Row(
            children: [
              // Theme toggle icon button
              Tooltip(
                message: AppTheme.of(context).isDark
                    ? 'Switch to Light Mode'
                    : 'Switch to Dark Mode',
                child: InkWell(
                  onTap: () => ThemeNotifier.of(context).toggle(),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      AppTheme.of(context).isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      size: 16,
                      color: t.textSecondary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Ready indicator
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6),
              Text(
                'Ready',
                style: TextStyle(fontSize: 11, color: t.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? t.accentBlue.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? t.accentBlue.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? t.accentBlue : t.textSecondary,
              ),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? t.accentBlue : t.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
