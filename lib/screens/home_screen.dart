import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;
import 'dart:io';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COLOURS  (keep in sync with main.dart)
// ─────────────────────────────────────────────────────────────────────────────

const Color kAppBg = Color(0xFF0F0F0F);
const Color kSurface = Color(0xFF1A1A1A);
const Color kSurfaceHigh = Color(0xFF222222);
const Color kBorder = Color(0xFF2A2A2A);
const Color kAccentBlue = Color(0xFF4FC3F7);
const Color kAccentPurple = Color(0xFFB39DDB);
const Color kTextPrimary = Color(0xFFEEEEEE);
const Color kTextSecondary = Color(0xFF8A8A8A);
const Color kTextMuted = Color(0xFF555555);
const Color kRangeHighlight = Color(0xFF1A3A4A);
const Color kAnchorHighlight = Color(0xFF0D2D3A);

const double kPanelWidth = 340.0;

// ─────────────────────────────────────────────────────────────────────────────
// BIBLE VERSIONS
//
// To add a new version:
//   1. Drop the .SQLite3 file into  assets/database/
//   2. Register it in pubspec.yaml under flutter › assets
//   3. Add one line below — that's it.
//
// The [fileName] must match the asset path exactly (case-sensitive).
// The [abbreviation] is shown as the badge in the preview panel.
// The [fullName] is shown in the version selector tooltip / UI.
// ─────────────────────────────────────────────────────────────────────────────

class BibleVersion {
  const BibleVersion({
    required this.abbreviation,
    required this.fullName,
    required this.fileName,
  });

  /// Short label shown on buttons and preview badges — e.g. "AMP", "KJV".
  final String abbreviation;

  /// Full human-readable name — e.g. "Amplified Bible".
  final String fullName;

  /// Asset filename inside  assets/database/ — e.g. "AMP.SQLite3".
  final String fileName;

  /// Full Flutter asset path used with [rootBundle.load].
  String get assetPath => 'assets/database/$fileName';
}

/// ── ADD NEW VERSIONS HERE ───────────────────────────────────────────────────
///
/// Order determines the display order in the selector.
const List<BibleVersion> kBibleVersions = [
  BibleVersion(
    abbreviation: 'AMP',
    fullName: 'Amplified Bible',
    fileName: 'AMP.SQLite3',
  ),
  BibleVersion(
    abbreviation: 'ESV',
    fullName: 'English Standard Version',
    fileName: 'ESVGSB.SQLite3',
  ),
  BibleVersion(
    abbreviation: 'NASB',
    fullName: 'New American Standard Bible',
    fileName: 'NASU.SQLite3',
  ),
  // ↓ Uncomment (or add) as you drop new .SQLite3 files into assets/database/
  // BibleVersion(
  //   abbreviation: 'KJV',
  //   fullName: 'King James Version',
  //   fileName: 'KJV.SQLite3',
  // ),
  // BibleVersion(
  //   abbreviation: 'NIV',
  //   fullName: 'New International Version',
  //   fileName: 'NIV.SQLite3',
  // ),
  // BibleVersion(
  //   abbreviation: 'NKJV',
  //   fullName: 'New King James Version',
  //   fileName: 'NKJV.SQLite3',
  // ),
  // BibleVersion(
  //   abbreviation: 'NLT',
  //   fullName: 'New Living Translation',
  //   fileName: 'NLT.SQLite3',
  // ),
];

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

/// One item in the scripture queue.
/// Stores everything needed to display it in the preview panel,
/// including which Bible version it came from.
class ScriptureQueueItem {
  ScriptureQueueItem({
    required this.book,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    required this.verses,
    required this.version,
  });

  final String book;
  final int chapter;
  final int startVerse;
  final int endVerse;

  /// Raw verse rows from the DB: [{verse: int, text: String}, ...]
  final List<Map<String, dynamic>> verses;

  /// The Bible version this passage was taken from.
  final BibleVersion version;

  /// e.g. "John 3:16" or "John 3:16–18"
  String get reference => startVerse == endVerse
      ? '$book $chapter:$startVerse'
      : '$book $chapter:$startVerse–$endVerse';

