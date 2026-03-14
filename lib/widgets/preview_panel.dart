// ─────────────────────────────────────────────────────────────────────────────
// PREVIEW PANEL  (centre column, top portion)
// Shows the active content: scripture verse, song section, announcement,
// logo, black screen, or the welcome/getting-started screen.
// Also renders the Black / Logo / Announce / Message action bar.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models.dart';
import 'shared_widgets.dart';

class PreviewPanel extends StatelessWidget {
  const PreviewPanel({
    super.key,
    required this.activeItem,
    required this.previewVerse,
    required this.selectedSection,
    required this.selectedSong,
    required this.onGoLive,
    required this.onClear,
    required this.onAddBlack,
    required this.onAddLogo,
    required this.onAddAnnouncement,
    required this.onAddMessage,
  });

  final ServiceItem? activeItem;
  final ScriptureQueueItem? previewVerse;
  final SongSection? selectedSection;
  final Map<String, String>? selectedSong;

  final VoidCallback onGoLive;
  final VoidCallback onClear;
  final VoidCallback onAddBlack;
  final VoidCallback onAddLogo;
  final VoidCallback onAddAnnouncement;
  final VoidCallback onAddMessage;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final item = activeItem;

    Widget preview;
    if (item == null) {
      if (previewVerse != null) {
        preview = _ScripturePreview(item: previewVerse!, onGoLive: onGoLive, onClear: onClear);
      } else if (selectedSection != null && selectedSong != null) {
        final previewSong = Map<String, String>.from(selectedSong!)
          ..['lyrics'] = selectedSection!.text
          ..['_sectionLabel'] = selectedSection!.label;
        preview = _SongPreview(song: previewSong, onGoLive: onGoLive, onClear: onClear);
      } else {
        preview = const _WelcomeScreen();
      }
    } else {
      switch (item.type) {
        case ServiceItemType.scripture:
          preview = _ScripturePreview(
            item: previewVerse ?? item.scriptureItem!,
            onGoLive: onGoLive, onClear: onClear,
          );
        case ServiceItemType.song:
          preview = _SongPreview(song: item.song!, onGoLive: onGoLive, onClear: onClear);
        case ServiceItemType.announcement:
          preview = _AnnouncementPreview(item: item, onGoLive: onGoLive, onClear: onClear);
        case ServiceItemType.logo:
          preview = _LogoPreview(onGoLive: onGoLive, onClear: onClear);
        case ServiceItemType.black:
          preview = _BlackPreview(onGoLive: onGoLive, onClear: onClear);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: preview),
        // ── Action bar ──────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: t.surfaceHigh,
            border: Border(top: BorderSide(color: t.border)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PreviewActionButton(icon: Icons.circle, label: 'Black',
                    color: const Color(0xFF777777), onTap: onAddBlack),
                const SizedBox(width: 6),
                PreviewActionButton(icon: Icons.church_rounded, label: 'Logo',
                    color: const Color(0xFF4CAF50), onTap: onAddLogo),
                const SizedBox(width: 6),
                PreviewActionButton(icon: Icons.campaign_rounded, label: 'Announce',
                    color: const Color(0xFFE6A817), onTap: onAddAnnouncement),
                const SizedBox(width: 6),
                PreviewActionButton(icon: Icons.message_rounded, label: 'Message',
                    color: const Color(0xFF42A5F5), onTap: onAddMessage),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Go Live bar (shared by all preview types) ──────────────────────────────

class _GoLiveBar extends StatelessWidget {
  const _GoLiveBar({required this.accent, required this.onGoLive, required this.onClear});
  final Color accent;
  final VoidCallback onGoLive;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: onGoLive,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: t.isDark ? t.appBg : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.cast_rounded, size: 17),
              label: const Text('Go Live',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      letterSpacing: 0.3)),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: onClear,
            style: OutlinedButton.styleFrom(
              foregroundColor: t.textSecondary,
              side: BorderSide(color: t.border),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.stop_screen_share_rounded, size: 16),
            label: const Text('Clear', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Scripture preview ──────────────────────────────────────────────────────

class _ScripturePreview extends StatelessWidget {
  const _ScripturePreview({required this.item, required this.onGoLive, required this.onClear});
  final ScriptureQueueItem item;
  final VoidCallback onGoLive;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(36, 36, 36, 28),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.accentBlue.withValues(alpha: 0.25),
                    width: t.isDark ? 1 : 1.5),
                boxShadow: t.isDark ? null : [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 14, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: RichText(
                          textAlign: TextAlign.left,
                          text: item.buildRichText(TextStyle(
                            fontSize: 38, height: 1.75, color: t.textPrimary,
                            fontWeight: FontWeight.w500, letterSpacing: 0.15,
                          )),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(height: 1, color: t.border),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: t.accentBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: t.accentBlue.withValues(alpha: 0.25)),
                        ),
                        child: Text(item.version.abbreviation,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                color: t.accentBlue, letterSpacing: 0.8)),
                      ),
                      const Spacer(),
                      Text(item.reference,
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600,
                              color: t.accentBlue, letterSpacing: 0.2)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _GoLiveBar(accent: t.accentBlue, onGoLive: onGoLive, onClear: onClear),
        ],
      ),
    );
  }
}

