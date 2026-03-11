import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/media_screen.dart';
import 'screens/settings_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// APP THEME CONSTANTS
// Edit these to restyle the entire application from one place.
// ─────────────────────────────────────────────────────────────────────────────

/// The deepest background — used for the main content area.
const Color kAppBg = Color(0xFF0F0F0F);

/// Slightly lighter surface used for panels, cards, and sidebars.
const Color kSurface = Color(0xFF1A1A1A);

/// The border/divider colour throughout the app.
const Color kBorder = Color(0xFF2A2A2A);

/// Primary accent — scripture highlights, active nav items, focus rings.
const Color kAccentBlue = Color(0xFF4FC3F7); // soft sky-blue

/// Secondary accent — song highlights.
const Color kAccentPurple = Color(0xFFB39DDB); // soft lavender

/// Text colour for primary/body copy.
const Color kTextPrimary = Color(0xFFEEEEEE);

/// Text colour for secondary labels, hints, artists.
const Color kTextSecondary = Color(0xFF8A8A8A);

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────

void main() => runApp(const ChurchPresentationApp());

/// Root widget — sets up the global MaterialApp theme and launches [MainScreen].
class ChurchPresentationApp extends StatelessWidget {
  const ChurchPresentationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Church Presentation',
      debugShowCheckedModeBanner: false,
      // ── Global dark theme ──────────────────────────────────────────────────
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kAppBg,
        colorScheme: const ColorScheme.dark(
          surface: kSurface,
          primary: kAccentBlue,
          secondary: kAccentPurple,
        ),
        // Override the default AppBar style (we don't use AppBar, but just in case)
        appBarTheme: const AppBarTheme(
          backgroundColor: kSurface,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: kTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        // Override PopupMenu styling used in the menu bar
        popupMenuTheme: const PopupMenuThemeData(
          color: Color(0xFF222222),
          textStyle: TextStyle(color: kTextPrimary, fontSize: 13),
        ),
        // Divider theme
        dividerTheme: const DividerThemeData(color: kBorder, space: 1),
      ),
      home: const MainScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

/// MainScreen
///
/// Layout (top-to-bottom):
///   1. [_MenuBar]   – slim system-style menu bar (File / Edit / View / Help)
///   2. [_TitleBar]  – app logo + tab navigation (Home / Media / Settings)
///   3. Body         – the screen that matches the selected tab
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// 0 = Home, 1 = Media, 2 = Settings
  int _selectedTab = 0;

  // ── Screens – built once, kept alive by IndexedStack ──────────────────────
  // Using IndexedStack instead of rebuilding screens on every tab switch
  // means scroll positions and state are preserved when you switch tabs.
  static const List<Widget> _screens = [
    HomeScreen(),
    MediaScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBg,
      body: Column(
        children: [
          // Row 1: slim system-style menu bar
          const _MenuBar(),

          // Row 2: title bar with tab navigation
          _TitleBar(
            selectedTab: _selectedTab,
            onTabSelected: (i) => setState(() => _selectedTab = i),
          ),

          // Row 3: content area — uses IndexedStack so state is preserved
          Expanded(
            child: IndexedStack(index: _selectedTab, children: _screens),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MENU BAR  (File / Edit / View / Help)
// ─────────────────────────────────────────────────────────────────────────────

/// A slim bar at the very top of the window mimicking a desktop menu bar.
/// Each entry opens a [PopupMenuButton] dropdown.
class _MenuBar extends StatelessWidget {
  const _MenuBar();

  // Menu structure: label → list of items
  static const Map<String, List<String>> _menus = {
    'File': ['New', 'Open', 'Save', 'Save As', 'Exit'],
    'Edit': ['Undo', 'Redo', 'Cut', 'Copy', 'Paste'],
    'View': ['Zoom In', 'Zoom Out', 'Reset Zoom', 'Fullscreen'],
    'Help': ['About', 'Documentation', 'Keyboard Shortcuts'],
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      color: const Color(0xFF141414), // slightly darker than the title bar
      child: Row(
        children: _menus.entries
            .map((entry) => _MenuBarItem(name: entry.key, items: entry.value))
            .toList(),
      ),
    );
  }
}

/// A single dropdown entry in [_MenuBar].
class _MenuBarItem extends StatelessWidget {
  const _MenuBarItem({required this.name, required this.items});

  final String name;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name › $value'),
            duration: const Duration(seconds: 1),
            backgroundColor: const Color(0xFF2A2A2A),
          ),
        );
      },
      itemBuilder: (_) => items
          .map((item) => PopupMenuItem<String>(
                value: item,
                height: 36,
                child: Text(item, style: const TextStyle(fontSize: 13)),
              ))
          .toList(),
      // Offset places the dropdown flush below the bar
      offset: const Offset(0, 30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(
          name,
          style: const TextStyle(
            color: kTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TITLE BAR  (logo + tab navigation)
// ─────────────────────────────────────────────────────────────────────────────

/// The main navigation bar: app name on the left, tab pills in the centre,
/// and a small status indicator on the right.
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
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // ── App logo / name ──────────────────────────────────────────────
          Row(
            children: [
              // Small cross icon as a logo mark
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: kAccentBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: kAccentBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.church_rounded,
                  size: 16,
                  color: kAccentBlue,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Church Presenter',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),

          const SizedBox(width: 32),

          // ── Tab pills ────────────────────────────────────────────────────
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

          // ── Spacer pushes status to the right ────────────────────────────
          const Spacer(),

          // ── Status dot (can be wired to a "presenting" state later) ──────
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50), // green = ready
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Ready',
                style: TextStyle(fontSize: 11, color: kTextSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single tab pill in [_TitleBar].
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
                ? kAccentBlue.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? kAccentBlue.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? kAccentBlue : kTextSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? kAccentBlue : kTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}