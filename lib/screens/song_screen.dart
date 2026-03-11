import 'package:flutter/material.dart';
import '../app_theme.dart';

/// SongScreen - Songs and lyrics section
/// Uses AppTheme for full light/dark mode support.
class SongScreen extends StatefulWidget {
  const SongScreen({super.key});

  @override
  State<SongScreen> createState() => _SongScreenState();
}

class _SongScreenState extends State<SongScreen> {
  late TextEditingController _searchController;

  // Sample songs — will be replaced with database later
  final List<Map<String, String>> _sampleSongs = [
    {
      'title': 'Amazing Grace',
      'artist': 'John Newton',
      'lyrics':
          'Amazing grace, how sweet the sound\n'
          'That saved a wretch like me\n'
          'I once was lost but now am found\n'
          'Was blind but now I see',
    },
    {
      'title': 'How Great Thou Art',
      'artist': 'Carl Boberg',
      'lyrics':
          'O Lord my God, when I in awesome wonder\n'
          'Consider all the worlds thy hands have made\n'
          'I see the stars, I hear the rolling thunder\n'
          'Thy power throughout the universe displayed',
    },
    {
      'title': 'Jesus Loves Me',
      'artist': 'Traditional',
      'lyrics':
          'Jesus loves me, this I know\n'
          'For the Bible tells me so\n'
          'Little ones to Him belong\n'
          'They are weak but He is strong',
    },
  ];

  late Map<String, String> _selectedSong;
  late List<Map<String, String>> _filteredSongs;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredSongs = _sampleSongs;
    _selectedSong = _sampleSongs[0];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Row(
      children: [
        // ── LEFT: search + song list ───────────────────────────────────────────
        Container(
          width: 350,
          color: t.surface,
          child: Column(
            children: [
              // Search bar
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: t.border)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterSongs,
                  style: TextStyle(fontSize: 13, color: t.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search songs…',
                    hintStyle: TextStyle(fontSize: 12, color: t.textMuted),
                    prefixIcon: Icon(
                      Icons.music_note_rounded,
                      size: 18,
                      color: t.textMuted,
                    ),
                    filled: true,
                    fillColor: t.appBg,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: t.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: t.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: t.accentPurple,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              // Song list
              Expanded(
                child: _filteredSongs.isEmpty
                    ? Center(
                        child: Text(
                          'No songs found',
                          style: TextStyle(fontSize: 13, color: t.textMuted),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredSongs.length,
                        separatorBuilder: (_, _) =>
                            Divider(color: t.border, height: 1),
                        itemBuilder: (context, index) {
                          final song = _filteredSongs[index];
                          final isSelected = song == _selectedSong;

                          return InkWell(
                            onTap: () => _selectSong(song),
                            hoverColor: t.accentPurple.withValues(alpha: 0.06),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                vertical: 11,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? t.accentPurple.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                border: Border(
                                  left: BorderSide(
                                    color: isSelected
                                        ? t.accentPurple
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song['title'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? t.accentPurple
                                          : t.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    song['artist'] ?? 'Unknown Artist',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: t.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),

        // Divider between panels
        VerticalDivider(width: 1, color: t.border),

        // ── RIGHT: song display ────────────────────────────────────────────────
        Expanded(
          child: Container(
            color: t.appBg,
            padding: const EdgeInsets.all(36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: t.border),
                  ),
                  child: Row(
                    children: [
                      // Accent bar
                      Container(
                        width: 4,
                        height: 48,
                        decoration: BoxDecoration(
                          color: t.accentPurple,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Title + artist
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedSong['title'] ?? 'No song selected',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: t.accentPurple,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'by ${_selectedSong['artist'] ?? 'Unknown'}',
                              style: TextStyle(
                                fontSize: 13,
                                color: t.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Lyrics badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: t.accentPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: t.accentPurple.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          'LYRICS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: t.accentPurple,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Lyrics card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: t.border),
                    ),
                    child: SingleChildScrollView(
                      child: Center(
                        child: Text(
                          _selectedSong['lyrics'] ?? 'No lyrics available',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            height: 2.0,
                            color: t.textPrimary,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Footer
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 24, height: 1, color: t.border),
                      const SizedBox(width: 10),
                      Text(
                        'Church Presentation Software',
                        style: TextStyle(fontSize: 11, color: t.textMuted),
                      ),
                      const SizedBox(width: 10),
                      Container(width: 24, height: 1, color: t.border),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _filterSongs(String query) {
    setState(() {
      _filteredSongs = query.isEmpty
          ? _sampleSongs
          : _sampleSongs
                .where(
                  (s) =>
                      s['title']!.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ||
                      s['artist']!.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
    });
  }

  void _selectSong(Map<String, String> song) {
    setState(() => _selectedSong = song);
  }
}