// ── Song preview ──────────────────────────────────────────────────────────

class _SongPreview extends StatelessWidget {
  const _SongPreview({required this.song, required this.onGoLive, required this.onClear});
  final Map<String, String> song;
  final VoidCallback onGoLive;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final sectionLabel = song['_sectionLabel'];
    final subtitle = sectionLabel != null && sectionLabel.isNotEmpty
        ? '$sectionLabel  ·  ${song['artist'] ?? ''}'
        : 'by ${song['artist'] ?? 'Unknown'}';
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PreviewHeader(
            title: song['title'] ?? '',
            subtitle: subtitle,
            accent: context.t.accentPurple,
            badgeLabel: sectionLabel != null && sectionLabel.isNotEmpty
                ? sectionLabel.toUpperCase() : 'LYRICS',
          ),
          const SizedBox(height: 20),
          Expanded(child: PreviewTextCard(
            text: song['lyrics'] ?? '', textAlign: TextAlign.center)),
          _GoLiveBar(accent: context.t.accentPurple, onGoLive: onGoLive, onClear: onClear),
        ],
      ),
    );
  }
}

// ── Announcement preview ──────────────────────────────────────────────────

class _AnnouncementPreview extends StatelessWidget {
  const _AnnouncementPreview(
      {required this.item, required this.onGoLive, required this.onClear});
  final ServiceItem item;
  final VoidCallback onGoLive;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFE6A817);
    final t = context.t;
    final lines = (item.announcementText ?? '').split('\n');
    final bodyLines   = <String>[];
    final bulletLines = <String>[];
    for (final line in lines) {
      final s = line.trim();
      if (s.startsWith('•')) {
        bulletLines.add(s.substring(1).trim());
      } else if (s.isNotEmpty) {
        bodyLines.add(s);
      }
    }
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PreviewHeader(
            title: item.announcementTitle?.isNotEmpty == true
                ? item.announcementTitle! : 'Announcement',
            subtitle: 'Weekly church announcement',
            accent: amber, badgeLabel: 'ANNOUNCE',
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: t.surface, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: t.border, width: t.isDark ? 1 : 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.campaign_rounded, color: amber, size: 16),
                    const SizedBox(width: 7),
                    Text('ANNOUNCEMENT',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                            color: amber.withValues(alpha: 0.85), letterSpacing: 1.4)),
                  ]),
                  const SizedBox(height: 16),
                  if (bodyLines.isNotEmpty) ...[
                    Text(bodyLines.join(' '),
                        style: TextStyle(fontSize: 18, height: 1.7, color: t.textPrimary,
                            fontWeight: FontWeight.w400)),
                    const SizedBox(height: 20),
                  ],
                  if (bulletLines.isNotEmpty)
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: t.surfaceHigh, borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: t.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: bulletLines.map((bp) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(width: 7, height: 7,
                                margin: const EdgeInsets.only(top: 7, right: 12),
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle, color: amber)),
                            Expanded(child: Text(bp,
                                style: TextStyle(fontSize: 15, height: 1.55,
                                    color: t.textPrimary))),
                          ]),
                        )).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          _GoLiveBar(accent: amber, onGoLive: onGoLive, onClear: onClear),
        ],
      ),
    );
  }
}

