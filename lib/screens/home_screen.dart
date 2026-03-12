import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../app_theme.dart';
import '../models.dart';
import 'projector_screen.dart';

const double kPanelWidth = 340.0;

// ── Convenience extension ─────────────────────────────────────────────────────
extension _ThemeX on BuildContext {
  AppTheme get t => AppTheme.of(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOK ALIAS RESOLVER
//
// Resolves a user-typed book name (short form, abbreviation, alternate
// spelling, or even a typo) to the canonical long name stored in the DB.
//
// Resolution order:
//   1. Exact match against canonical DB name           (John → John)
//   2. Alias / abbreviation lookup                     (Jn / Joh → John)
//   3. Prefix match against canonical names            (Jo → John)
//   4. Fuzzy match via Levenshtein distance (best ≤ 3) (Jhon → John)
// ─────────────────────────────────────────────────────────────────────────────

class _BookAliasResolver {
  // ── Alias table ─────────────────────────────────────────────────────────────
  // Keys are lowercase aliases / abbreviations.
  // Values are the canonical long names as they appear in the DB.
  //
  // Covers: common English abbreviations, single-letter prefixes, common typos,
  // numbered-book shorthand (1co / 2co), and widely-used alternate spellings.
  static const Map<String, String> _aliases = {
    // ── Genesis ────────────────────────────────────────────────────────────────
    'gen': 'Genesis', 'ge': 'Genesis', 'gn': 'Genesis',

    // ── Exodus ─────────────────────────────────────────────────────────────────
    'exo': 'Exodus', 'ex': 'Exodus', 'exod': 'Exodus',

    // ── Leviticus ──────────────────────────────────────────────────────────────
    'lev': 'Leviticus', 'le': 'Leviticus', 'lv': 'Leviticus',

    // ── Numbers ────────────────────────────────────────────────────────────────
    'num': 'Numbers', 'nu': 'Numbers', 'nm': 'Numbers', 'nb': 'Numbers',

    // ── Deuteronomy ────────────────────────────────────────────────────────────
    'deu': 'Deuteronomy', 'deut': 'Deuteronomy', 'dt': 'Deuteronomy',
    'de': 'Deuteronomy',

    // ── Joshua ─────────────────────────────────────────────────────────────────
    'jos': 'Joshua', 'josh': 'Joshua', 'jsh': 'Joshua',

    // ── Judges ─────────────────────────────────────────────────────────────────
    'jdg': 'Judges', 'judg': 'Judges', 'jg': 'Judges', 'jgs': 'Judges',

    // ── Ruth ───────────────────────────────────────────────────────────────────
    'rut': 'Ruth', 'ru': 'Ruth',

    // ── 1 Samuel ───────────────────────────────────────────────────────────────
    '1sa': '1 Samuel', '1sam': '1 Samuel', '1s': '1 Samuel',
    'i sam': '1 Samuel', 'i samuel': '1 Samuel', '1samuel': '1 Samuel',

    // ── 2 Samuel ───────────────────────────────────────────────────────────────
    '2sa': '2 Samuel', '2sam': '2 Samuel', '2s': '2 Samuel',
    'ii sam': '2 Samuel', 'ii samuel': '2 Samuel', '2samuel': '2 Samuel',

    // ── 1 Kings ────────────────────────────────────────────────────────────────
    '1ki': '1 Kings', '1kgs': '1 Kings', '1k': '1 Kings',
    'i kings': '1 Kings', 'i ki': '1 Kings', '1kings': '1 Kings',

    // ── 2 Kings ────────────────────────────────────────────────────────────────
    '2ki': '2 Kings', '2kgs': '2 Kings', '2k': '2 Kings',
    'ii kings': '2 Kings', '2kings': '2 Kings',

    // ── 1 Chronicles ───────────────────────────────────────────────────────────
    '1ch': '1 Chronicles', '1chr': '1 Chronicles', '1chron': '1 Chronicles',
    'i chron': '1 Chronicles', '1chronicles': '1 Chronicles',

    // ── 2 Chronicles ───────────────────────────────────────────────────────────
    '2ch': '2 Chronicles', '2chr': '2 Chronicles', '2chron': '2 Chronicles',
    'ii chron': '2 Chronicles', '2chronicles': '2 Chronicles',

    // ── Ezra ───────────────────────────────────────────────────────────────────
    'ezr': 'Ezra', 'ez': 'Ezra',

    // ── Nehemiah ───────────────────────────────────────────────────────────────
    'neh': 'Nehemiah', 'ne': 'Nehemiah',

    // ── Esther ─────────────────────────────────────────────────────────────────
    'est': 'Esther', 'esth': 'Esther', 'es': 'Esther',

    // ── Job ────────────────────────────────────────────────────────────────────
    'jb': 'Job',

    // ── Psalms ─────────────────────────────────────────────────────────────────
    'psa': 'Psalms', 'ps': 'Psalms', 'psalm': 'Psalms', 'pss': 'Psalms',

    // ── Proverbs ───────────────────────────────────────────────────────────────
    'pro': 'Proverbs', 'prov': 'Proverbs', 'prv': 'Proverbs', 'pr': 'Proverbs',

    // ── Ecclesiastes ───────────────────────────────────────────────────────────
    'ecc': 'Ecclesiastes', 'eccl': 'Ecclesiastes', 'qoh': 'Ecclesiastes',
    'ec': 'Ecclesiastes',

    // ── Song of Solomon / Song of Songs ────────────────────────────────────────
    'sos': 'Song of Solomon', 'sol': 'Song of Solomon',
    'song': 'Song of Solomon', 'ss': 'Song of Solomon',
    'sng': 'Song of Solomon', 'sg': 'Song of Solomon',
    'song of songs': 'Song of Solomon', 'canticles': 'Song of Solomon',

    // ── Isaiah ─────────────────────────────────────────────────────────────────
    'isa': 'Isaiah', 'is': 'Isaiah',

    // ── Jeremiah ───────────────────────────────────────────────────────────────
    'jer': 'Jeremiah', 'je': 'Jeremiah', 'jr': 'Jeremiah',

    // ── Lamentations ───────────────────────────────────────────────────────────
    'lam': 'Lamentations', 'la': 'Lamentations',

    // ── Ezekiel ────────────────────────────────────────────────────────────────
    'eze': 'Ezekiel', 'ezek': 'Ezekiel', 'ezk': 'Ezekiel',

    // ── Daniel ─────────────────────────────────────────────────────────────────
    'dan': 'Daniel', 'da': 'Daniel', 'dn': 'Daniel',

    // ── Hosea ──────────────────────────────────────────────────────────────────
    'hos': 'Hosea', 'ho': 'Hosea',

    // ── Joel ───────────────────────────────────────────────────────────────────
    'joe': 'Joel', 'jl': 'Joel',

    // ── Amos ───────────────────────────────────────────────────────────────────
    'amo': 'Amos', 'am': 'Amos',

    // ── Obadiah ────────────────────────────────────────────────────────────────
    'oba': 'Obadiah', 'ob': 'Obadiah', 'obad': 'Obadiah',

    // ── Jonah ──────────────────────────────────────────────────────────────────
    'jon': 'Jonah', 'jnh': 'Jonah',

    // ── Micah ──────────────────────────────────────────────────────────────────
    'mic': 'Micah', 'mc': 'Micah',

    // ── Nahum ──────────────────────────────────────────────────────────────────
    'nah': 'Nahum', 'na': 'Nahum',

    // ── Habakkuk ───────────────────────────────────────────────────────────────
    'hab': 'Habakkuk', 'hb': 'Habakkuk',

    // ── Zephaniah ──────────────────────────────────────────────────────────────
    'zep': 'Zephaniah', 'zeph': 'Zephaniah', 'zp': 'Zephaniah',

    // ── Haggai ─────────────────────────────────────────────────────────────────
    'hag': 'Haggai', 'hg': 'Haggai',

    // ── Zechariah ──────────────────────────────────────────────────────────────
    'zec': 'Zechariah', 'zech': 'Zechariah', 'zc': 'Zechariah',

    // ── Malachi ────────────────────────────────────────────────────────────────
    'mal': 'Malachi', 'ml': 'Malachi',

    // ── Matthew ────────────────────────────────────────────────────────────────
    'mat': 'Matthew', 'matt': 'Matthew', 'mt': 'Matthew',

    // ── Mark ───────────────────────────────────────────────────────────────────
    'mar': 'Mark', 'mrk': 'Mark', 'mk': 'Mark',

    // ── Luke ───────────────────────────────────────────────────────────────────
    'luk': 'Luke', 'lk': 'Luke',

    // ── John ───────────────────────────────────────────────────────────────────
    'joh': 'John', 'jn': 'John', 'jhn': 'John',

    // ── Acts ───────────────────────────────────────────────────────────────────
    'act': 'Acts', 'ac': 'Acts',

    // ── Romans ─────────────────────────────────────────────────────────────────
    'rom': 'Romans', 'ro': 'Romans', 'rm': 'Romans',

    // ── 1 Corinthians ──────────────────────────────────────────────────────────
    '1co': '1 Corinthians', '1cor': '1 Corinthians',
    'i cor': '1 Corinthians', '1corinthians': '1 Corinthians',

    // ── 2 Corinthians ──────────────────────────────────────────────────────────
    '2co': '2 Corinthians', '2cor': '2 Corinthians',
    'ii cor': '2 Corinthians', '2corinthians': '2 Corinthians',

    // ── Galatians ──────────────────────────────────────────────────────────────
    'gal': 'Galatians', 'ga': 'Galatians',

    // ── Ephesians ──────────────────────────────────────────────────────────────
    'eph': 'Ephesians', 'ep': 'Ephesians',

    // ── Philippians ────────────────────────────────────────────────────────────
    'php': 'Philippians', 'phil': 'Philippians', 'pp': 'Philippians',
    'phl': 'Philippians',

    // ── Colossians ─────────────────────────────────────────────────────────────
    'col': 'Colossians', 'co': 'Colossians',

    // ── 1 Thessalonians ────────────────────────────────────────────────────────
    '1th': '1 Thessalonians', '1thes': '1 Thessalonians',
    '1thess': '1 Thessalonians', 'i thess': '1 Thessalonians',
    '1thessalonians': '1 Thessalonians',

    // ── 2 Thessalonians ────────────────────────────────────────────────────────
    '2th': '2 Thessalonians', '2thes': '2 Thessalonians',
    '2thess': '2 Thessalonians', 'ii thess': '2 Thessalonians',
    '2thessalonians': '2 Thessalonians',

    // ── 1 Timothy ──────────────────────────────────────────────────────────────
    '1ti': '1 Timothy', '1tim': '1 Timothy',
    'i tim': '1 Timothy', '1timothy': '1 Timothy',

    // ── 2 Timothy ──────────────────────────────────────────────────────────────
    '2ti': '2 Timothy', '2tim': '2 Timothy',
    'ii tim': '2 Timothy', '2timothy': '2 Timothy',

    // ── Titus ──────────────────────────────────────────────────────────────────
    'tit': 'Titus', 'ti': 'Titus',

    // ── Philemon ───────────────────────────────────────────────────────────────
    'phm': 'Philemon', 'phlm': 'Philemon', 'phile': 'Philemon',

    // ── Hebrews ────────────────────────────────────────────────────────────────
    'heb': 'Hebrews', 'he': 'Hebrews',

    // ── James ──────────────────────────────────────────────────────────────────
    'jas': 'James', 'jm': 'James',

    // ── 1 Peter ────────────────────────────────────────────────────────────────
    '1pe': '1 Peter', '1pet': '1 Peter', '1pt': '1 Peter',
    'i pet': '1 Peter', '1peter': '1 Peter',

    // ── 2 Peter ────────────────────────────────────────────────────────────────
    '2pe': '2 Peter', '2pet': '2 Peter', '2pt': '2 Peter',
    'ii pet': '2 Peter', '2peter': '2 Peter',

    // ── 1 John ─────────────────────────────────────────────────────────────────
    '1jo': '1 John', '1jn': '1 John', '1joh': '1 John',
    'i john': '1 John', '1john': '1 John',

    // ── 2 John ─────────────────────────────────────────────────────────────────
    '2jo': '2 John', '2jn': '2 John', '2joh': '2 John',
    'ii john': '2 John', '2john': '2 John',

    // ── 3 John ─────────────────────────────────────────────────────────────────
    '3jo': '3 John', '3jn': '3 John', '3joh': '3 John',
    'iii john': '3 John', '3john': '3 John',

    // ── Jude ───────────────────────────────────────────────────────────────────
    'jud': 'Jude', 'jude': 'Jude',

    // ── Revelation ─────────────────────────────────────────────────────────────
    'rev': 'Revelation', 're': 'Revelation', 'rv': 'Revelation',
    'apoc': 'Revelation', 'apocalypse': 'Revelation',
  };

  /// Levenshtein distance between two strings (case-insensitive).
  static int _lev(String a, String b) {
    a = a.toLowerCase();
    b = b.toLowerCase();
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final prev = List<int>.generate(b.length + 1, (i) => i);
    final curr = List<int>.filled(b.length + 1, 0);
    for (int i = 0; i < a.length; i++) {
      curr[0] = i + 1;
      for (int j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        curr[j + 1] = [
          curr[j] + 1,
          prev[j + 1] + 1,
          prev[j] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
      prev.setAll(0, curr);
    }
    return prev[b.length];
  }

  /// Resolve [input] (the book portion of a typed reference) against
  /// [canonicalBooks] (the list loaded from the SQLite DB).
  ///
  /// Returns the matched canonical book name, or an empty string on failure.
  static String resolve(String input, List<String> canonicalBooks) {
    final q = input.trim().toLowerCase();
    if (q.isEmpty) return '';

    // 1. Exact match against canonical names ──────────────────────────────────
    for (final b in canonicalBooks) {
      if (b.toLowerCase() == q) return b;
    }

    // 2. Alias / abbreviation lookup ─────────────────────────────────────────
    final aliasHit = _aliases[q];
    if (aliasHit != null) {
      // Verify the alias target actually exists in the loaded DB
      final found = canonicalBooks.firstWhere(
        (b) => b.toLowerCase() == aliasHit.toLowerCase(),
        orElse: () => '',
      );
      if (found.isNotEmpty) return found;
    }

    // 3. Prefix match against canonical names ─────────────────────────────────
    // e.g. "Jo" → "John", "Joh" → "John"
    // Only use if exactly one book starts with the prefix (avoids ambiguity).
    if (q.length >= 2) {
      final prefixMatches = canonicalBooks
          .where((b) => b.toLowerCase().startsWith(q))
          .toList();
      if (prefixMatches.length == 1) return prefixMatches.first;
    }

    // 4. Fuzzy match (Levenshtein) ─────────────────────────────────────────────
    // Score against canonical names AND alias targets.
    // Threshold: allow ≤ 3 edits for longer words, ≤ 2 for short words.
    final threshold = q.length <= 4 ? 2 : 3;

    String bestBook = '';
    int bestDist = threshold + 1;

    for (final b in canonicalBooks) {
      final d = _lev(q, b.toLowerCase());
      if (d < bestDist) {
        bestDist = d;
        bestBook = b;
      }
    }

    // Also fuzzy-match alias keys to catch things like "jhon" → alias "joh" → John
    for (final entry in _aliases.entries) {
      final d = _lev(q, entry.key);
      if (d < bestDist) {
        // Make sure the alias target is in the DB
        final found = canonicalBooks.firstWhere(
          (b) => b.toLowerCase() == entry.value.toLowerCase(),
          orElse: () => '',
        );
        if (found.isNotEmpty) {
          bestDist = d;
          bestBook = found;
        }
      }
    }

    return bestBook;
  }
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
  // Reverse map: book_number → display name (rebuilt on each version load)
  final Map<int, String> _bookByNumber = {};

  String? _selectedBook;
  // Stable cross-version identity — survives book name changes between versions
  int? _selectedBookNumber;
  List<int> _chapters = [];

  int? _selectedChapter;
  List<Map<String, dynamic>> _verseList = [];

  // ── Passage picker (clicker-friendly From / To dropdowns) ─────────────────

  int? _pickerFromVerse;
  int? _pickerToVerse;

  // ── Middle verse-overview panel ────────────────────────────────────────────

  /// ScrollController for the middle chapter overview so we can
  /// programmatically jump to the selected verse range.
  final ScrollController _verseOverviewScroll = ScrollController();

  /// Approximate height of each verse row in the overview panel (px).
  static const double _kVerseRowHeight = 52.0;

  // Song overview (Col 3)
  /// Song selected in the Col1 list — drives the Col3 section list.
  Map<String, String>? _selectedSong;
  /// Section currently highlighted/live in the song overview.
  SongSection? _selectedSection;

  // ── Service plan ───────────────────────────────────────────────────────────

  final List<ServiceItem> _plan = [];
  int _activeIndex = -1; // index into _plan; -1 = nothing live

  ServiceItem? get _activeItem =>
      _activeIndex >= 0 && _activeIndex < _plan.length
          ? _plan[_activeIndex]
          : null;

  // Derived convenience getters used by preview / projector
  ScriptureQueueItem? get _activeQueueItem =>
      _activeItem?.type == ServiceItemType.scripture
          ? _activeItem!.scriptureItem
          : null;

  Map<String, String>? get _activeSong =>
      _activeItem?.type == ServiceItemType.song ? _activeItem!.song : null;

  // Auto-save
  static const _kAutoSaveFileName = 'service_plan.json';

  final List<Map<String, String>> _songs = [
    {
      'title': 'Amazing Grace',
      'artist': 'John Newton',
      'lyrics':
          '[Verse 1]\n'
          'Amazing grace, how sweet the sound\n'
          'That saved a wretch like me\n'
          'I once was lost but now am found\n'
          'Was blind but now I see\n'
          '[Verse 2]\n'
          "'Twas grace that taught my heart to fear\n"
          'And grace my fears relieved\n'
          'How precious did that grace appear\n'
          'The hour I first believed\n'
          '[Chorus]\n'
          'My chains are gone, I\'ve been set free\n'
          'My God, my Savior has ransomed me\n'
          'And like a flood His mercy rains\n'
          'Unending love, amazing grace\n'
          '[Verse 3]\n'
          'The Lord has promised good to me\n'
          'His word my hope secures\n'
          'He will my shield and portion be\n'
          'As long as life endures',
    },
    {
      'title': 'How Great Thou Art',
      'artist': 'Carl Boberg',
      'lyrics':
          '[Verse 1]\n'
          'O Lord my God, when I in awesome wonder\n'
          'Consider all the worlds thy hands have made\n'
          'I see the stars, I hear the rolling thunder\n'
          'Thy power throughout the universe displayed\n'
          '[Chorus]\n'
          'Then sings my soul, my Savior God, to thee\n'
          'How great thou art, how great thou art\n'
          'Then sings my soul, my Savior God, to thee\n'
          'How great thou art, how great thou art\n'
          '[Verse 2]\n'
          'When through the woods and forest glades I wander\n'
          'And hear the birds sing sweetly in the trees\n'
          'When I look down from lofty mountain grandeur\n'
          'And hear the brook and feel the gentle breeze\n'
          '[Verse 3]\n'
          'And when I think that God, his Son not sparing\n'
          'Sent him to die, I scarce can take it in\n'
          'That on the cross, my burden gladly bearing\n'
          'He bled and died to take away my sin',
    },
    {
      'title': 'Jesus Loves Me',
      'artist': 'Traditional',
      'lyrics':
          '[Verse 1]\n'
          'Jesus loves me, this I know\n'
          'For the Bible tells me so\n'
          'Little ones to Him belong\n'
          'They are weak but He is strong\n'
          '[Chorus]\n'
          'Yes, Jesus loves me\n'
          'Yes, Jesus loves me\n'
          'Yes, Jesus loves me\n'
          'The Bible tells me so\n'
          '[Verse 2]\n'
          'Jesus loves me, he who died\n'
          'Heaven\'s gate to open wide\n'
          'He will wash away my sin\n'
          'Let his little child come in',
    },
  ];

  late List<Map<String, String>> _filteredSongs;

  // ── Keyboard focus ─────────────────────────────────────────────────────────
  final FocusNode _keyboardFocus = FocusNode();

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _songSearchController = TextEditingController();
    _filteredSongs = _songs;
    _loadVersion(kBibleVersions.first, isInitialLoad: true);
    _loadServicePlan();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _songSearchController.dispose();
    _verseOverviewScroll.dispose();
    _keyboardFocus.dispose();
    _database?.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (!_initialLoadDone) return _buildFullScreenLoader();

    return KeyboardListener(
      focusNode: _keyboardFocus,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Row(
        children: [
          // ── Col 1: Scripture pickers + Song list (fixed 300px) ───────────────
          SizedBox(
            width: kPanelWidth,
            child: Container(
              color: context.t.surface,
              child: Column(
                children: [
                  Expanded(child: _buildScripturePanel()),
                  Divider(color: context.t.border, height: 1, thickness: 1),
                  Expanded(child: _buildSongPanel()),
                ],
              ),
            ),
          ),

          VerticalDivider(width: 1, color: context.t.border),

          // ── Col 2: Verse overview (fixed 220px) ─────────────────────────────────────────
          SizedBox(
            width: 220,
            child: _buildChapterOverviewPanel(),
          ),

          VerticalDivider(width: 1, color: context.t.border),

          // ── Col 3: Song overview (fixed 220px) ─────────────────────────────────────────
          SizedBox(
            width: 220,
            child: _buildSongOverviewPanel(),
          ),

          VerticalDivider(width: 1, color: context.t.border),

          // ── Col 4: Operator preview (top) + Service Plan (bottom) ────────────
          Expanded(
            child: Container(
              color: context.t.appBg,
              child: Column(
                children: [
                  Expanded(
                    flex: 6,
                    child: _buildDisplaySection(),
                  ),
                  Flexible(
                    flex: 4,
                    child: _buildServicePlanPanel(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenLoader() {
    return Container(
      color: context.t.appBg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: context.t.accentBlue,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading Bible…',
              style: TextStyle(fontSize: 14, color: context.t.textSecondary),
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
        _SectionLabel(label: 'SCRIPTURE', accent: context.t.accentBlue),
        _buildSearchBar(),
        _buildPassagePicker(),
        // Version library fills all remaining space below the pickers
        Expanded(child: _buildVersionLibrary()),
      ],
    );
  }

  // ── Passage Picker ─────────────────────────────────────────────────────────
  //
  // A single compact panel that serves BOTH clickers AND typists:
  //
  //   Row 1:  [ Book ▼ ──────────── ]  [ Ch. ▼ ]
  //   Row 2:  [ From verse ▼ ]  [ To verse ▼ ]  [ ➕ Add ]
  //
  // All four dropdowns populate in sequence (Book → Ch → From/To).
  // From defaults to verse 1, To defaults to the last verse of the chapter.
  // One tap on Add queues the passage — no scrolling, no tapping individual
  // verses.  Works perfectly for Psalm 119:65-88 in ≤ 5 clicks.
  //
  // Below the pickers, a read-only verse preview list shows the selected range
  // highlighted so the operator can confirm before adding.
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPassagePicker() {
    final t = context.t;
    final bool chapterReady = _selectedBook != null && !_versionLoading;
    final bool versesReady = chapterReady && _verseList.isNotEmpty;
    final verseNumbers = _verseList.map((v) => v['verse'] as int).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Row 1: Book + Chapter ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SELECT PASSAGE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: t.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
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
                        onChanged: chapterReady ? _selectChapter : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Row 2: From + To + Add ─────────────────────────────────
                Row(
                  children: [
                    // From verse
                    Expanded(
                      child: _StyledDropdown<int>(
                        hint: 'From',
                        value: versesReady ? _pickerFromVerse : null,
                        items: versesReady ? verseNumbers : [],
                        labelBuilder: (v) => 'v.$v',
                        onChanged: versesReady
                            ? (v) {
                                setState(() {
                                  _pickerFromVerse = v;
                                  if (_pickerToVerse != null &&
                                      v != null &&
                                      _pickerToVerse! < v) {
                                    _pickerToVerse = v;
                                  }
                                });
                                Future.delayed(
                                  const Duration(milliseconds: 50),
                                  _scrollOverviewToSelection,
                                );
                              }
                            : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // To verse
                    Expanded(
                      child: _StyledDropdown<int>(
                        hint: 'To',
                        value: versesReady ? _pickerToVerse : null,
                        items: versesReady
                            ? verseNumbers
                                  .where(
                                    (v) =>
                                        _pickerFromVerse == null ||
                                        v >= _pickerFromVerse!,
                                  )
                                  .toList()
                            : [],
                        labelBuilder: (v) => 'v.$v',
                        onChanged: versesReady
                            ? (v) => setState(() => _pickerToVerse = v)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Add button
                    FilledButton.icon(
                      onPressed: versesReady &&
                              _pickerFromVerse != null &&
                              _pickerToVerse != null
                          ? _addPickerSelectionToQueue
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: t.accentBlue,
                        disabledBackgroundColor: t.border,
                        foregroundColor:
                            t.isDark ? t.appBg : Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 15),
                      label: const Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // (Verse preview moved to middle column overview panel)
        ],
      );
  }

  /// Version selector — a wrapping row of compact chips.
  /// Scrolls horizontally if there are too many versions to fit.
  /// The active chip is filled; others are outlined. Loading shows a spinner.
  // ── Version Library ────────────────────────────────────────────────────────
  //
  // Fills the empty space below the passage pickers.
  // Shows every installed Bible version as a full-width row with abbreviation
  // badge + full name, making it easy to find and switch even with 10+ versions.
  // The active row is highlighted; switching shows an inline spinner.
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildVersionLibrary() {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: t.surfaceHigh,
            border: Border(
              top: BorderSide(color: t.border),
              bottom: BorderSide(color: t.border),
            ),
          ),
          child: Text(
            'BIBLE VERSIONS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: t.textMuted,
              letterSpacing: 1.2,
            ),
          ),
        ),

        // Scrollable list of all installed versions
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: kBibleVersions.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: t.border),
            itemBuilder: (context, index) {
              final version = kBibleVersions[index];
              final bool isActive = version == _activeVersion;
              final bool isLoading = isActive && _versionLoading;

              return InkWell(
                onTap: () => _switchVersion(version),
                hoverColor: t.accentBlue.withValues(alpha: 0.05),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? t.accentBlue.withValues(alpha: 0.1)
                        : Colors.transparent,
                    border: Border(
                      left: BorderSide(
                        color: isActive ? t.accentBlue : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Abbreviation badge
                      Container(
                        width: 44,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? t.accentBlue
                              : t.surfaceHigh,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: isActive
                                ? t.accentBlue
                                : t.border,
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                height: 12,
                                child: Center(
                                  child: SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: t.isDark
                                          ? t.appBg
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                version.abbreviation,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isActive
                                      ? (t.isDark ? t.appBg : Colors.white)
                                      : t.textSecondary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),

                      // Full name
                      Expanded(
                        child: Text(
                          version.fullName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isActive
                                ? t.accentBlue
                                : t.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Active checkmark
                      if (isActive && !isLoading)
                        Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: t.accentBlue,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  // ── Zone 2: Search bar ─────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.t.border)),
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: _parseAndJumpToReference,
        style: TextStyle(fontSize: 13, color: context.t.textPrimary),
        decoration: InputDecoration(
          hintText: 'e.g. Jn 3:16  ·  rev12:1  ·  revelation22:1-5  ·  jhon 3',
          hintStyle: TextStyle(fontSize: 12, color: context.t.textMuted),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 17,
            color: context.t.textMuted,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: context.t.accentBlue,
            ),
            tooltip: 'Go',
            splashRadius: 16,
            onPressed: () => _parseAndJumpToReference(_searchController.text),
          ),
          filled: true,
          fillColor: context.t.appBg,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: context.t.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: context.t.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: context.t.accentBlue, width: 1.5),
          ),
        ),
      ),
    );
  }


  // ── Zone 6: Queue strip ────────────────────────────────────────────────────

  // ═══════════════════════════════════════════════════════════════════════════
  // COL 3 — QUEUE PANEL  (bottom half of the operator column)
  // ═══════════════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════════════
  // SERVICE PLAN PANEL  (bottom of col 3)
  // ═══════════════════════════════════════════════════════════════════════════

  final ScrollController _planScroll = ScrollController();

  Widget _buildServicePlanPanel() {
    final t = context.t;
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.border, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: t.surfaceHigh,
              border: Border(bottom: BorderSide(color: t.border)),
            ),
            child: Row(
              children: [
                Icon(Icons.format_list_numbered_rounded, size: 13, color: t.textMuted),
                const SizedBox(width: 6),
                Text(
                  'SERVICE PLAN',
                  style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: t.textMuted, letterSpacing: 1.2,
                  ),
                ),
                if (_plan.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: t.accentBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_plan.length}',
                      style: TextStyle(fontSize: 9, color: t.accentBlue, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
                const Spacer(),

                // Quick-action: Black screen
                _PlanQuickButton(
                  icon: Icons.circle,
                  label: 'Black',
                  color: const Color(0xFF777777),
                  onTap: _addBlackScreen,
                ),
                const SizedBox(width: 6),
                // Quick-action: Logo slide
                _PlanQuickButton(
                  icon: Icons.church_rounded,
                  label: 'Logo',
                  color: const Color(0xFF4CAF50),
                  onTap: _addLogoSlide,
                ),
                const SizedBox(width: 6),
                // Add announcement
                _PlanQuickButton(
                  icon: Icons.campaign_rounded,
                  label: 'Announce',
                  color: const Color(0xFFE6A817),
                  onTap: _showAnnouncementDialog,
                ),
                const SizedBox(width: 6),
                // Clear whole plan
                if (_plan.isNotEmpty)
                  _PlanQuickButton(
                    icon: Icons.delete_sweep_rounded,
                    label: 'Clear all',
                    color: t.textMuted,
                    onTap: _confirmClearPlan,
                  ),
              ],
            ),
          ),

          // ── Nav bar: prev / position / next ─────────────────────────────────
          if (_plan.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: t.border)),
              ),
              child: Row(
                children: [
                  _navButton(
                    icon: Icons.skip_previous_rounded,
                    onTap: _activeIndex > 0 ? _stepBack : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _activeIndex < 0
                        ? 'Not live'
                        : '${_activeIndex + 1} / ${_plan.length}',
                    style: TextStyle(fontSize: 10, color: t.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  _navButton(
                    icon: Icons.skip_next_rounded,
                    onTap: _activeIndex < _plan.length - 1 ? _stepForward : null,
                  ),
                  const Spacer(),
                  // "Go Live" shortcut for current preview
                  if (_activeItem != null)
                    GestureDetector(
                      onTap: _goLive,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: t.accentBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: t.accentBlue.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cast_rounded, size: 11, color: t.accentBlue),
                            const SizedBox(width: 5),
                            Text(
                              'Go Live',
                              style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w700,
                                color: t.accentBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // ── Plan list ────────────────────────────────────────────────────────
          Expanded(
            child: _plan.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.playlist_add_rounded, size: 28, color: t.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          'Service plan is empty',
                          style: TextStyle(fontSize: 12, color: t.textMuted),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Add scripture, songs, announcements or logo slides',
                          style: TextStyle(fontSize: 10, color: t.textMuted),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    scrollController: _planScroll,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    itemCount: _plan.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = _plan.removeAt(oldIndex);
                        _plan.insert(newIndex, item);
                        // Keep _activeIndex tracking the same item
                        if (_activeIndex == oldIndex) {
                          _activeIndex = newIndex;
                        } else if (oldIndex < _activeIndex && newIndex >= _activeIndex) {
                          _activeIndex--;
                        } else if (oldIndex > _activeIndex && newIndex <= _activeIndex) {
                          _activeIndex++;
                        }
                      });
                      _autoSavePlan();
                    },
                    itemBuilder: (context, index) => _buildPlanRow(index),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _navButton({required IconData icon, VoidCallback? onTap}) {
    final t = context.t;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: onTap != null
              ? t.accentBlue.withValues(alpha: 0.1)
              : t.surfaceHigh,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 14,
          color: onTap != null ? t.accentBlue : t.textMuted,
        ),
      ),
    );
  }

  Widget _buildPlanRow(int index) {
    final t = context.t;
    final item = _plan[index];
    final isActive = index == _activeIndex;
    final isDone = _activeIndex >= 0 && index < _activeIndex;
    final accent = item.accentColor(t);

    return InkWell(
      key: ValueKey(item.id),
      onTap: () => _selectPlanItem(index),
      hoverColor: accent.withValues(alpha: 0.05),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? accent.withValues(alpha: 0.1) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isActive ? accent : Colors.transparent,
              width: 3,
            ),
            bottom: BorderSide(color: t.border.withValues(alpha: 0.5)),
          ),
        ),
        child: Row(
          children: [
            // Drag handle
            Icon(Icons.drag_indicator_rounded, size: 13, color: t.textMuted),
            const SizedBox(width: 6),

            // Type icon
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isActive
                    ? accent.withValues(alpha: 0.2)
                    : t.surfaceHigh,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(
                item.icon,
                size: 13,
                color: isDone
                    ? t.textMuted
                    : isActive
                        ? accent
                        : accent.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 10),

            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isDone
                          ? t.textMuted
                          : isActive
                              ? accent
                              : t.textPrimary,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.subtitle.isNotEmpty)
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 9,
                        color: isDone ? t.textMuted : t.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Live badge
            if (isActive) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: accent,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],

            // Remove
            GestureDetector(
              onTap: () => _removePlanItem(index),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 12, color: t.textMuted),
              ),
            ),
          ],
        ),
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
        Row(
          children: [
            Expanded(child: _SectionLabel(label: 'SONGS', accent: context.t.accentPurple)),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Tooltip(
                message: 'Add new song',
                child: GestureDetector(
                  onTap: () => _showSongEditorDialog(null),
                  child: Icon(Icons.add_rounded, size: 16, color: context.t.accentPurple),
                ),
              ),
            ),
          ],
        ),

        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.t.border)),
          ),
          child: TextField(
            controller: _songSearchController,
            onChanged: _filterSongs,
            style: TextStyle(fontSize: 13, color: context.t.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search songs…',
              hintStyle: TextStyle(fontSize: 12, color: context.t.textMuted),
              prefixIcon: Icon(
                Icons.music_note_rounded,
                size: 17,
                color: context.t.textMuted,
              ),
              filled: true,
              fillColor: context.t.appBg,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.t.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.t.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: context.t.accentPurple,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),

        Expanded(
          child: _filteredSongs.isEmpty
              ? Center(
                  child: Text(
                    'No songs found',
                    style: TextStyle(fontSize: 12, color: context.t.textMuted),
                  ),
                )
              : ListView.separated(
                  itemCount: _filteredSongs.length,
                  separatorBuilder: (_, _) =>
                      Divider(color: context.t.border, height: 1),
                  itemBuilder: (context, index) {
                    final song = _filteredSongs[index];
                    final isSelected = _selectedSong?['title'] == song['title'];
                    return InkWell(
                      // Single-tap: load this song's sections in the overview
                      onTap: () {
                        setState(() {
                          _selectedSong = song;
                          _selectedSection = null;
                        });
                      },
                      hoverColor: context.t.accentPurple.withValues(
                        alpha: 0.06,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.t.accentPurple.withValues(alpha: 0.1)
                              : Colors.transparent,
                          border: isSelected
                              ? Border(
                                  left: BorderSide(
                                    color: context.t.accentPurple,
                                    width: 3,
                                  ),
                                )
                              : Border(
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
                                color: isSelected
                                    ? context.t.accentPurple
                                    : context.t.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              song['artist'] ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.t.textSecondary,
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
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: context.t.border)),
          ),
          child: Text(
            'Double-tap a song to preview',
            style: TextStyle(fontSize: 10, color: context.t.textMuted),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RIGHT PANEL — PREVIEW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDisplaySection() {
    final item = _activeItem;
    // Nothing live — show selected section preview if tapped in song overview
    if (item == null) {
      if (_selectedSection != null && _selectedSong != null) {
        final previewSong = Map<String, String>.from(_selectedSong!)
          ..['lyrics'] = _selectedSection!.text
          ..['_sectionLabel'] = _selectedSection!.label;
        return _buildSongPreview(previewSong);
      }
      return _buildWelcomeScreen();
    }

    switch (item.type) {
      case ServiceItemType.scripture:
        return _buildScripturePreview(item.scriptureItem!);
      case ServiceItemType.song:
        return _buildSongPreview(item.song!);
      case ServiceItemType.announcement:
        return _buildAnnouncementPreview(item);
      case ServiceItemType.logo:
        return _buildLogoPreview();
      case ServiceItemType.black:
        return _buildBlackPreview();
    }
  }


  // ═══════════════════════════════════════════════════════════════════════════
  // MIDDLE COLUMN — CHAPTER VERSE OVERVIEW
  // ═══════════════════════════════════════════════════════════════════════════

  /// Always-visible middle panel.
  /// Shows all verses of the loaded chapter with the picker range highlighted.
  /// • Single-tap  → sets From & To to that verse (updates picker + highlight)
  /// • Double-tap  → queues and displays the verse/range immediately
  /// Auto-scrolls to the first verse of the selection whenever From changes.
  Widget _buildChapterOverviewPanel() {
    final t = context.t;

    return Container(
      color: t.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: t.surfaceHigh,
              border: Border(bottom: BorderSide(color: t.border)),
            ),
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded, size: 13, color: t.accentBlue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _selectedBook != null && _selectedChapter != null
                        ? '$_selectedBook  ·  Ch. $_selectedChapter'
                        : 'Verse Overview',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_verseList.isNotEmpty)
                  Text(
                    '${_verseList.length}v',
                    style: TextStyle(fontSize: 10, color: t.textMuted),
                  ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────────
          Expanded(
            child: _versionLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: t.accentBlue,
                      strokeWidth: 2,
                    ),
                  )
                : _verseList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 36,
                          color: t.textMuted,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _selectedBook == null
                              ? 'Select a book\n& chapter'
                              : 'Select a chapter',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: t.textMuted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  )
                : Builder(builder: (context) {
                    final rows = _buildVerseRows();
                    return ListView.builder(
                      controller: _verseOverviewScroll,
                      padding: EdgeInsets.zero,
                      itemCount: rows.length,
                      itemExtent: _kVerseRowHeight,
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        return _buildOverviewVerseRow(
                          verseNum: row.startVerse,
                          endVerseNum: row.endVerse,
                          verseText: row.text,
                        );
                      },
                    );
                  }),
          ),

          // ── Prev / Next navigation bar ───────────────────────────────────────
          _buildOverviewNavBar(
            accent: t.accentBlue,
            onPrev: _verseList.isEmpty ? null : () {
              final rows = _buildVerseRows();
              if (rows.isEmpty) return;
              final cur = rows.indexWhere((r) => r.startVerse == _pickerFromVerse);
              final idx = (cur <= 0) ? rows.length - 1 : cur - 1;
              setState(() {
                _pickerFromVerse = rows[idx].startVerse;
                _pickerToVerse  = rows[idx].endVerse;
              });
              _addPickerSelectionToQueue();
            },
            onNext: _verseList.isEmpty ? null : () {
              final rows = _buildVerseRows();
              if (rows.isEmpty) return;
              final cur = rows.indexWhere((r) => r.startVerse == _pickerFromVerse);
              final idx = (cur < 0 || cur >= rows.length - 1) ? 0 : cur + 1;
              setState(() {
                _pickerFromVerse = rows[idx].startVerse;
                _pickerToVerse  = rows[idx].endVerse;
              });
              _addPickerSelectionToQueue();
            },
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // COL 3 — SONG SECTION OVERVIEW
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildSongOverviewPanel() {
    final t = context.t;
    final song = _selectedSong;

    // Parse sections from the selected song's lyrics
    final sections = song != null
        ? parseSongSections(song['lyrics'] ?? '')
        : <SongSection>[];

    return Container(
      color: t.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
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
                    song != null
                        ? song['title'] ?? 'Song Overview'
                        : 'Song Overview',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (sections.isNotEmpty)
                  Text(
                    '${sections.length}',
                    style: TextStyle(fontSize: 10, color: t.textMuted),
                  ),
                if (song != null)
                  GestureDetector(
                    onTap: () => _showSongEditorDialog(song),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(Icons.edit_rounded, size: 13, color: t.textMuted),
                    ),
                  ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────────
          Expanded(
            child: song == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.music_note_outlined, size: 36, color: t.textMuted),
                        const SizedBox(height: 10),
                        Text(
                          'Select a song\nfrom the list',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: t.textMuted, height: 1.5),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: sections.length,
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      final isSelected = _selectedSection?.label == section.label &&
                          _selectedSection?.text == section.text;
                      final isLive = _activeItem?.type == ServiceItemType.song &&
                          _activeItem?.song?['title'] == song['title'] &&
                          _activeItem?.song?['_sectionLabel'] == section.label;

                      return InkWell(
                        // Single-tap: preview this section in Col 4
                        onTap: () => setState(() => _selectedSection = section),
                        // Double-tap: add to plan and go live
                        onDoubleTap: () {
                          final sectionSong = Map<String, String>.from(song)
                            ..['lyrics'] = section.text
                            ..['_sectionLabel'] = section.label;
                          setState(() {
                            _selectedSection = section;
                            _plan.add(ServiceItem(
                              type: ServiceItemType.song,
                              song: sectionSong,
                            ));
                            _activeIndex = _plan.length - 1;
                          });
                          _autoSavePlan();
                        },
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
                                    // Section label (Verse 1, Chorus, etc.)
                                    if (section.hasLabel)
                                      Text(
                                        section.label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isLive || isSelected
                                              ? t.accentPurple
                                              : t.textSecondary,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    if (section.hasLabel)
                                      const SizedBox(height: 3),
                                    // First line(s) of section as preview
                                    Text(
                                      section.text,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        height: 1.4,
                                        color: isLive || isSelected
                                            ? t.textPrimary
                                            : t.textSecondary,
                                      ),
                                    ),
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
                                  child: const Text(
                                    'LIVE',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // ── Prev / Next + Add Section nav bar ────────────────────────────────
          _buildOverviewNavBar(
            accent: t.accentPurple,
            extraButton: IconButton(
              icon: Icon(Icons.add_rounded, size: 16, color: t.accentPurple),
              tooltip: 'Add / edit song',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () => _showSongEditorDialog(song),
            ),
            onPrev: sections.isEmpty ? null : () {
              final cur = sections.indexWhere(
                  (s) => s.label == _selectedSection?.label && s.text == _selectedSection?.text);
              final idx = (cur <= 0) ? sections.length - 1 : cur - 1;
              setState(() => _selectedSection = sections[idx]);
            },
            onNext: sections.isEmpty ? null : () {
              final cur = sections.indexWhere(
                  (s) => s.label == _selectedSection?.label && s.text == _selectedSection?.text);
              final idx = (cur < 0 || cur >= sections.length - 1) ? 0 : cur + 1;
              setState(() => _selectedSection = sections[idx]);
            },
          ),
        ],
      ),
    );
  }

  // ── Shared prev/next nav bar for both overview panels ─────────────────────
  Widget _buildOverviewNavBar({
    required Color accent,
    required VoidCallback? onPrev,
    required VoidCallback? onNext,
    Widget? extraButton,
  }) {
    final t = context.t;
    return Container(
      height: 34,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.border)),
        color: t.surfaceHigh,
      ),
      child: Row(
        children: [
          if (extraButton != null) ...[
            const SizedBox(width: 4),
            extraButton,
          ],
          const Spacer(),
          // Prev button
          _NavBtn(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Previous',
            accent: accent,
            enabled: onPrev != null,
            onTap: onPrev ?? () {},
          ),
          const SizedBox(width: 2),
          // Next button
          _NavBtn(
            icon: Icons.chevron_right_rounded,
            tooltip: 'Next',
            accent: accent,
            enabled: onNext != null,
            onTap: onNext ?? () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ── Build the collapsed verse row list (shared by overview + nav) ──────────
  List<({int startVerse, int endVerse, String text})> _buildVerseRows() {
    final rows = <({int startVerse, int endVerse, String text})>[];
    int i = 0;
    while (i < _verseList.length) {
      final raw   = (_verseList[i]['text'] as String?) ?? '';
      final plain = ScriptureQueueItem.toPlain(raw);
      final startNum = _verseList[i]['verse'] as int;
      if (plain.isEmpty) { i++; continue; }
      int endNum = startNum;
      int j = i + 1;
      while (j < _verseList.length) {
        final nxt = ScriptureQueueItem.toPlain(
            (_verseList[j]['text'] as String?) ?? '');
        if (nxt.isNotEmpty) break;
        endNum = _verseList[j]['verse'] as int;
        j++;
      }
      rows.add((startVerse: startNum, endVerse: endNum, text: plain));
      i = j;
    }
    return rows;
  }

  // ── Song editor dialog ─────────────────────────────────────────────────────
  void _showSongEditorDialog(Map<String, String>? existingSong) {
    final titleCtrl  = TextEditingController(text: existingSong?['title']  ?? '');
    final artistCtrl = TextEditingController(text: existingSong?['artist'] ?? '');

    // Parse existing sections or start with one blank verse
    final sections = existingSong != null
        ? parseSongSections(existingSong['lyrics'] ?? '')
        : [SongSection(label: 'Verse 1', text: '')];

    // Each section gets its own controllers
    final labelCtrls = sections.map((s) => TextEditingController(text: s.label)).toList();
    final textCtrls  = sections.map((s) => TextEditingController(text: s.text)).toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDlg) {
          final t = context.t;

          void addSection(String label) {
            setDlg(() {
              labelCtrls.add(TextEditingController(text: label));
              textCtrls.add(TextEditingController());
            });
          }

          void removeSection(int i) {
            setDlg(() {
              labelCtrls.removeAt(i);
              textCtrls.removeAt(i);
            });
          }

          void save() {
            if (titleCtrl.text.trim().isEmpty) return;
            // Build lyrics string from sections
            final buf = StringBuffer();
            for (int i = 0; i < labelCtrls.length; i++) {
              final lbl  = labelCtrls[i].text.trim();
              final body = textCtrls[i].text.trim();
              if (lbl.isNotEmpty) buf.writeln('[$lbl]');
              if (body.isNotEmpty) buf.write(body);
              if (i < labelCtrls.length - 1) buf.write('\n');
            }
            final newSong = {
              'title':  titleCtrl.text.trim(),
              'artist': artistCtrl.text.trim(),
              'lyrics': buf.toString(),
            };
            setState(() {
              if (existingSong != null) {
                final idx = _songs.indexOf(existingSong);
                if (idx >= 0) _songs[idx] = newSong;
              } else {
                _songs.add(newSong);
              }
              _filteredSongs = _songs;
              _selectedSong  = newSong;
              _selectedSection = null;
            });
            Navigator.pop(ctx);
          }

          return AlertDialog(
            backgroundColor: t.surface,
            title: Text(
              existingSong != null ? 'Edit Song' : 'Add Song',
              style: TextStyle(color: t.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title + Artist row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _DlgField(ctrl: titleCtrl,  label: 'Song title',  t: t),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _DlgField(ctrl: artistCtrl, label: 'Artist / Author', t: t),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Section list
                    for (int i = 0; i < labelCtrls.length; i++) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section label
                          SizedBox(
                            width: 110,
                            child: _DlgField(ctrl: labelCtrls[i], label: 'Label', t: t),
                          ),
                          const SizedBox(width: 8),
                          // Section lyrics
                          Expanded(
                            child: _DlgField(
                              ctrl: textCtrls[i],
                              label: 'Lyrics',
                              t: t,
                              maxLines: 5,
                            ),
                          ),
                          // Remove button
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline_rounded,
                                size: 18, color: t.textMuted),
                            onPressed: labelCtrls.length > 1
                                ? () => removeSection(i)
                                : null,
                            tooltip: 'Remove section',
                            padding: const EdgeInsets.only(top: 8),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Quick-add section buttons
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final lbl in ['Verse', 'Chorus', 'Bridge', 'Pre-Chorus', 'Outro', 'Intro'])
                          ActionChip(
                            label: Text('+ $lbl',
                                style: TextStyle(fontSize: 11, color: t.textSecondary)),
                            backgroundColor: t.surfaceHigh,
                            side: BorderSide(color: t.border),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            onPressed: () {
                              // Auto-number Verses
                              String label = lbl;
                              if (lbl == 'Verse') {
                                final count = labelCtrls
                                    .where((c) => c.text.startsWith('Verse'))
                                    .length;
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
                      ],
                    ),
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
                onPressed: save,
                style: FilledButton.styleFrom(backgroundColor: t.accentPurple),
                child: Text(existingSong != null ? 'Save' : 'Add Song'),
              ),
            ],
          );
        });
      },
    );
  }


  Widget _buildOverviewVerseRow({
    required int verseNum,
    int? endVerseNum,         // non-null when MSG combines e.g. v16–18
    required String verseText,
  }) {
    final t = context.t;
    final bool isFrom = verseNum == _pickerFromVerse;
    final bool isTo = verseNum == _pickerToVerse ||
        (endVerseNum != null && endVerseNum == _pickerToVerse);
    final bool isEdge = isFrom || isTo;
    final bool inRange = _pickerFromVerse != null &&
        _pickerToVerse != null &&
        verseNum >= _pickerFromVerse! &&
        (endVerseNum ?? verseNum) <= _pickerToVerse!;
    final bool isSingle = isFrom && _pickerFromVerse == _pickerToVerse;

    final displayLabel = (endVerseNum != null && endVerseNum > verseNum)
        ? '$verseNum–$endVerseNum'
        : '$verseNum';

    final Color bg = isEdge || isSingle
        ? t.anchorHighlight
        : inRange
        ? t.rangeHighlight
        : Colors.transparent;

    return InkWell(
      // Single tap → update From & To pickers (highlights, does NOT display)
      onTap: () {
        setState(() {
          _pickerFromVerse = verseNum;
          _pickerToVerse = endVerseNum ?? verseNum;
        });
      },
      // Double tap → queue and display immediately
      onDoubleTap: () {
        setState(() {
          _pickerFromVerse = verseNum;
          _pickerToVerse = endVerseNum ?? verseNum;
        });
        _addPickerSelectionToQueue();
      },
      hoverColor: t.accentBlue.withValues(alpha: 0.05),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            left: BorderSide(
              color: isEdge || inRange || isSingle
                  ? t.accentBlue
                  : Colors.transparent,
              width: 3,
            ),
            bottom: BorderSide(color: t.border, width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verse number / range badge
            SizedBox(
              width: 32,
              child: Text(
                displayLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isEdge || inRange || isSingle
                      ? t.accentBlue
                      : t.textMuted,
                ),
              ),
            ),
            // Verse text snippet
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    verseText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: isEdge || inRange || isSingle
                          ? t.textPrimary
                          : t.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // FROM / TO badges
            if (isFrom && !isSingle)
              _RangeBadge(label: 'FROM', color: t.accentBlue),
            if (isTo && !isSingle)
              _RangeBadge(label: 'TO', color: t.accentBlue),
          ],
        ),
      ),
    );
  }

  /// Auto-scroll the overview panel so the FROM verse is visible near the top.
  void _scrollOverviewToSelection() {
    if (!_verseOverviewScroll.hasClients || _pickerFromVerse == null) return;
    final idx = _verseList.indexWhere(
      (v) => (v['verse'] as int) == _pickerFromVerse,
    );
    if (idx < 0) return;
    final offset = (idx * _kVerseRowHeight - 40).clamp(
      0.0,
      _verseOverviewScroll.position.maxScrollExtent,
    );
    _verseOverviewScroll.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Widget _buildScripturePreview(ScriptureQueueItem item) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewHeader(
            title: item.reference,
            subtitle: item.version.fullName,
            accent: context.t.accentBlue,
            badgeLabel: item.version.abbreviation,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _PreviewTextCard(
              richText: item.buildRichText,
              textAlign: TextAlign.left,
            ),
          ),
          _buildGoLiveBar(accent: context.t.accentBlue),
        ],
      ),
    );
  }

  Widget _buildSongPreview(Map<String, String> song) {
    final sectionLabel = song['_sectionLabel'];
    final subtitle = sectionLabel != null && sectionLabel.isNotEmpty
        ? '$sectionLabel  ·  ${song['artist'] ?? ''}'
        : 'by ${song['artist'] ?? 'Unknown'}';
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewHeader(
            title: song['title'] ?? '',
            subtitle: subtitle,
            accent: context.t.accentPurple,
            badgeLabel: sectionLabel != null && sectionLabel.isNotEmpty
                ? sectionLabel.toUpperCase()
                : 'LYRICS',
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _PreviewTextCard(
              text: song['lyrics'] ?? '',
              textAlign: TextAlign.center,
            ),
          ),
          _buildGoLiveBar(accent: context.t.accentPurple),
        ],
      ),
    );
  }

  Widget _buildAnnouncementPreview(ServiceItem item) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewHeader(
            title: item.announcementTitle?.isNotEmpty == true
                ? item.announcementTitle!
                : 'Announcement',
            subtitle: 'Custom slide',
            accent: const Color(0xFFE6A817),
            badgeLabel: 'ANNOUNCE',
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _PreviewTextCard(
              text: item.announcementText ?? '',
              textAlign: TextAlign.center,
            ),
          ),
          _buildGoLiveBar(accent: const Color(0xFFE6A817)),
        ],
      ),
    );
  }

  Widget _buildLogoPreview() {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          _PreviewHeader(
            title: 'Church Logo',
            subtitle: 'Branded slide',
            accent: const Color(0xFF4CAF50),
            badgeLabel: 'LOGO',
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: t.border),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.church_rounded, size: 64, color: Colors.white.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'CHURCH LOGO',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.2),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your logo image in settings',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildGoLiveBar(accent: const Color(0xFF4CAF50)),
        ],
      ),
    );
  }

  Widget _buildBlackPreview() {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          _PreviewHeader(
            title: 'Black Screen',
            subtitle: 'Clear projector output',
            accent: const Color(0xFF777777),
            badgeLabel: 'BLACK',
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: t.border),
              ),
            ),
          ),
          _buildGoLiveBar(accent: const Color(0xFF777777)),
        ],
      ),
    );
  }

  /// Action bar shown below the preview — Go Live + Clear buttons.
  Widget _buildGoLiveBar({bool? isScripture, Color? accent}) {
    final t = context.t;
    final a = accent ??
        (isScripture == true ? t.accentBlue : t.accentPurple);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          // Go Live button — opens/updates the projector window
          Expanded(
            child: FilledButton.icon(
              onPressed: _goLive,
              style: FilledButton.styleFrom(
                backgroundColor: a,
                foregroundColor: t.isDark ? t.appBg : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.cast_rounded, size: 17),
              label: const Text(
                'Go Live',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Clear projector — blanks the screen
          OutlinedButton.icon(
            onPressed: _clearProjector,
            style: OutlinedButton.styleFrom(
              foregroundColor: t.textSecondary,
              side: BorderSide(color: t.border),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.stop_screen_share_rounded, size: 16),
            label: const Text(
              'Clear',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.t.surface,
              shape: BoxShape.circle,
              border: Border.all(color: context.t.border),
            ),
            child: Icon(
              Icons.church_rounded,
              size: 52,
              color: context.t.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Church Presentation',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: context.t.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a verse or song to begin',
            style: TextStyle(fontSize: 14, color: context.t.textSecondary),
          ),
          const SizedBox(height: 36),
          Container(
            width: 380,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.t.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.t.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GETTING STARTED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: context.t.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                _TipRow(
                  icon: Icons.menu_book_rounded,
                  color: context.t.accentBlue,
                  text: 'Pick a version from the Bible Versions list on the left',
                ),
                _TipRow(
                  icon: Icons.search_rounded,
                  color: context.t.accentBlue,
                  text:
                      'Type Jn 3:16, rev12:1, ps119:65-88 or even a typo — it figures it out',
                ),
                _TipRow(
                  icon: Icons.tune_rounded,
                  color: context.t.accentBlue,
                  text:
                      'Use the Book, Chapter, From & To dropdowns to pick any passage in seconds',
                ),
                _TipRow(
                  icon: Icons.touch_app_rounded,
                  color: context.t.accentBlue,
                  text:
                      'Single-tap a verse in the overview to highlight it — double-tap to display',
                ),
                _TipRow(
                  icon: Icons.playlist_add_rounded,
                  color: context.t.accentBlue,
                  text: 'Hit Add to queue passages in service order',
                ),
                _TipRow(
                  icon: Icons.music_note_rounded,
                  color: context.t.accentPurple,
                  text: 'Double-tap a song to display its lyrics',
                  bottomPad: 0,
                ),
              ],
            ),
          ),
        ],
        ),
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
      // Reverse map: number → name (so we can remap _selectedBook after switch)
      final Map<int, String> byNumber = {
        for (final r in bookRows)
          r['book_number'] as int: r['long_name'] as String,
      };

      // Step 5 — Re-query verses using the STABLE book_number, not the name.
      //          This is what fixes NKJV whose long_names differ from every
      //          other version (e.g. "The First Book of Moses Called GENESIS").
      final int? currentBookNum = _selectedBookNumber;
      final int? currentChapter = _selectedChapter;
      List<Map<String, dynamic>> newVerseList = [];
      // The display name for _selectedBook in the new version
      String? remappedBookName =
          currentBookNum != null ? byNumber[currentBookNum] : null;

      if (currentBookNum != null && currentChapter != null) {
        try {
          final verseRows = db.select(
            'SELECT verse, text FROM verses '
            'WHERE book_number = ? AND chapter = ? ORDER BY verse',
            [currentBookNum, currentChapter],
          );
          newVerseList = verseRows
              .map((r) => {'verse': r['verse'], 'text': r['text']})
              .toList();
        } catch (e) {
          debugPrint('❌ Re-query verses on switch: $e');
        }
      }

      setState(() {
        _database = db;
        _activeVersion = version;
        _bibleBooks = books;
        _bookNumberMap
          ..clear()
          ..addAll(bookMap);
        _bookByNumber
          ..clear()
          ..addAll(byNumber);

        // Remap _selectedBook to whatever this version calls the same book
        if (remappedBookName != null) _selectedBook = remappedBookName;

        // Verse list refreshed with new translation text
        _verseList = newVerseList;

        _versionLoading = false;
        _initialLoadDone = true;
      });

      // After the new verse list is rendered, scroll the overview panel
      // back to the user's selected range (same as after a search-bar jump).
      if (_pickerFromVerse != null) {
        Future.delayed(
          const Duration(milliseconds: 120),
          _scrollOverviewToSelection,
        );
      }
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
        _selectedBookNumber = bookNumber; // stable cross-version identity
        _chapters = rows.map((r) => r['chapter'] as int).toList();
        _selectedChapter = null;
        _verseList = [];
        _pickerFromVerse = null;
        _pickerToVerse = null;
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
        // Auto-default picker: From = first verse, To = last verse
        if (_verseList.isNotEmpty) {
          _pickerFromVerse = _verseList.first['verse'] as int;
          _pickerToVerse = _verseList.last['verse'] as int;
        } else {
          _pickerFromVerse = null;
          _pickerToVerse = null;
        }
      });
    } catch (e) {
      debugPrint('❌ Verses error: $e');
    }
  }

  // ── Queue (picker-driven) ──────────────────────────────────────────────────

  /// Called by the Add button in the passage picker.
  /// Reads _pickerFromVerse / _pickerToVerse and builds a ScriptureQueueItem.
  void _addPickerSelectionToQueue() {
    if (_selectedBook == null ||
        _selectedChapter == null ||
        _pickerFromVerse == null ||
        _pickerToVerse == null) { return; }

    final int start = _pickerFromVerse!;
    final int end = _pickerToVerse!;

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
      version: _activeVersion,
    );

    setState(() {
      final si = ServiceItem(type: ServiceItemType.scripture, scriptureItem: item);
      _plan.add(si);
      _activeIndex = _plan.length - 1;
    });
    _autoSavePlan();
  }

  // ── Service plan item management ────────────────────────────────────────────

  void _selectPlanItem(int index) {
    setState(() => _activeIndex = index);
    _scrollPlanToIndex(index);
  }

  void _removePlanItem(int index) {
    setState(() {
      _plan.removeAt(index);
      if (_activeIndex >= _plan.length) {
        _activeIndex = _plan.length - 1;
      }
    });
    _autoSavePlan();
  }

  void _stepForward() {
    if (_activeIndex < _plan.length - 1) {
      setState(() => _activeIndex++);
      _scrollPlanToIndex(_activeIndex);
    }
  }

  void _stepBack() {
    if (_activeIndex > 0) {
      setState(() => _activeIndex--);
      _scrollPlanToIndex(_activeIndex);
    }
  }

  void _addBlackScreen() {
    setState(() {
      _plan.add(ServiceItem(type: ServiceItemType.black));
      _activeIndex = _plan.length - 1;
    });
    _autoSavePlan();
  }

  void _addLogoSlide() {
    setState(() {
      _plan.add(ServiceItem(type: ServiceItemType.logo));
      _activeIndex = _plan.length - 1;
    });
    _autoSavePlan();
  }

  void _confirmClearPlan() {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear service plan?'),
        content: const Text('This will remove all items. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() { _plan.clear(); _activeIndex = -1; });
        _autoSavePlan();
      }
    });
  }

  void _showAnnouncementDialog() {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
                hintText: 'e.g. Sunday School',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Announcement text',
                hintText: 'Enter text to display on screen',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (bodyCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _plan.add(ServiceItem(
                    type: ServiceItemType.announcement,
                    announcementTitle: titleCtrl.text.trim(),
                    announcementText: bodyCtrl.text.trim(),
                  ));
                  _activeIndex = _plan.length - 1;
                });
                _autoSavePlan();
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _scrollPlanToIndex(int index) {
    if (!_planScroll.hasClients) return;
    const rowH = 52.0;
    _planScroll.animateTo(
      (index * rowH).clamp(0.0, _planScroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  // ── Projector output ────────────────────────────────────────────────────────

  bool _projectorOpen = false;

  void _goLive() {
    if (_activeItem == null) return;
    final item = _activeItem!;

    // For black screen items, just clear the projector
    if (item.type == ServiceItemType.black) {
      _clearProjector();
      return;
    }

    if (!_projectorOpen) {
      setState(() => _projectorOpen = true);
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: true,
          barrierColor: Colors.black,
          pageBuilder: (_, _, _) => ProjectorScreen(
            queueItem: _activeQueueItem,
            song: _activeSong,
            announcement: item.type == ServiceItemType.announcement ? item : null,
            showLogo: item.type == ServiceItemType.logo,
          ),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ).then((_) => setState(() => _projectorOpen = false));
    } else {
      ProjectorNotifier.instance.update(
        queueItem: _activeQueueItem,
        song: _activeSong,
        announcement: item.type == ServiceItemType.announcement ? item : null,
        showLogo: item.type == ServiceItemType.logo,
      );
    }
  }

  void _clearProjector() {
    ProjectorNotifier.instance.clear();
  }

  // ── Keyboard navigation ─────────────────────────────────────────────────────

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowDown) {
      _stepForward();
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp) {
      _stepBack();
    } else if (key == LogicalKeyboardKey.space) {
      _goLive();
    } else if (key == LogicalKeyboardKey.keyB) {
      _clearProjector();
    }
  }

  // ── Auto-save / restore ─────────────────────────────────────────────────────

  Future<String> get _savePath async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/ChurchPresenter');
    if (!folder.existsSync()) folder.createSync(recursive: true);
    return '${folder.path}/$_kAutoSaveFileName';
  }

  Future<void> _autoSavePlan() async {
    try {
      final path = await _savePath;
      final data = {
        'savedAt': DateTime.now().toIso8601String(),
        'activeIndex': _activeIndex,
        'items': _plan.map((e) => e.toJson()).toList(),
      };
      await File(path).writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Auto-save failed: $e');
    }
  }

  Future<void> _loadServicePlan() async {
    try {
      final path = await _savePath;
      final file = File(path);
      if (!file.existsSync()) return;
      final raw = await file.readAsString();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((e) => ServiceItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .whereType<ServiceItem>()
          .toList();
      if (items.isEmpty) return;
      final savedAt = DateTime.tryParse(data['savedAt'] as String? ?? '');
      if (!mounted) return;
      // Offer to restore if saved within the last 7 days
      if (savedAt != null &&
          DateTime.now().difference(savedAt).inDays <= 7) {
        final restore = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Restore service plan?'),
            content: Text(
              'Found a saved service plan from '
              '${savedAt.day}/${savedAt.month}/${savedAt.year} '
              'with ${items.length} item${items.length == 1 ? '' : 's'}.\n\n'
              'Would you like to restore it?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Start fresh'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Restore'),
              ),
            ],
          ),
        );
        if (restore == true && mounted) {
          setState(() {
            _plan.addAll(items);
            _activeIndex = data['activeIndex'] as int? ?? -1;
          });
        }
      }
    } catch (e) {
      debugPrint('Load service plan failed: $e');
    }
  }

  // ── Quick-jump ─────────────────────────────────────────────────────────────

  // ── Search bar → picker navigation ────────────────────────────────────────
  //
  // Handles every level of specificity so operators can type as much or as
  // little as they know:
  //
  //   "John"           → selects book John in the Book picker
  //   "John 3"         → selects book + chapter
  //   "John 3:16"      → selects book + chapter + sets From=16 To=16
  //   "ps 119:65-88"   → selects all four pickers, auto-scrolls to v.65
  //   "jn3:16"         → same, without spaces
  //
  // After navigation the verse overview auto-scrolls to the selection.
  void _parseAndJumpToReference(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;

    // ── Normalise: insert space between book letters and chapter number ────────
    // "rev12:1" → "rev 12:1",  "1cor3:16" → "1cor 3:16"
    String normalised = trimmed;

    // "rev 12 1"  (space instead of colon, three tokens) → "rev 12:1"
    final sp = normalised.split(RegExp(r'\s+'));
    if (!normalised.contains(':') && sp.length == 3) {
      final c = int.tryParse(sp[sp.length - 2]);
      final v = int.tryParse(sp[sp.length - 1]);
      if (c != null && v != null) {
        normalised = '${sp.sublist(0, sp.length - 2).join(' ')} $c:$v';
      }
    }

    // glued "rev12:1" → "rev 12:1"
    normalised = normalised.replaceFirstMapped(
      RegExp(r'^(\d?[a-zA-Z\s]+?)(\d)'),
      (m) => '${m[1]} ${m[2]}',
    );

    final ref = normalised.trim();
    final tokens = ref.split(RegExp(r'\s+'));

    // ── Resolve book name (try longest candidate first) ───────────────────────
    String matchedBook = '';
    int afterIdx = 0;

    // First try ALL tokens as a book-only query (e.g. "John" with no chapter)
    final fullCandidate = _BookAliasResolver.resolve(tokens.join(' '), _bibleBooks);
    if (fullCandidate.isNotEmpty) {
      matchedBook = fullCandidate;
      afterIdx = tokens.length; // nothing left after the book name
    } else {
      for (int len = tokens.length - 1; len > 0; len--) {
        final candidate = tokens.sublist(0, len).join(' ');
        final resolved = _BookAliasResolver.resolve(candidate, _bibleBooks);
        if (resolved.isNotEmpty) {
          matchedBook = resolved;
          afterIdx = len;
          break;
        }
      }
    }

    if (matchedBook.isEmpty) return;

    // ── Parse chapter[:verse[-verse]] from remaining tokens ───────────────────
    final cvRaw = tokens.sublist(afterIdx).join('').replaceAll(' ', '');
    final colonIdx = cvRaw.indexOf(':');
    int? chapter;
    int? startVerse;
    int? endVerse;

    if (cvRaw.isNotEmpty) {
      if (colonIdx == -1) {
        chapter = int.tryParse(cvRaw);
      } else {
        chapter = int.tryParse(cvRaw.substring(0, colonIdx));
        final vPart = cvRaw.substring(colonIdx + 1);
        final vTokens = vPart.split(RegExp(r'[\u2013\-]'));
        startVerse = int.tryParse(vTokens[0]);
        endVerse = vTokens.length > 1 ? int.tryParse(vTokens[1]) : startVerse;
      }
    }

    // ── Navigate ──────────────────────────────────────────────────────────────
    _selectBook(matchedBook);
    _searchController.clear();

    if (chapter == null) return; // book-only: done

    Future.delayed(const Duration(milliseconds: 80), () {
      _selectChapter(chapter!);

      if (startVerse == null) return; // chapter-only: done

      Future.delayed(const Duration(milliseconds: 80), () {
        setState(() {
          _pickerFromVerse = startVerse;
          _pickerToVerse = endVerse ?? startVerse;
        });
        // Auto-scroll the verse overview to show the selection
        Future.delayed(const Duration(milliseconds: 60), _scrollOverviewToSelection);
      });
    });
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
}


// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────


// ── _SectionLabel ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.accent});
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.t.border)),
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
    // Guard: value must exist in items, otherwise pass null to avoid assertion crash
    final T? safeValue = (value != null && items.contains(value)) ? value : null;

    return DropdownButtonFormField<T>(
      initialValue: safeValue,
      onChanged: onChanged,
      isExpanded: true,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 18,
        color: context.t.textMuted,
      ),
      dropdownColor: context.t.surfaceHigh,
      style: TextStyle(fontSize: 13, color: context.t.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12, color: context.t.textMuted),
        isDense: true,
        filled: true,
        fillColor: context.t.appBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.t.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.t.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.t.accentBlue, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: context.t.border.withValues(alpha: 0.4),
          ),
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
        color: context.t.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.t.border),
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
                  style: TextStyle(
                    fontSize: 12,
                    color: context.t.textSecondary,
                  ),
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
  /// For scripture — rich text with italic/bold markup rendered.
  const _PreviewTextCard({
    this.text,
    this.richText,
    required this.textAlign,
    this.fontSize = 26,
  }) : assert(text != null || richText != null);

  /// Plain string — used for song lyrics.
  final String? text;

  /// Rich-text builder — used for scripture (italic, bold, etc.).
  /// Receives the base [TextStyle] and returns a [TextSpan].
  final TextSpan Function(TextStyle base)? richText;

  final TextAlign textAlign;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final base = TextStyle(
      fontSize: fontSize,
      height: 1.85,
      color: t.textPrimary,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    );

    final child = richText != null
        ? RichText(
            text: richText!(base),
            textAlign: textAlign,
          )
        : Text(
            text!,
            textAlign: textAlign,
            style: base,
          );

    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.border, width: t.isDark ? 1 : 1.5),
        boxShadow: t.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: SingleChildScrollView(child: child),
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
              style: TextStyle(
                fontSize: 12,
                color: context.t.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAN QUICK BUTTON  — small pill button for the service plan header
// ─────────────────────────────────────────────────────────────────────────────

class _PlanQuickButton extends StatelessWidget {
  const _PlanQuickButton({
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
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Prev / Next nav button ─────────────────────────────────────────────────────
class _NavBtn extends StatefulWidget {
  const _NavBtn({
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
  State<_NavBtn> createState() => _NavBtnState();
}

class _NavBtnState extends State<_NavBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: 56,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered && widget.enabled
                  ? widget.accent.withValues(alpha: 0.15)
                  : Colors.transparent,
            ),
            child: Icon(
              widget.icon,
              size: 20,
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

// ── Dialog text field helper ───────────────────────────────────────────────────
class _DlgField extends StatelessWidget {
  const _DlgField({
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
        filled: true,
        fillColor: t.appBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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