  /// All verse texts joined, with verse numbers as inline labels.
  String get fullText =>
      verses.map((v) => '${v['verse']}  ${v['text']}').join('\n\n');
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME SCREEN
// ─────────────────────────────────────────────────────────────────────────────

/// HomeScreen
///
/// Layout:
///   LEFT  (340 px fixed)
///     ├── Scripture panel
///     │     ├── Section label
///     │     ├── Version selector  ← NEW
///     │     ├── Search bar
///     │     ├── Book + Chapter dropdowns
///     │     ├── Verse range picker
///     │     ├── Add-to-queue bar  (appears when a range is selected)
///     │     └── Queue strip       (appears when queue is non-empty)
///     └── Song panel
///   RIGHT (flex) — live preview
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Controllers ────────────────────────────────────────────────────────────

  late TextEditingController _searchController;
  late TextEditingController _songSearchController;

  // ── Bible version ──────────────────────────────────────────────────────────

  /// The version currently loaded in memory.
  BibleVersion _activeVersion = kBibleVersions.first;

  /// True while a version switch is in progress (shows inline spinner).
  bool _versionLoading = false;

  // ── Database ───────────────────────────────────────────────────────────────

  /// The open SQLite connection. Replaced each time the version changes.
  Database? _database;

  /// False only during the very first load (shows full-screen spinner).
  bool _initialLoadDone = false;

  // ── Bible navigation ───────────────────────────────────────────────────────

  List<String> _bibleBooks = [];
  final Map<String, int> _bookNumberMap = {};

  String? _selectedBook;
  List<int> _chapters = [];

  int? _selectedChapter;
  List<Map<String, dynamic>> _verseList = [];

  // ── Verse range selection ──────────────────────────────────────────────────

  int? _rangeStart;
  int? _rangeEnd;

  // ── Scripture queue ────────────────────────────────────────────────────────

  final List<ScriptureQueueItem> _queue = [];
  ScriptureQueueItem? _activeQueueItem;

  // ── Songs ──────────────────────────────────────────────────────────────────

