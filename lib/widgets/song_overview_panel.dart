// ─────────────────────────────────────────────────────────────────────────────
// SONG OVERVIEW PANEL  (column 3)
// Displays sections (Verse 1, Chorus, Bridge…) for the selected song.
// Single-tap selects a section for preview; double-tap goes live.
// Houses the song editor dialog.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models.dart';
import 'shared_widgets.dart';

class SongOverviewPanel extends StatelessWidget {
  const SongOverviewPanel({
    super.key,
    required this.selectedSong,
    required this.selectedSection,
    required this.activeItem,
    required this.onSectionTap,
    required this.onSectionDoubleTap,
    required this.onPrev,
    required this.onNext,
    required this.onEditSong,
  });

  final Map<String, String>? selectedSong;
  final SongSection? selectedSection;
  final ServiceItem? activeItem;
  final void Function(SongSection) onSectionTap;
  final void Function(SongSection) onSectionDoubleTap;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final void Function(Map<String, String>? song) onEditSong;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final song = selectedSong;
    final sections = song != null
        ? parseSongSections(song['lyrics'] ?? '')
        : <SongSection>[];

    return Container(
      color: t.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: t.surfaceHigh,
              border: Border(bottom: BorderSide(color: t.border)),
            ),
            child: Row(
              children: [
                Icon(Icons.music_note_rounded, size: 13, color: t.accentPurple),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    song != null ? (song['title'] ?? 'Song Overview') : 'Song Overview',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: t.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (sections.isNotEmpty)
                  Text('${sections.length}',
                      style: TextStyle(fontSize: 10, color: t.textMuted)),
                if (song != null)
                  GestureDetector(
                    onTap: () => onEditSong(song),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(Icons.edit_rounded, size: 13, color: t.textMuted),
                    ),
                  ),
              ],
            ),
          ),

          // ── Section list ──────────────────────────────────────────────────
          Expanded(
            child: song == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.music_note_outlined, size: 36, color: t.textMuted),
                        const SizedBox(height: 10),
                        Text('Select a song\nfrom the list',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: t.textMuted, height: 1.5)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: sections.length,
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      final isSelected = selectedSection?.label == section.label &&
                          selectedSection?.text == section.text;
                      final isLive = activeItem?.type == ServiceItemType.song &&
                          activeItem?.song?['title'] == song['title'] &&
                          activeItem?.song?['_sectionLabel'] == section.label;

                      return InkWell(
                        onTap: () => onSectionTap(section),
                        onDoubleTap: () => onSectionDoubleTap(section),
                        hoverColor: t.accentPurple.withValues(alpha: 0.05),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: isLive
                                ? t.accentPurple.withValues(alpha: 0.15)
                                : isSelected
                                ? t.accentPurple.withValues(alpha: 0.08)
                                : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: isLive
                                    ? t.accentPurple
                                    : isSelected
                                    ? t.accentPurple.withValues(alpha: 0.6)
                                    : Colors.transparent,
                                width: 3,
                              ),
                              bottom: BorderSide(color: t.border, width: 0.5),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (section.hasLabel) ...[
                                      Text(section.label,
                                          style: TextStyle(
                                            fontSize: 13, fontWeight: FontWeight.w700,
                                            color: isLive || isSelected
                                                ? t.accentPurple : t.textSecondary,
                                            letterSpacing: 0.3,
                                          )),
                                      const SizedBox(height: 3),
                                    ],
                                    Text(section.text,
                                        maxLines: 2, overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13, height: 1.4,
                                          color: isLive || isSelected
                                              ? t.textPrimary : t.textSecondary,
                                        )),
                                  ],
                                ),
                              ),
                              if (isLive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: t.accentPurple,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text('LIVE',
                                      style: TextStyle(fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // ── Nav bar ────────────────────────────────────────────────────────
          OverviewNavBar(
            accent: t.accentPurple,
            onPrev: onPrev,
            onNext: onNext,
            extraButton: IconButton(
              icon: Icon(Icons.add_rounded, size: 16, color: t.accentPurple),
              tooltip: 'Add / edit song',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () => onEditSong(song),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SONG EDITOR DIALOG
// Called by both SongPanel (add new) and SongOverviewPanel (edit existing).
// Returns the updated song map or null if cancelled.
// ─────────────────────────────────────────────────────────────────────────────

Future<Map<String, String>?> showSongEditorDialog(
  BuildContext context, {
  Map<String, String>? existingSong,
}) {
  final titleCtrl  = TextEditingController(text: existingSong?['title'] ?? '');
  final artistCtrl = TextEditingController(text: existingSong?['artist'] ?? '');

  final sections = existingSong != null
      ? parseSongSections(existingSong['lyrics'] ?? '')
      : [SongSection(label: 'Verse 1', text: '')];

  final labelCtrls = sections.map((s) => TextEditingController(text: s.label)).toList();
  final textCtrls  = sections.map((s) => TextEditingController(text: s.text)).toList();

  return showDialog<Map<String, String>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlg) {
        final t = AppTheme.of(context);

        void addSection(String label) => setDlg(() {
          labelCtrls.add(TextEditingController(text: label));
          textCtrls.add(TextEditingController());
        });

        void removeSection(int i) => setDlg(() {
          labelCtrls.removeAt(i);
          textCtrls.removeAt(i);
        });

        Map<String, String> buildSong() {
          final buf = StringBuffer();
          for (int i = 0; i < labelCtrls.length; i++) {
            final lbl  = labelCtrls[i].text.trim();
            final body = textCtrls[i].text.trim();
            if (lbl.isNotEmpty) buf.writeln('[$lbl]');
            if (body.isNotEmpty) buf.write(body);
            if (i < labelCtrls.length - 1) buf.write('\n');
          }
          return {
            'title':  titleCtrl.text.trim(),
            'artist': artistCtrl.text.trim(),
            'lyrics': buf.toString(),
          };
        }

        return AlertDialog(
          backgroundColor: t.surface,
          title: Text(existingSong != null ? 'Edit Song' : 'Add Song',
              style: TextStyle(color: t.textPrimary, fontSize: 16,
                  fontWeight: FontWeight.w600)),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Expanded(flex: 3,
                        child: DlgField(ctrl: titleCtrl, label: 'Song title', t: t)),
                    const SizedBox(width: 12),
                    Expanded(flex: 2,
                        child: DlgField(ctrl: artistCtrl, label: 'Artist / Author', t: t)),
                  ]),
                  const SizedBox(height: 16),
                  for (int i = 0; i < labelCtrls.length; i++) ...[
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(width: 110,
                          child: DlgField(ctrl: labelCtrls[i], label: 'Label', t: t)),
                      const SizedBox(width: 8),
                      Expanded(child: DlgField(ctrl: textCtrls[i], label: 'Lyrics',
                          t: t, maxLines: 5)),
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline_rounded, size: 18,
                            color: t.textMuted),
                        onPressed: labelCtrls.length > 1 ? () => removeSection(i) : null,
                        tooltip: 'Remove section',
                        padding: const EdgeInsets.only(top: 8),
                      ),
                    ]),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final lbl in ['Verse', 'Chorus', 'Bridge', 'Pre-Chorus', 'Outro', 'Intro'])
                      ActionChip(
                        label: Text('+ $lbl',
                            style: TextStyle(fontSize: 11, color: t.textSecondary)),
                        backgroundColor: t.surfaceHigh,
                        side: BorderSide(color: t.border),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        onPressed: () {
                          String label = lbl;
                          if (lbl == 'Verse') {
                            final count = labelCtrls
                                .where((c) => c.text.startsWith('Verse')).length;
                            label = 'Verse ${count + 1}';
                          }
                          addSection(label);
                        },
                      ),
                    ActionChip(
                      label: Text('+ Custom',
                          style: TextStyle(fontSize: 11, color: t.textSecondary)),
                      backgroundColor: t.surfaceHigh,
                      side: BorderSide(color: t.border),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      onPressed: () => addSection(''),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: t.textMuted)),
            ),
            FilledButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, buildSong());
              },
              style: FilledButton.styleFrom(backgroundColor: t.accentPurple),
              child: Text(existingSong != null ? 'Save' : 'Add Song'),
            ),
          ],
        );
      },
    ),
  );
}
