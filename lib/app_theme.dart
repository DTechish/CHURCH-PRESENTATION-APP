import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// APP THEME  —  single source of truth for every colour in the app.
//
// Usage anywhere in the tree:
//   final t = AppTheme.of(context);
//   Container(color: t.surface)
//
// To toggle the theme:
//   ThemeNotifier.of(context).toggle();
// ─────────────────────────────────────────────────────────────────────────────

/// Immutable snapshot of one theme's colours.
///
/// Add new semantic colour slots here and they will automatically be available
/// to every widget that calls [AppTheme.of].
class AppTheme {
  const AppTheme._({
    required this.isDark,
    required this.appBg,
    required this.surface,
    required this.surfaceHigh,
    required this.border,
    required this.accentBlue,
    required this.accentPurple,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.rangeHighlight,
    required this.anchorHighlight,
    required this.menuBarBg,
  });

  final bool isDark;

  // ── Backgrounds ────────────────────────────────────────────────────────────
  final Color appBg;
  final Color surface;
  final Color surfaceHigh;
  final Color menuBarBg;

  // ── Borders ────────────────────────────────────────────────────────────────
  final Color border;

  // ── Accents (unchanged between themes) ────────────────────────────────────
  final Color accentBlue;
  final Color accentPurple;

  // ── Text ───────────────────────────────────────────────────────────────────
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // ── Verse-range highlights ─────────────────────────────────────────────────
  final Color rangeHighlight;
  final Color anchorHighlight;

  // ── Named constructors ────────────────────────────────────────────────────

  /// The original dark theme.
  static const AppTheme dark = AppTheme._(
    isDark: true,
    appBg: Color(0xFF0F0F0F),
    surface: Color(0xFF1A1A1A),
    surfaceHigh: Color(0xFF222222),
    menuBarBg: Color(0xFF141414),
    border: Color(0xFF2A2A2A),
    accentBlue: Color(0xFF4FC3F7),
    accentPurple: Color(0xFFB39DDB),
    textPrimary: Color(0xFFEEEEEE),
    textSecondary: Color(0xFF8A8A8A),
    textMuted: Color(0xFF555555),
    rangeHighlight: Color(0xFF1A3A4A),
    anchorHighlight: Color(0xFF0D2D3A),
  );

  /// The light theme — tuned for maximum readability and clear structure.
  static const AppTheme light = AppTheme._(
    isDark: false,
    // Backgrounds: clear layering so panels have visible depth
    appBg:           Color(0xFFD8DCE6), // mid-grey page — panels pop off it
    surface:         Color(0xFFF4F6FA), // off-white panel faces
    surfaceHigh:     Color(0xFFE4E8F0), // inset areas / headers / section bars
    menuBarBg:       Color(0xFF1E2533), // dark nav bar — same as dark theme
    // Borders: strong enough to see on light backgrounds
    border:          Color(0xFF9AA3B8), // clearly visible dividers
    // Accents
    accentBlue:      Color(0xFF1A5FB4), // deep blue — WCAG AA on all surfaces
    accentPurple:    Color(0xFF6B3FA0), // deep purple — WCAG AA on all surfaces
    // Text: all weights heavy enough to read at a glance
    textPrimary:     Color(0xFF0D1117), // near-black — max contrast
    textSecondary:   Color(0xFF1E2A3D), // dark navy — clearly readable labels
    textMuted:       Color(0xFF4A5568), // slate — hints, counts, secondary info
    // Highlights
    rangeHighlight:  Color(0xFFB8D4F0), // blue wash for selected range
    anchorHighlight: Color(0xFF7AAEE8), // stronger blue for anchor verse
  );

  // ── InheritedWidget plumbing ───────────────────────────────────────────────

  /// Retrieve the current [AppTheme] from the nearest [_AppThemeScope].
  static AppTheme of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_AppThemeScope>();
    assert(scope != null, 'No AppTheme found in widget tree. '
        'Wrap your app with ThemeNotifier.');
    return scope!.theme;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME NOTIFIER  —  holds and toggles the active theme
// ─────────────────────────────────────────────────────────────────────────────

/// A [ChangeNotifier] that owns the current [AppTheme] and exposes [toggle].
///
/// Wrap your root widget with [ThemeNotifierWidget] and call
/// [ThemeNotifier.of(context).toggle()] from anywhere in the tree.
class ThemeNotifier extends ChangeNotifier {
  ThemeNotifier({bool startDark = true})
      : _theme = startDark ? AppTheme.dark : AppTheme.light;

  AppTheme _theme;

  AppTheme get theme => _theme;
  bool get isDark => _theme.isDark;

  void toggle() {
    _theme = _theme.isDark ? AppTheme.light : AppTheme.dark;
    notifyListeners();
  }

  void setDark(bool dark) {
    if (dark == _theme.isDark) return;
    toggle();
  }

  /// Retrieve the nearest [ThemeNotifier] from the widget tree.
  static ThemeNotifier of(BuildContext context) {
    final result =
        context.findAncestorStateOfType<_ThemeNotifierWidgetState>();
    assert(result != null, 'No ThemeNotifierWidget found in widget tree.');
    return result!._notifier;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME NOTIFIER WIDGET  —  place at the top of the tree
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps [child] with both the [ThemeNotifier] and the [_AppThemeScope].
///
/// ```dart
/// ThemeNotifierWidget(
///   child: MaterialApp(home: MainScreen()),
/// )
/// ```
class ThemeNotifierWidget extends StatefulWidget {
  const ThemeNotifierWidget({super.key, required this.child});

  final Widget child;

  @override
  State<ThemeNotifierWidget> createState() => _ThemeNotifierWidgetState();
}

class _ThemeNotifierWidgetState extends State<ThemeNotifierWidget> {
  final ThemeNotifier _notifier = ThemeNotifier(startDark: true);

  @override
  void initState() {
    super.initState();
    _notifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _notifier.removeListener(_onThemeChanged);
    _notifier.dispose();
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return _AppThemeScope(
      theme: _notifier.theme,
      child: widget.child,
    );
  }
}

// ── Internal InheritedWidget ──────────────────────────────────────────────────

class _AppThemeScope extends InheritedWidget {
  const _AppThemeScope({required this.theme, required super.child});

  final AppTheme theme;

  @override
  bool updateShouldNotify(_AppThemeScope old) => theme != old.theme;
}