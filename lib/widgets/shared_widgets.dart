// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// Small, stateless UI atoms reused across multiple panels.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../app_theme.dart';

extension ThemeX on BuildContext {
  AppTheme get t => AppTheme.of(this);
}

// ── Section label (e.g. "SCRIPTURE", "SONGS") ─────────────────────────────

class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.label, required this.accent});
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 13, color: accent,
              margin: const EdgeInsets.only(right: 8)),
          Text(
            label,
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: accent, letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Icon + tooltip button ──────────────────────────────────────────────────

class IconTip extends StatelessWidget {
  const IconTip({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ── Navigation arrow button (prev / next) ─────────────────────────────────

class NavBtn extends StatefulWidget {
  const NavBtn({
    super.key,
    required this.icon,
    required this.accent,
    required this.onTap,
    required this.enabled,
    this.tooltip = '',
  });
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool enabled;
  final String tooltip;

  @override
  State<NavBtn> createState() => _NavBtnState();
}

class _NavBtnState extends State<NavBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: 56, height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered && widget.enabled
                  ? widget.accent.withValues(alpha: 0.15)
                  : Colors.transparent,
            ),
            child: Icon(
              widget.icon, size: 20,
              color: widget.enabled
                  ? (_hovered ? widget.accent : t.textSecondary)
                  : t.textMuted.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared prev/next nav bar (used in verse and song overview panels) ──────

class OverviewNavBar extends StatelessWidget {
  const OverviewNavBar({
    super.key,
    required this.accent,
    required this.onPrev,
    required this.onNext,
    this.extraButton,
  });
  final Color accent;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final Widget? extraButton;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          NavBtn(
            icon: Icons.chevron_left_rounded,
            accent: accent,
            onTap: onPrev ?? () {},
            enabled: onPrev != null,
            tooltip: 'Previous',
          ),
          const Spacer(),
          ?extraButton,
          NavBtn(
            icon: Icons.chevron_right_rounded,
            accent: accent,
            onTap: onNext ?? () {},
            enabled: onNext != null,
            tooltip: 'Next',
          ),
        ],
      ),
    );
  }
}

// ── Small preview header (title + badge) ──────────────────────────────────

class PreviewHeader extends StatelessWidget {
  const PreviewHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.badgeLabel,
  });
  final String title;
  final String subtitle;
  final Color accent;
  final String badgeLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: accent, letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle,
                style: TextStyle(fontSize: 12, color: t.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Text(
            badgeLabel,
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: accent, letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Preview text card (lyrics / announcement body) ─────────────────────────

class PreviewTextCard extends StatelessWidget {
  const PreviewTextCard({
    super.key,
    this.text,
    this.richText,
    required this.textAlign,
    this.fontSize = 26,
  }) : assert(text != null || richText != null);

  final String? text;
  final TextSpan Function(TextStyle base)? richText;
  final TextAlign textAlign;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final base = TextStyle(
      fontSize: fontSize, height: 1.85, color: t.textPrimary,
      fontWeight: FontWeight.w500, letterSpacing: 0.1,
    );
    final child = richText != null
        ? RichText(text: richText!(base), textAlign: textAlign)
        : Text(text!, textAlign: textAlign, style: base);

    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.border, width: t.isDark ? 1 : 1.5),
        boxShadow: t.isDark ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: textAlign == TextAlign.center
            ? Alignment.center : Alignment.centerLeft,
        child: child,
      ),
    );
  }
}

// ── Tip row (icon + text, used in welcome screen) ─────────────────────────

class TipRow extends StatelessWidget {
  const TipRow({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
    this.bottomPad = 12,
  });
  final IconData icon;
  final Color color;
  final String text;
  final double bottomPad;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
              style: TextStyle(
                fontSize: 12, color: context.t.textSecondary, height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Plan quick-add chip button ─────────────────────────────────────────────

class PlanQuickButton extends StatelessWidget {
  const PlanQuickButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
            Text(label,
              style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w600,
                color: color, letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dialog text field ──────────────────────────────────────────────────────

class DlgField extends StatelessWidget {
  const DlgField({
    super.key,
    required this.ctrl,
    required this.label,
    required this.t,
    this.maxLines = 1,
  });
  final TextEditingController ctrl;
  final String label;
  final AppTheme t;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(fontSize: 13, color: t.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: t.textMuted),
        filled: true, fillColor: t.appBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: t.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: t.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: t.accentPurple, width: 1.5),
        ),
      ),
    );
  }
}

// ── Preview action button (Go Live / Clear, etc.) ──────────────────────────

class PreviewActionButton extends StatelessWidget {
  const PreviewActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: t.surfaceHigh,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label,
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: t.textPrimary, letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Announcement toggle chip ───────────────────────────────────────────────

class AnnToggleChip extends StatelessWidget {
  const AnnToggleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.amber,
    required this.t,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final Color amber;
  final AppTheme t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? amber : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
          style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: selected ? Colors.black : t.textSecondary,
          ),
        ),
      ),
    );
  }
}