  final List<Map<String, String>> _songs = [
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

  late List<Map<String, String>> _filteredSongs;
  Map<String, String>? _activeSong;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _songSearchController = TextEditingController();
    _filteredSongs = _songs;
    // Load the first version on startup
    _loadVersion(kBibleVersions.first, isInitialLoad: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _songSearchController.dispose();
    _database?.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // Full-screen spinner only on the very first app launch
    if (!_initialLoadDone) return _buildFullScreenLoader();

    return Row(
      children: [
        // ── Left panel ───────────────────────────────────────────────────────
        SizedBox(
          width: kPanelWidth,
          child: Container(
            color: kSurface,
            child: Column(
              children: [
                Expanded(child: _buildScripturePanel()),
                const Divider(color: kBorder, height: 1, thickness: 1),
                Expanded(child: _buildSongPanel()),
              ],
            ),
          ),
        ),

        const VerticalDivider(width: 1, color: kBorder),

        // ── Right panel ──────────────────────────────────────────────────────
        Expanded(
          child: Container(color: kAppBg, child: _buildPreviewSection()),
        ),
      ],
    );
  }

  Widget _buildFullScreenLoader() {
    return Container(
      color: kAppBg,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: kAccentBlue,
                strokeWidth: 2.5,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Loading Bible…',
              style: TextStyle(fontSize: 14, color: kTextSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEFT PANEL — SCRIPTURE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildScripturePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section header label
        _SectionLabel(label: 'SCRIPTURE', accent: kAccentBlue),

        // ── Zone 1: Version selector ────────────────────────────────────────
        _buildVersionSelector(),

        // ── Zone 2: Search bar ──────────────────────────────────────────────
        _buildSearchBar(),

        // ── Zone 3: Book + Chapter dropdowns ────────────────────────────────
        _buildBookChapterRow(),

        // ── Zone 4: Verse range picker ───────────────────────────────────────
        Expanded(child: _buildVerseRangePicker()),

        // ── Zone 5: Add-to-queue bar (only when a range is selected) ─────────
        if (_rangeStart != null) _buildAddToQueueBar(),

        // ── Zone 6: Queue strip (only when queue is non-empty) ───────────────
        if (_queue.isNotEmpty) _buildQueueStrip(),
      ],
    );
  }

  // ── Zone 1: Version selector ───────────────────────────────────────────────

  /// A horizontal strip of tappable version pills.
  ///
  /// The active version is highlighted in blue.
  /// If [_versionLoading] is true, a small inline spinner replaces the
  /// active pill's text so the user gets immediate feedback during the switch.
  Widget _buildVersionSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: kAppBg,
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          // "VERSION" label
          const Text(
            'VERSION',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: kTextMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 10),

          // Scrollable row of version pills
          // (Wrapped in Expanded + SingleChildScrollView so many versions
          //  don't overflow the panel width)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: kBibleVersions.map((version) {
                  final bool isActive = version == _activeVersion;
                  return _VersionPill(
                    version: version,
                    isActive: isActive,
                    // Show spinner inside the active pill while switching
                    isLoading: isActive && _versionLoading,
                    onTap: () => _switchVersion(version),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Zone 2: Search bar ─────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: _parseAndJumpToReference,
        style: const TextStyle(fontSize: 13, color: kTextPrimary),
        decoration: InputDecoration(
          hintText: 'Jump to… e.g. John 3:16  or  John 3:16-18',
          hintStyle: const TextStyle(fontSize: 12, color: kTextMuted),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 17,
            color: kTextMuted,
          ),
          suffixIcon: IconButton(
            icon: const Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: kAccentBlue,
            ),
            tooltip: 'Go',
            splashRadius: 16,
            onPressed: () => _parseAndJumpToReference(_searchController.text),
          ),
          filled: true,
          fillColor: kAppBg,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kAccentBlue, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Zone 3: Book + Chapter dropdowns ──────────────────────────────────────

  Widget _buildBookChapterRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: _StyledDropdown<String>(
              hint: 'Book',
              value: _selectedBook,
              items: _bibleBooks,
              labelBuilder: (b) => b,
              onChanged: _versionLoading ? null : _selectBook,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: _StyledDropdown<int>(
              hint: 'Ch.',
              value: _selectedChapter,
              items: _chapters,
              labelBuilder: (c) => 'Ch. $c',
              onChanged: (_selectedBook == null || _versionLoading)
                  ? null
                  : _selectChapter,
            ),
          ),
        ],
      ),
    );
  }

  // ── Zone 4: Verse range picker ─────────────────────────────────────────────

  Widget _buildVerseRangePicker() {
    // While switching versions, dim the picker area
    if (_versionLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: kAccentBlue,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading ${_activeVersion.fullName}…',
              style: const TextStyle(fontSize: 12, color: kTextSecondary),
            ),
          ],
        ),
      );
    }

    if (_verseList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, size: 32, color: kTextMuted),
            const SizedBox(height: 10),
            Text(
              _selectedBook == null
                  ? 'Select a book to begin'
                  : 'Select a chapter',
              style: const TextStyle(fontSize: 12, color: kTextMuted),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRangeInstructionStrip(),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: _verseList.length,
            itemBuilder: (context, index) {
              final verseNum = _verseList[index]['verse'] as int;
              return _buildVerseRow(verseNum);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRangeInstructionStrip() {
    final String hint;
    if (_rangeStart == null) {
      hint = 'Tap a verse to start your selection';
    } else if (_rangeEnd == null) {
      hint = 'Tap another verse to set the end  ·  tap same for just one';
    } else {
      hint = 'Range: $_selectedBook $_selectedChapter:$_rangeStart–$_rangeEnd';
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      color: kAppBg,
      child: Text(
        hint,
        style: const TextStyle(fontSize: 10, color: kTextSecondary),
      ),
    );
  }

  Widget _buildVerseRow(int verseNum) {
    final bool isStart = verseNum == _rangeStart;
    final bool isEnd = verseNum == _rangeEnd;
    final bool isAnchor = isStart || isEnd;
    final bool inRange =
        _rangeStart != null &&
        _rangeEnd != null &&
        verseNum >= _rangeStart! &&
        verseNum <= _rangeEnd!;
    final bool isSingleStart = isStart && _rangeEnd == null;

    final Color bgColor = isAnchor
        ? kAnchorHighlight
        : inRange
        ? kRangeHighlight
        : isSingleStart
        ? kAnchorHighlight
        : Colors.transparent;

    return InkWell(
      onTap: () => _onVerseTap(verseNum),
      hoverColor: kAccentBlue.withValues(alpha: 0.05),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          border: isAnchor
              ? const Border(left: BorderSide(color: kAccentBlue, width: 3))
              : const Border(
                  left: BorderSide(color: Colors.transparent, width: 3),
                ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '$verseNum',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isAnchor || isSingleStart
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: isAnchor || isSingleStart ? kAccentBlue : kTextMuted,
                ),
              ),
            ),
            Expanded(
              child: Text(
                _getVerseText(verseNum),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: inRange || isAnchor || isSingleStart
                      ? kTextPrimary
                      : kTextSecondary,
                ),
              ),
            ),
            if (isStart && _rangeEnd != null)
              _RangeBadge(label: 'START', color: kAccentBlue),
            if (isEnd) _RangeBadge(label: 'END', color: kAccentBlue),
            if (isSingleStart) _RangeBadge(label: 'FROM', color: kAccentBlue),
          ],
        ),
      ),
    );
  }

  // ── Zone 5: Add-to-queue bar ───────────────────────────────────────────────

  Widget _buildAddToQueueBar() {
    final String ref = _rangeEnd != null && _rangeEnd != _rangeStart
        ? '$_selectedBook $_selectedChapter:$_rangeStart–$_rangeEnd'
        : '$_selectedBook $_selectedChapter:$_rangeStart';

    final int verseCount = _rangeEnd != null
        ? _rangeEnd! - _rangeStart! + 1
        : 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: kSurfaceHigh,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kAccentBlue,
                  ),
                ),
                Text(
                  '$verseCount verse${verseCount == 1 ? '' : 's'}  ·  ${_activeVersion.abbreviation}',
                  style: const TextStyle(fontSize: 10, color: kTextSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: kTextMuted),
            tooltip: 'Clear selection',
            splashRadius: 16,
            onPressed: _clearSelection,
          ),
          const SizedBox(width: 4),
          FilledButton.icon(
            onPressed: _addSelectionToQueue,
            style: FilledButton.styleFrom(
              backgroundColor: kAccentBlue,
              foregroundColor: kAppBg,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 15),
            label: const Text(
              'Add',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── Zone 6: Queue strip ────────────────────────────────────────────────────

  Widget _buildQueueStrip() {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: kAppBg,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 5, 12, 0),
            child: Text(
              'QUEUE  ·  ${_queue.length} item${_queue.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: kTextMuted,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: _queue.length,
              itemBuilder: (context, index) {
                final item = _queue[index];
                return _QueueCard(
                  item: item,
                  isActive: item == _activeQueueItem,
                  onTap: () => _previewQueueItem(item),
                  onRemove: () => _removeFromQueue(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEFT PANEL — SONGS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSongPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel(label: 'SONGS', accent: kAccentPurple),

        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: kBorder)),
          ),
          child: TextField(
            controller: _songSearchController,
            onChanged: _filterSongs,
            style: const TextStyle(fontSize: 13, color: kTextPrimary),
            decoration: InputDecoration(
              hintText: 'Search songs…',
              hintStyle: const TextStyle(fontSize: 12, color: kTextMuted),
              prefixIcon: const Icon(
                Icons.music_note_rounded,
                size: 17,
                color: kTextMuted,
              ),
              filled: true,
              fillColor: kAppBg,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kAccentPurple, width: 1.5),
              ),
            ),
          ),
        ),

        Expanded(
          child: _filteredSongs.isEmpty
              ? const Center(
                  child: Text(
                    'No songs found',
                    style: TextStyle(fontSize: 12, color: kTextMuted),
                  ),
                )
              : ListView.separated(
                  itemCount: _filteredSongs.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: kBorder, height: 1),
                  itemBuilder: (context, index) {
                    final song = _filteredSongs[index];
                    final isActive = _activeSong == song;
                    return InkWell(
                      onDoubleTap: () => setState(() => _activeSong = song),
                      hoverColor: kAccentPurple.withValues(alpha: 0.06),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? kAccentPurple.withValues(alpha: 0.1)
                              : Colors.transparent,
                          border: isActive
                              ? const Border(
                                  left: BorderSide(
                                    color: kAccentPurple,
                                    width: 3,
                                  ),
                                )
                              : const Border(
                                  left: BorderSide(
                                    color: Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song['title'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isActive ? kAccentPurple : kTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              song['artist'] ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: kTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: kBorder)),
          ),
          child: const Text(
            'Double-tap a song to preview',
            style: TextStyle(fontSize: 10, color: kTextMuted),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RIGHT PANEL — PREVIEW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPreviewSection() {
    if (_activeQueueItem != null)
      return _buildScripturePreview(_activeQueueItem!);
    if (_activeSong != null) return _buildSongPreview(_activeSong!);
    return _buildWelcomeScreen();
  }

  Widget _buildScripturePreview(ScriptureQueueItem item) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewHeader(
            title: item.reference,
            // Show full version name in the subtitle
            subtitle: item.version.fullName,
            accent: kAccentBlue,
            // Show abbreviation in the badge
            badgeLabel: item.version.abbreviation,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _PreviewTextCard(
              text: item.fullText,
              textAlign: TextAlign.left,
              fontSize: 22,
            ),
          ),
          _buildPreviewFooter(),
        ],
      ),
    );
  }

  Widget _buildSongPreview(Map<String, String> song) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewHeader(
            title: song['title'] ?? '',
            subtitle: 'by ${song['artist'] ?? 'Unknown'}',
            accent: kAccentPurple,
            badgeLabel: 'LYRICS',
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _PreviewTextCard(
              text: song['lyrics'] ?? '',
              textAlign: TextAlign.center,
              fontSize: 21,
            ),
          ),
          _buildPreviewFooter(),
        ],
      ),
    );
  }

  Widget _buildPreviewFooter() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 24, height: 1, color: kBorder),
          const SizedBox(width: 10),
          const Text(
            'Church Presentation Software',
            style: TextStyle(fontSize: 11, color: kTextMuted),
          ),
          const SizedBox(width: 10),
          Container(width: 24, height: 1, color: kBorder),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kSurface,
              shape: BoxShape.circle,
              border: Border.all(color: kBorder),
            ),
            child: const Icon(
              Icons.church_rounded,
              size: 52,
              color: kTextMuted,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Church Presentation',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a verse or song to begin',
            style: TextStyle(fontSize: 14, color: kTextSecondary),
          ),
          const SizedBox(height: 36),
          Container(
            width: 380,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GETTING STARTED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: kTextMuted,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                _TipRow(
                  icon: Icons.layers_rounded,
                  color: kAccentBlue,
                  text: 'Tap a version pill to switch translations instantly',
                ),
                _TipRow(
                  icon: Icons.search_rounded,
                  color: kAccentBlue,
                  text:
                      'Type "John 3:16" or "John 3:16-18" to jump straight there',
                ),
                _TipRow(
                  icon: Icons.touch_app_rounded,
                  color: kAccentBlue,
                  text:
                      'Tap a start verse, then an end verse to select a range',
                ),
                _TipRow(
                  icon: Icons.playlist_add_rounded,
                  color: kAccentBlue,
                  text: 'Hit Add to build your service queue in order',
                ),
                _TipRow(
                  icon: Icons.music_note_rounded,
                  color: kAccentPurple,
                  text: 'Double-tap a song to display its lyrics',
                  bottomPad: 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATABASE  &  VERSION SWITCHING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Loads a Bible version from assets into a temp file and opens it.
  ///
  /// On a version switch (not the initial load) we keep the current book,
  /// chapter, and verse-range selection alive and simply re-query the verse
  /// text from the new database — so the user never loses their place.
  ///
  /// [isInitialLoad] — true only on first app launch; shows the full-screen
  /// spinner instead of the inline pill spinner.
  Future<void> _loadVersion(
    BibleVersion version, {
    bool isInitialLoad = false,
  }) async {
    setState(() {
      if (!isInitialLoad) _versionLoading = true;
    });

    try {
      // Step 1 — Read the .SQLite3 file from the Flutter asset bundle
      final data = await rootBundle.load(version.assetPath);
      final bytes = data.buffer.asUint8List();

      // Step 2 — Each version gets its own temp file so they never collide
      final safeFileName = version.fileName.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );
      final tempFile = File('${Directory.systemTemp.path}/$safeFileName');
      await tempFile.writeAsBytes(bytes);

      // Step 3 — Close the old connection, then open the new one
      _database?.dispose();
      final db = sqlite3.open(tempFile.path);

      // Step 4 — Load the book list  (schema: books(book_number, long_name))
      final bookRows = db.select(
        'SELECT book_number, long_name FROM books ORDER BY book_number',
      );
      final List<String> books = bookRows
          .map((r) => r['long_name'] as String)
          .toList();
      final Map<String, int> bookMap = {
        for (final r in bookRows)
          r['long_name'] as String: r['book_number'] as int,
      };

      // Step 5 — If a chapter was already selected, re-query its verses from
      //          the new DB so the verse list shows the new translation text.
      //          We snapshot the current selections before setState so we can
      //          use them inside the callback safely.
      final String? currentBook = _selectedBook;
      final int? currentChapter = _selectedChapter;
      List<Map<String, dynamic>> newVerseList = [];

      if (currentBook != null && currentChapter != null) {
        final bookNumber = bookMap[currentBook];
        if (bookNumber != null) {
          try {
            final verseRows = db.select(
              'SELECT verse, text FROM verses '
              'WHERE book_number = ? AND chapter = ? ORDER BY verse',
              [bookNumber, currentChapter],
            );
            newVerseList = verseRows
                .map((r) => {'verse': r['verse'], 'text': r['text']})
                .toList();
          } catch (e) {
            debugPrint('❌ Re-query verses on switch: $e');
          }
        }
      }

      setState(() {
        _database = db;
        _activeVersion = version;
        _bibleBooks = books;
        _bookNumberMap
          ..clear()
          ..addAll(bookMap);

        // ── Preserve everything the user had selected ──────────────────────
        // _selectedBook, _selectedChapter, _chapters, _rangeStart, _rangeEnd
        // all stay exactly as they were.  Only the verse *text* is refreshed
        // because it comes from the new translation.
        _verseList = newVerseList;

        _versionLoading = false;
        _initialLoadDone = true;
      });
    } catch (e) {
      debugPrint('❌ Failed to load version ${version.abbreviation}: $e');
      setState(() {
        _versionLoading = false;
        _initialLoadDone = true;
      });
    }
  }

  /// Called when the user taps a version pill.
  ///
  /// Does nothing if the selected version is already active or if a
  /// version switch is already in progress.
  void _switchVersion(BibleVersion version) {
    if (version == _activeVersion || _versionLoading) return;
    _loadVersion(version);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════════

  void _selectBook(String? book) {
    if (book == null || _database == null) return;
    final bookNumber = _bookNumberMap[book];
    if (bookNumber == null) return;
    try {
      final rows = _database!.select(
        'SELECT DISTINCT chapter FROM verses WHERE book_number = ? ORDER BY chapter',
        [bookNumber],
      );
      setState(() {
        _selectedBook = book;
        _chapters = rows.map((r) => r['chapter'] as int).toList();
        _selectedChapter = null;
        _verseList = [];
        _rangeStart = null;
        _rangeEnd = null;
      });
    } catch (e) {
      debugPrint('❌ Chapters error: $e');
    }
  }

  void _selectChapter(int? chapter) {
    if (chapter == null || _selectedBook == null || _database == null) return;
    final bookNumber = _bookNumberMap[_selectedBook!];
    if (bookNumber == null) return;
    try {
      final rows = _database!.select(
        'SELECT verse, text FROM verses WHERE book_number = ? AND chapter = ? ORDER BY verse',
        [bookNumber, chapter],
      );
      setState(() {
        _selectedChapter = chapter;
        _verseList = rows
            .map((r) => {'verse': r['verse'], 'text': r['text']})
            .toList();
        _rangeStart = null;
        _rangeEnd = null;
      });
    } catch (e) {
      debugPrint('❌ Verses error: $e');
    }
  }

  // ── Verse range selection ──────────────────────────────────────────────────

  /// State machine for verse tapping.
  ///
  ///   No selection → tap A        → A = start (awaiting end)
  ///   Start set    → tap A again  → single-verse confirmed
  ///   Start set    → tap B (B>A)  → range A–B confirmed
  ///   Start set    → tap B (B<A)  → reset, B = new start
  ///   Range done   → tap any      → start over from tapped verse
  void _onVerseTap(int verseNum) {
    setState(() {
      if (_rangeStart == null) {
        _rangeStart = verseNum;
        _rangeEnd = null;
      } else if (_rangeEnd == null) {
        if (verseNum == _rangeStart) {
          _rangeEnd = verseNum; // single verse
        } else if (verseNum > _rangeStart!) {
          _rangeEnd = verseNum; // valid end
        } else {
          _rangeStart = verseNum; // reset
          _rangeEnd = null;
        }
      } else {
        _rangeStart = verseNum; // start fresh
        _rangeEnd = null;
      }
    });
  }

  // ── Queue ──────────────────────────────────────────────────────────────────

  void _addSelectionToQueue() {
    if (_selectedBook == null ||
        _selectedChapter == null ||
        _rangeStart == null)
      return;

    final int start = _rangeStart!;
    final int end = _rangeEnd ?? start;

    final selectedVerses = _verseList.where((v) {
      final n = v['verse'] as int;
      return n >= start && n <= end;
    }).toList();

    final item = ScriptureQueueItem(
      book: _selectedBook!,
      chapter: _selectedChapter!,
      startVerse: start,
      endVerse: end,
      verses: selectedVerses,
      version: _activeVersion, // ← records which version was active
    );

    setState(() {
      _queue.add(item);
      _activeQueueItem = item;
      _activeSong = null;
      _rangeStart = null;
      _rangeEnd = null;
    });
  }

  void _clearSelection() => setState(() {
    _rangeStart = null;
    _rangeEnd = null;
  });

  void _previewQueueItem(ScriptureQueueItem item) => setState(() {
    _activeQueueItem = item;
    _activeSong = null;
  });

  void _removeFromQueue(int index) {
    setState(() {
      final removed = _queue.removeAt(index);
      if (_activeQueueItem == removed) {
        _activeQueueItem = _queue.isNotEmpty ? _queue.last : null;
      }
    });
  }

  // ── Quick-jump ─────────────────────────────────────────────────────────────

  void _parseAndJumpToReference(String raw) {
    final ref = raw.trim();
    if (ref.isEmpty) return;

    final parts = ref.split(RegExp(r'\s+'));
    if (parts.length < 2) return;

    String matchedBook = '';
    int afterIndex = 0;
    for (int len = parts.length; len > 0; len--) {
      final candidate = parts.sublist(0, len).join(' ');
      final found = _bibleBooks.firstWhere(
        (b) => b.toLowerCase() == candidate.toLowerCase(),
        orElse: () => '',
      );
      if (found.isNotEmpty) {
        matchedBook = found;
        afterIndex = len;
        break;
      }
    }

    if (matchedBook.isEmpty || afterIndex >= parts.length) return;

    final cvRaw = parts.sublist(afterIndex).join('');
    final cvParts = cvRaw.split(':');
    if (cvParts.length != 2) return;

    final chapter = int.tryParse(cvParts[0]);
    if (chapter == null) return;

    final verseRange = cvParts[1].split(RegExp(r'[–\-]'));
    final startVerse = int.tryParse(verseRange[0]);
    final endVerse = verseRange.length > 1
        ? int.tryParse(verseRange[1])
        : startVerse;
    if (startVerse == null) return;

    _selectBook(matchedBook);
    Future.delayed(const Duration(milliseconds: 80), () {
      _selectChapter(chapter);
      Future.delayed(const Duration(milliseconds: 80), () {
        setState(() {
          _rangeStart = startVerse;
          _rangeEnd = endVerse;
        });
      });
    });

    _searchController.clear();
  }

  // ── Song filter ────────────────────────────────────────────────────────────

  void _filterSongs(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filteredSongs = q.isEmpty
          ? _songs
          : _songs
                .where(
                  (s) =>
                      (s['title'] ?? '').toLowerCase().contains(q) ||
                      (s['artist'] ?? '').toLowerCase().contains(q),
                )
                .toList();
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _getVerseText(int verseNum) {
    final entry = _verseList.firstWhere(
      (v) => v['verse'] == verseNum,
      orElse: () => {'verse': verseNum, 'text': ''},
    );
    return (entry['text'] as String?) ?? '';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

// ── _VersionPill ───────────────────────────────────────────────────────────────

/// A tappable pill showing a Bible version abbreviation.
///
/// [isActive]  – renders with blue tint + border when true.
/// [isLoading] – replaces the text with a small spinner (used while switching).
class _VersionPill extends StatelessWidget {
  const _VersionPill({
    required this.version,
    required this.isActive,
    required this.isLoading,
    required this.onTap,
  });

  final BibleVersion version;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      // Show the full name on hover so users know what they're switching to
      message: version.fullName,
      waitDuration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isActive
                  ? kAccentBlue.withValues(alpha: 0.15)
                  : kSurfaceHigh,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isActive ? kAccentBlue.withValues(alpha: 0.5) : kBorder,
              ),
            ),
            child: isLoading
                // Spinner replaces text during the switch
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      color: kAccentBlue,
                      strokeWidth: 1.5,
                    ),
                  )
                : Text(
                    version.abbreviation,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? kAccentBlue : kTextSecondary,
                      letterSpacing: 0.4,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── _SectionLabel ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.accent});
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 13,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: accent,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── _StyledDropdown ────────────────────────────────────────────────────────────

