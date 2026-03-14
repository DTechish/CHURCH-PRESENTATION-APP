// ─────────────────────────────────────────────────────────────────────────────
// SONG PANEL  (left column, bottom half)
// Song list with search, single-tap to select, add to queue button.
// Also houses the song editor dialog launcher.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'shared_widgets.dart';

class SongPanel extends StatelessWidget {
  const SongPanel({
    super.key,
    required this.songs,
    required this.selectedSong,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSongSelected,
    required this.onAddToQueue,
    required this.onAddSong,
  });

  final List<Map<String, String>> songs;
  final Map<String, String>? selectedSong;
  final TextEditingController searchController;
  final void Function(String) onSearchChanged;
  final void Function(Map<String, String>) onSongSelected;
  final VoidCallback onAddToQueue;
  final VoidCallback onAddSong; // opens song editor dialog with null (new song)

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ─────────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: t.surfaceHigh,
                  border: Border(bottom: BorderSide(color: t.border)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.music_note_rounded, size: 13, color: t.accentPurple),
                    const SizedBox(width: 6),
                    Text('SONGS',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: t.textPrimary)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Tooltip(
                message: 'Add new song',
                child: GestureDetector(
                  onTap: onAddSong,
                  child: Icon(Icons.add_rounded, size: 16, color: t.accentPurple),
                ),
              ),
            ),
          ],
        ),

        // ── Search ─────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.border)),
          ),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            style: TextStyle(fontSize: 13, color: t.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search songs…',
              hintStyle: TextStyle(fontSize: 12, color: t.textMuted),
              prefixIcon: Icon(Icons.music_note_rounded, size: 17, color: t.textMuted),
              filled: true,
              fillColor: t.appBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: t.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: t.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: t.accentPurple, width: 1.5)),
            ),
          ),
        ),

        // ── Song list ──────────────────────────────────────────────────────
        Expanded(
          child: songs.isEmpty
              ? Center(child: Text('No songs found',
                  style: TextStyle(fontSize: 12, color: t.textMuted)))
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: songs.length,
                  separatorBuilder: (_, _) => Divider(color: t.border, height: 1),
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    final isSelected = selectedSong?['title'] == song['title'];
                    return InkWell(
                      onTap: () => onSongSelected(song),
                      hoverColor: t.accentPurple.withValues(alpha: 0.06),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? t.accentPurple.withValues(alpha: 0.1)
                              : Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              color: isSelected ? t.accentPurple : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(song['title'] ?? '',
                                style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500,
                                  color: isSelected ? t.accentPurple : t.textPrimary,
                                )),
                            const SizedBox(height: 2),
                            Text(song['artist'] ?? '',
                                style: TextStyle(fontSize: 11, color: t.textSecondary)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // ── Footer: add to queue ───────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: t.border)),
          ),
          child: Row(
            children: [
              Text('Double-tap to preview',
                  style: TextStyle(fontSize: 10, color: t.textMuted)),
              const Spacer(),
              GestureDetector(
                onTap: selectedSong != null ? onAddToQueue : null,
                child: AnimatedOpacity(
                  opacity: selectedSong != null ? 1.0 : 0.35,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: t.accentPurple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: t.accentPurple.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.playlist_add_rounded, size: 14, color: t.accentPurple),
                        const SizedBox(width: 5),
                        Text('Add to Queue',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                color: t.accentPurple)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
