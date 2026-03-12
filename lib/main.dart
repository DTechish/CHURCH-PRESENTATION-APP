import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/media_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const options = WindowOptions(
    backgroundColor: Colors.black,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'Church Presenter',
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.maximize();
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ChurchPresentationApp());
}

class ChurchPresentationApp extends StatelessWidget {
  const ChurchPresentationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeNotifierWidget(
      child: Builder(
        builder: (context) => MaterialApp(
          title: 'Church Presenter',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            colorSchemeSeed: Colors.indigo,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: const MainScreen(),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedNavIndex = 0;

  static const _kBarBg     = Color(0xFF1E2533);
  static const _kBarFg     = Color(0xFFCCCCCC);
  static const _kHoverBg   = Color(0xFF2D3A4F);
  static const _kDropBg    = Color(0xFF252D3B);
  static const _kDropHover = Color(0xFF2D3A4F);
  static const _kDivider   = Color(0xFF3A4459);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Menu bar ───────────────────────────────────────────────────────────
        Material(
          color: _kBarBg,
          child: SizedBox(
            height: 28,
            child: _BarCoord(
              child: Row(
              children: [
                _DesktopMenu(
                  label: 'File',
                  barFg: _kBarFg, hoverBg: _kHoverBg,
                  dropBg: _kDropBg, dropHover: _kDropHover, divider: _kDivider,
                  items: [
                    _Item('New',     shortcut: 'Ctrl+N'),
                    _Item('Open',    shortcut: 'Ctrl+O'),
                    _Item('Save',    shortcut: 'Ctrl+S'),
                    _Item('Save As', shortcut: 'Ctrl+Shift+S'),
                    _Divider(),
                    _Item('Exit', onTap: () => windowManager.close()),
                  ],
                ),
                _DesktopMenu(
                  label: 'Edit',
                  barFg: _kBarFg, hoverBg: _kHoverBg,
                  dropBg: _kDropBg, dropHover: _kDropHover, divider: _kDivider,
                  items: [
                    _Item('Undo',  shortcut: 'Ctrl+Z'),
                    _Item('Redo',  shortcut: 'Ctrl+Y'),
                    _Divider(),
                    _Item('Cut',   shortcut: 'Ctrl+X'),
                    _Item('Copy',  shortcut: 'Ctrl+C'),
                    _Item('Paste', shortcut: 'Ctrl+V'),
                  ],
                ),
                _DesktopMenu(
                  label: 'View',
                  barFg: _kBarFg, hoverBg: _kHoverBg,
                  dropBg: _kDropBg, dropHover: _kDropHover, divider: _kDivider,
                  items: [
                    _Item('Zoom In',    shortcut: 'Ctrl++'),
                    _Item('Zoom Out',   shortcut: 'Ctrl+-'),
                    _Item('Reset Zoom', shortcut: 'Ctrl+0'),
                    _Divider(),
                    _Item('Fullscreen', shortcut: 'F11'),
                  ],
                ),
                _DesktopMenu(
                  label: 'Help',
                  barFg: _kBarFg, hoverBg: _kHoverBg,
                  dropBg: _kDropBg, dropHover: _kDropHover, divider: _kDivider,
                  items: [
                    _Item('Documentation'),
                    _Item('Keyboard Shortcuts'),
                    _Divider(),
                    _Item('About'),
                  ],
                ),
              ],
            ),
            ),
          ),
        ),

        // ── App bar + body ─────────────────────────────────────────────────────
        Expanded(
          child: Scaffold(
            appBar: AppBar(
              elevation: 4,
              title: Row(
                children: [
                  _navBtn('Home',     0),
                  _navBtn('Media',    1),
                  _navBtn('Settings', 2),
                ],
              ),
            ),
            body: _body(),
          ),
        ),
      ],
    );
  }

  Widget _navBtn(String label, int index) => Padding(
        padding: const EdgeInsets.all(8),
        child: TextButton(
          onPressed: () => setState(() => _selectedNavIndex = index),
          style: TextButton.styleFrom(
            backgroundColor: _selectedNavIndex == index
                ? Colors.cyan
                : Colors.transparent,
          ),
          child: Text(label,
              style: const TextStyle(fontSize: 16, color: Colors.white)),
        ),
      );