// ── Logo preview ──────────────────────────────────────────────────────────

class _LogoPreview extends StatelessWidget {
  const _LogoPreview({required this.onGoLive, required this.onClear});
  final VoidCallback onGoLive;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) {
    final t = context.t;
    const green = Color(0xFF4CAF50);
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(children: [
        PreviewHeader(title: 'Church Logo', subtitle: 'Branded slide',
            accent: green, badgeLabel: 'LOGO'),
        const SizedBox(height: 20),
        Expanded(child: Container(
          decoration: BoxDecoration(color: Colors.black,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: t.border)),
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.church_rounded, size: 64,
                color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('CHURCH LOGO', style: TextStyle(fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.2), letterSpacing: 2)),
            const SizedBox(height: 8),
            Text('Add your logo image in settings',
                style: TextStyle(fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.15))),
          ])),
        )),
        _GoLiveBar(accent: green, onGoLive: onGoLive, onClear: onClear),
      ]),
    );
  }
}

// ── Black screen preview ──────────────────────────────────────────────────

class _BlackPreview extends StatelessWidget {
  const _BlackPreview({required this.onGoLive, required this.onClear});
  final VoidCallback onGoLive;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) {
    final t = context.t;
    const grey = Color(0xFF777777);
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(children: [
        PreviewHeader(title: 'Black Screen', subtitle: 'Clear projector output',
            accent: grey, badgeLabel: 'BLACK'),
        const SizedBox(height: 20),
        Expanded(child: Container(
          decoration: BoxDecoration(color: Colors.black,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: t.border)),
        )),
        _GoLiveBar(accent: grey, onGoLive: onGoLive, onClear: onClear),
      ]),
    );
  }
}

// ── Welcome / getting started screen ──────────────────────────────────────

class _WelcomeScreen extends StatelessWidget {
  const _WelcomeScreen();
  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: t.surface, shape: BoxShape.circle,
                  border: Border.all(color: t.border),
                ),
                child: Icon(Icons.church_rounded, size: 44, color: t.textMuted),
              ),
              const SizedBox(height: 16),
              Text('Church Presentation',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                      color: t.textPrimary)),
              const SizedBox(height: 6),
              Text('Select a verse or song to begin',
                  style: TextStyle(fontSize: 13, color: t.textSecondary)),
              const SizedBox(height: 20),
              SizedBox(
                width: 360,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: t.surface, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.border),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('GETTING STARTED',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                            color: t.textMuted, letterSpacing: 1.2)),
                    const SizedBox(height: 14),
                    TipRow(icon: Icons.format_list_numbered_rounded,
                        color: t.accentBlue,
                        text: 'Pick a version from the Bible Versions list on the left'),
                    TipRow(icon: Icons.search_rounded, color: t.accentBlue,
                        text: 'Type Jn 3:16, rev12:1, ps119:65-88 or even a typo — it figures it out'),
                    TipRow(icon: Icons.table_rows_rounded, color: t.accentBlue,
                        text: 'Use the Book, Chapter, From & To dropdowns to pick any passage'),
                    TipRow(icon: Icons.touch_app_rounded, color: t.accentBlue,
                        text: 'Tap to preview · Double-tap to go live · Right-click to set range'),
                    TipRow(icon: Icons.playlist_add_rounded, color: t.accentBlue,
                        text: 'Hit Add to queue passages in service order'),
                    TipRow(icon: Icons.music_note_rounded, color: t.accentPurple,
                        text: 'Double-tap a song to display its lyrics', bottomPad: 0),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      );
    });
  }
}
