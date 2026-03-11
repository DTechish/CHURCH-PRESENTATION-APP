import 'package:flutter/material.dart';
import '../app_theme.dart';

/// SettingsScreen
///
/// Houses all user-configurable preferences.
/// Currently contains the Light / Dark theme selector.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Container(
      color: t.appBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page heading ────────────────────────────────────────────────
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: t.textPrimary,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Configure your Church Presenter experience',
              style: TextStyle(fontSize: 13, color: t.textSecondary),
            ),

            SizedBox(height: 32),

            // ── Appearance section ──────────────────────────────────────────
            _SectionHeader(label: 'APPEARANCE'),
            SizedBox(height: 12),
            _SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SettingRow(
                    icon: Icons.palette_rounded,
                    title: 'Theme',
                    subtitle: 'Choose between Light and Dark mode',
                    trailing: _ThemeToggle(),
                  ),
                  Divider(color: t.border, height: 1),
                  SizedBox(height: 16),
                  // Visual theme previews
                  _ThemePreviewRow(),
                ],
              ),
            ),

            SizedBox(height: 24),

            // ── Presentation section (placeholder) ─────────────────────────
            _SectionHeader(label: 'PRESENTATION'),
            SizedBox(height: 12),
            _SettingsCard(
              child: Column(
                children: [
                  _SettingRow(
                    icon: Icons.text_fields_rounded,
                    title: 'Default Font Size',
                    subtitle: 'Font size used in the presentation view',
                    trailing: Text(
                      '22',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: t.accentBlue,
                      ),
                    ),
                  ),
                  Divider(color: t.border, height: 1),
                  _SettingRow(
                    icon: Icons.align_horizontal_center_rounded,
                    title: 'Text Alignment',
                    subtitle: 'Alignment for scripture and song lyrics',
                    trailing: Text(
                      'Left',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: t.accentBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // ── About section ───────────────────────────────────────────────
            _SectionHeader(label: 'ABOUT'),
            SizedBox(height: 12),
            _SettingsCard(
              child: _SettingRow(
                icon: Icons.church_rounded,
                title: 'Church Presenter',
                subtitle: 'Version 1.0.0  ·  Built with Flutter',
                trailing: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppTheme.of(context).textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME TOGGLE  —  Light / Dark pill switcher
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final notifier = ThemeNotifier.of(context);

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemePill(
            icon: Icons.light_mode_rounded,
            label: 'Light',
            isSelected: !t.isDark,
            onTap: () => notifier.setDark(false),
          ),
          _ThemePill(
            icon: Icons.dark_mode_rounded,
            label: 'Dark',
            isSelected: t.isDark,
            onTap: () => notifier.setDark(true),
          ),
        ],
      ),
    );
  }
}

class _ThemePill extends StatelessWidget {
  const _ThemePill({
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? t.accentBlue.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isSelected
                ? t.accentBlue.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? t.accentBlue : t.textMuted,
            ),
            SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? t.accentBlue : t.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME PREVIEW ROW  —  shows a mini visual of each theme
// ─────────────────────────────────────────────────────────────────────────────

class _ThemePreviewRow extends StatelessWidget {
  const _ThemePreviewRow();

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
      child: Row(
        children: [
          Expanded(
            child: _ThemePreviewCard(
              theme: AppTheme.light,
              isActive: !t.isDark,
              onTap: () => ThemeNotifier.of(context).setDark(false),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _ThemePreviewCard(
              theme: AppTheme.dark,
              isActive: t.isDark,
              onTap: () => ThemeNotifier.of(context).setDark(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.theme,
    required this.isActive,
    required this.onTap,
  });

  final AppTheme theme;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currentTheme = AppTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? currentTheme.accentBlue : currentTheme.border,
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: currentTheme.accentBlue.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mini title bar
              Container(
                height: 24,
                color: theme.surface,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.accentBlue,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    SizedBox(width: 5),
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.textMuted,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 20,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              // Mini content
              Container(
                height: 68,
                color: theme.appBg,
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.accentBlue,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.textMuted,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      width: 80,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.textMuted,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              // Label bar
              Container(
                color: theme.surface,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Row(
                  children: [
                    Text(
                      theme.isDark ? 'Dark' : 'Light',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: currentTheme.accentBlue.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: currentTheme.accentBlue,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: t.textMuted,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.border),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: t.surfaceHigh,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: t.border),
            ),
            child: Icon(icon, size: 17, color: t.textSecondary),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: t.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: t.textSecondary),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}