  Widget _body() {
    switch (_selectedNavIndex) {
      case 0:  return const HomeScreen();
      case 1:  return const MediaScreen();
      case 2:  return const SettingsScreen();
      default: return const HomeScreen();
    }
  }
}

// ── Menu entry types ──────────────────────────────────────────────────────────

abstract class _Entry {}

class _Item extends _Entry {
  _Item(this.label, {this.shortcut, this.onTap});
  final String label;
  final String? shortcut;
  final VoidCallback? onTap;
}

class _Divider extends _Entry {
  _Divider();
}

// ── Desktop menu ──────────────────────────────────────────────────────────────
// Uses MenuAnchor (Flutter 3.7+) for native-feel: no animation delay, flush
// positioning, hover-to-switch, keyboard navigation built-in.

class _DesktopMenu extends StatefulWidget {
  const _DesktopMenu({
    required this.label,
    required this.items,
    required this.barFg,
    required this.hoverBg,
    required this.dropBg,
    required this.dropHover,
    required this.divider,
  });

  final String label;
  final List<_Entry> items;
  final Color barFg, hoverBg, dropBg, dropHover, divider;

  @override
  State<_DesktopMenu> createState() => _DesktopMenuState();
}

class _DesktopMenuState extends State<_DesktopMenu> {
  final _controller = MenuController();
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isOpen = _controller.isOpen;

    return MenuAnchor(
      controller: _controller,
      // Flush with no gap — aligns exactly under the bar item
      alignmentOffset: Offset.zero,
      // Remove the default Material animation so it opens instantly
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(widget.dropBg),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(6),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 4)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        )),
        // Zero animation duration = instant open, no delay
        maximumSize: const WidgetStatePropertyAll(Size(360, 600)),
      ),
      menuChildren: [
        for (final entry in widget.items)
          if (entry is _Divider)
            Divider(height: 1, thickness: 1, color: widget.divider,
                indent: 0, endIndent: 0)
          else
            _MenuRow(
              item: entry as _Item,
              hoverColor: widget.dropHover,
              onTap: () {
                _controller.close();
                (entry).onTap?.call();
              },
            ),
      ],
      builder: (context, controller, _) {
        return MouseRegion(
          onEnter: (_) {
            setState(() => _hovered = true);
            // Hover-switch: if another menu is open, steal it
            final bar = context.findAncestorStateOfType<_BarCoordState>();
            if (bar != null && bar.hasOpen && !controller.isOpen) {
              bar.switchTo(controller);
            }
          },
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (controller.isOpen) {
                controller.close();
                context.findAncestorStateOfType<_BarCoordState>()?.clear();
              } else {
                controller.open();
                context.findAncestorStateOfType<_BarCoordState>()
                    ?.switchTo(controller);
              }
              setState(() {});
            },
            child: Container(
              height: 28,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              color: _hovered || isOpen ? widget.hoverBg : Colors.transparent,
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  color: widget.barFg,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Individual drop-down row ──────────────────────────────────────────────────

class _MenuRow extends StatefulWidget {
  const _MenuRow({
    required this.item,
    required this.hoverColor,
    required this.onTap,
  });
  final _Item item;
  final Color hoverColor;
  final VoidCallback onTap;

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          color: _hovered ? widget.hoverColor : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.item.label,
                style: const TextStyle(fontSize: 13, color: Color(0xFFDDDDDD)),
              ),
              if (widget.item.shortcut != null) ...[
                const SizedBox(width: 32),
                Text(
                  widget.item.shortcut!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.33),
                  ),
                ),
              ],
              // Minimum width so narrow labels still have room for shortcuts
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bar coordinator ───────────────────────────────────────────────────────────
// Invisible widget that sits above the menu buttons so they can coordinate
// hover-switching (close the previously open menu, open the hovered one).

class _BarCoord extends StatefulWidget {
  const _BarCoord({required this.child});
  final Widget child;
  @override
  _BarCoordState createState() => _BarCoordState();
}

class _BarCoordState extends State<_BarCoord> {
  MenuController? _open;

  bool get hasOpen => _open != null && _open!.isOpen;

  void switchTo(MenuController next) {
    if (_open != null && _open != next && _open!.isOpen) {
      _open!.close();
    }
    setState(() => _open = next);
  }

  void clear() => setState(() => _open = null);

  @override
  Widget build(BuildContext context) => widget.child;
}