class _StyledDropdown<T> extends StatelessWidget {
  const _StyledDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      onChanged: onChanged,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 18,
        color: kTextMuted,
      ),
      dropdownColor: kSurfaceHigh,
      style: const TextStyle(fontSize: 13, color: kTextPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: kTextMuted),
        isDense: true,
        filled: true,
        fillColor: kAppBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kAccentBlue, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: kBorder.withValues(alpha: 0.4)),
        ),
      ),
      items: items
          .map(
            (v) => DropdownMenuItem<T>(
              value: v,
              child: Text(labelBuilder(v), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
    );
  }
}

// ── _RangeBadge ────────────────────────────────────────────────────────────────

class _RangeBadge extends StatelessWidget {
  const _RangeBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── _QueueCard ─────────────────────────────────────────────────────────────────

/// A compact card in the horizontal queue strip.
/// Shows reference + version abbreviation; tap to preview, × to remove.
class _QueueCard extends StatelessWidget {
  const _QueueCard({
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.onRemove,
  });

  final ScriptureQueueItem item;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? kAccentBlue.withValues(alpha: 0.15) : kSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? kAccentBlue.withValues(alpha: 0.5) : kBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.reference,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? kAccentBlue : kTextPrimary,
                  ),
                ),
                // Show which version this card came from
                Text(
                  item.version.abbreviation,
                  style: TextStyle(
                    fontSize: 9,
                    color: isActive
                        ? kAccentBlue.withValues(alpha: 0.7)
                        : kTextMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                Icons.close_rounded,
                size: 12,
                color: isActive ? kAccentBlue : kTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _PreviewHeader ─────────────────────────────────────────────────────────────

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: kTextSecondary),
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
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: accent,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── _PreviewTextCard ────────────────────────────────────────────────────────────

class _PreviewTextCard extends StatelessWidget {
  const _PreviewTextCard({
    required this.text,
    required this.textAlign,
    this.fontSize = 22,
  });

  final String text;
  final TextAlign textAlign;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: SingleChildScrollView(
        child: Text(
          text,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: fontSize,
            height: 1.9,
            color: kTextPrimary,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.15,
          ),
        ),
      ),
    );
  }
}

// ── _TipRow ─────────────────────────────────────────────────────────────────────

class _TipRow extends StatelessWidget {
  const _TipRow({
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
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: kTextSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
