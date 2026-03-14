// ─────────────────────────────────────────────────────────────────────────────
// MEDIA PANEL  (bottom of the preview column)
// Browse and send images, videos, and audio to the projector.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'shared_widgets.dart';

class MediaPanel extends StatefulWidget {
  const MediaPanel({super.key});
  @override
  State<MediaPanel> createState() => _MediaPanelState();
}

class _MediaPanelState extends State<MediaPanel> {
  String _tab = 'Images';
  String _search = '';
  final _searchCtrl = TextEditingController();

  static const List<Map<String, dynamic>> _kMedia = [
    {'name': 'Worship Background 1', 'type': 'image', 'ext': 'JPG', 'color': 0xFF1A3A4A},
    {'name': 'Cross Silhouette',     'type': 'image', 'ext': 'PNG', 'color': 0xFF2A1A4A},
    {'name': 'Church Interior',      'type': 'image', 'ext': 'JPG', 'color': 0xFF1A2A3A},
    {'name': 'Sunrise Mountains',    'type': 'image', 'ext': 'JPG', 'color': 0xFF3A2A1A},
    {'name': 'Dove in Flight',       'type': 'image', 'ext': 'PNG', 'color': 0xFF1A3A2A},
    {'name': 'Offering Background',  'type': 'image', 'ext': 'JPG', 'color': 0xFF3A1A2A},
    {'name': 'Dark Gradient',        'type': 'image', 'ext': 'JPG', 'color': 0xFF111111},
    {'name': 'Sermon Intro',         'type': 'video', 'ext': 'MP4', 'color': 0xFF2A1A1A},
    {'name': 'Worship Loop',         'type': 'video', 'ext': 'MP4', 'color': 0xFF1A1A3A},
    {'name': 'Amazing Grace Instrumental', 'type': 'audio', 'ext': 'MP3', 'color': 0xFF2A3A1A},
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tabs = ['Images', 'Videos', 'Audio', 'Backgrounds'];

    final filtered = _kMedia.where((m) {
      final matchesTab = _tab == 'Images'
          ? m['type'] == 'image' && m['name'] != 'Dark Gradient'
          : _tab == 'Videos'
          ? m['type'] == 'video'
          : _tab == 'Audio'
          ? m['type'] == 'audio'
          : m['type'] == 'image';
      final matchesSearch = _search.isEmpty ||
          (m['name'] as String).toLowerCase().contains(_search.toLowerCase());
      return matchesTab && matchesSearch;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.border, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: t.surfaceHigh,
              border: Border(bottom: BorderSide(color: t.border)),
            ),
            child: Row(
              children: [
                Icon(Icons.perm_media_rounded, size: 13, color: t.textMuted),
                const SizedBox(width: 6),
                Text('MEDIA',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: t.textMuted, letterSpacing: 1.2)),
                const Spacer(),
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Import media — coming soon'))),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: t.accentBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: t.accentBlue.withValues(alpha: 0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add_rounded, size: 11, color: t.accentBlue),
                      const SizedBox(width: 3),
                      Text('Import',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                              color: t.accentBlue)),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // ── Tabs + search ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.border)),
            ),
            child: Row(
              children: [
                ...tabs.map((tab) {
                  final isActive = _tab == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _tab = tab),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 130),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive
                              ? t.accentBlue.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: isActive
                                ? t.accentBlue.withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(tab,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                color: isActive ? t.accentBlue : t.textMuted)),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140, minWidth: 80),
                    child: SizedBox(
                      height: 26,
                      child: TextField(
                        controller: _searchCtrl,
                        style: TextStyle(fontSize: 11, color: t.textPrimary),
                        onChanged: (v) => setState(() => _search = v),
                        decoration: InputDecoration(
                          hintText: 'Search…',
                          hintStyle: TextStyle(fontSize: 11, color: t.textMuted),
                          prefixIcon: Icon(Icons.search_rounded, size: 14, color: t.textMuted),
                          filled: true, fillColor: t.appBg,
                          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: t.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: t.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: t.accentBlue, width: 1.5)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Grid ───────────────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image_not_supported_outlined, size: 28, color: t.textMuted),
                        const SizedBox(height: 8),
                        Text('No $_tab found',
                            style: TextStyle(fontSize: 12, color: t.textMuted)),
                        const SizedBox(height: 4),
                        Text('Tap Import to add media files',
                            style: TextStyle(fontSize: 10, color: t.textMuted)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 130,
                      mainAxisSpacing: 8, crossAxisSpacing: 8,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final item = filtered[i];
                      final isAudio = item['type'] == 'audio';
                      final isVideo = item['type'] == 'video';
                      return GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(
                              'Send "${item['name']}" to projector — coming soon'))),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(item['color'] as int),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: t.border),
                          ),
                          child: Stack(children: [
                            Center(child: Icon(
                              isAudio ? Icons.music_note_rounded
                                  : isVideo ? Icons.play_circle_outline_rounded
                                  : Icons.image_rounded,
                              size: 24,
                              color: Colors.white.withValues(alpha: 0.35),
                            )),
                            Positioned(
                              left: 0, right: 0, bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(5, 3, 5, 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(5),
                                    bottomRight: Radius.circular(5),
                                  ),
                                ),
                                child: Text(item['name'] as String,
                                    style: const TextStyle(fontSize: 9,
                                        color: Colors.white, fontWeight: FontWeight.w500),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                            Positioned(
                              top: 4, right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(item['ext'] as String,
                                    style: const TextStyle(fontSize: 8,
                                        color: Colors.white70, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
