import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;
import 'dart:io';
import 'package:flutter/services.dart';
import '../app_theme.dart';

const double kPanelWidth = 340.0;

// ── Convenience extension ─────────────────────────────────────────────────────
// Lets any widget write `context.t` instead of `AppTheme.of(context)`.
extension _ThemeX on BuildContext {
  AppTheme get t => AppTheme.of(this);
}

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
  /// HTML tags (e.g. <pb/>, <n>…</n>, <i>…</i> from the AMP) are stripped.
  String get fullText =>
      verses.map((v) => '${v['verse']}  ${_stripHtml(v['text'] as String? ?? '')}').join('\n\n');

  /// Strip XML/HTML tags and decode common entities from Bible DB text.
  static String _stripHtml(String raw) {
    // Remove all tags like <pb/>, <n>, </n>, <i>, <br>, etc.
    String s = raw.replaceAll(RegExp(r'<[^>]*>'), '');
    // Decode common HTML entities
    s = s
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
    // Collapse multiple spaces / trim
    return s.replaceAll(RegExp(r'  +'), ' ').trim();
  }
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

  String? _selectedBook;
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
    _verseOverviewScroll.dispose();
    _database?.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (!_initialLoadDone) return _buildFullScreenLoader();

    return Row(
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

        // ── Col 2: Chapter verse overview — always visible (fixed 240px) ─────
        SizedBox(
          width: 240,
          child: _buildChapterOverviewPanel(),
        ),

        VerticalDivider(width: 1, color: context.t.border),

        // ── Col 3: Main display — scripture/song preview or welcome ──────────
        Expanded(
          child: Container(
            color: context.t.appBg,
            child: _buildDisplaySection(),
          ),
        ),
      ],
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
        if (_queue.isNotEmpty) _buildQueueStrip(),
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

  Widget _buildQueueStrip() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: context.t.appBg,
        border: Border(top: BorderSide(color: context.t.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 5, 12, 0),
            child: Text(
              'QUEUE  ·  ${_queue.length} item${_queue.length == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: context.t.textMuted,
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
        _SectionLabel(label: 'SONGS', accent: context.t.accentPurple),

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
                    final isActive = _activeSong == song;
                    return InkWell(
                      onDoubleTap: () => setState(() => _activeSong = song),
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
                          color: isActive
                              ? context.t.accentPurple.withValues(alpha: 0.1)
                              : Colors.transparent,
                          border: isActive
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
                                color: isActive
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
    if (_activeQueueItem == null && _activeSong == null) {
      return _buildWelcomeScreen();
    }
    return _activeQueueItem != null
        ? _buildScripturePreview(_activeQueueItem!)
        : _buildSongPreview(_activeSong!);
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
                : ListView.builder(
                    controller: _verseOverviewScroll,
                    padding: EdgeInsets.zero,
                    itemCount: _verseList.length,
                    itemExtent: _kVerseRowHeight,
                    itemBuilder: (context, index) {
                      final verseNum =
                          _verseList[index]['verse'] as int;
                      final verseText = ScriptureQueueItem._stripHtml(
                  (_verseList[index]['text'] as String?) ?? '');
                      return _buildOverviewVerseRow(
                        verseNum: verseNum,
                        verseText: verseText,
                      );
                    },
                  ),
          ),

          // ── Footer hint ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: t.border)),
              color: t.surfaceHigh,
            ),
            child: Text(
              'Single tap to select  ·  Double tap to display',
              style: TextStyle(fontSize: 9, color: t.textMuted),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewVerseRow({
    required int verseNum,
    required String verseText,
  }) {
    final t = context.t;
    final bool isFrom = verseNum == _pickerFromVerse;
    final bool isTo = verseNum == _pickerToVerse;
    final bool isEdge = isFrom || isTo;
    final bool inRange = _pickerFromVerse != null &&
        _pickerToVerse != null &&
        verseNum >= _pickerFromVerse! &&
        verseNum <= _pickerToVerse!;
    final bool isSingle = isFrom && _pickerFromVerse == _pickerToVerse;

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
          _pickerToVerse = verseNum;
        });
      },
      // Double tap → queue and display immediately
      onDoubleTap: () {
        setState(() {
          _pickerFromVerse = verseNum;
          _pickerToVerse = verseNum;
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
            // Verse number badge
            SizedBox(
              width: 24,
              child: Text(
                '$verseNum',
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
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewHeader(
            title: item.reference,
            // Show full version name in the subtitle
            subtitle: item.version.fullName,
            accent: context.t.accentBlue,
            // Show abbreviation in the badge
            badgeLabel: item.version.abbreviation,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _PreviewTextCard(
              text: item.fullText,
              textAlign: TextAlign.left,
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
            accent: context.t.accentPurple,
            badgeLabel: 'LYRICS',
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _PreviewTextCard(
              text: song['lyrics'] ?? '',
              textAlign: TextAlign.center,
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
          Container(width: 24, height: 1, color: context.t.border),
          const SizedBox(width: 10),
          Text(
            'Church Presentation Software',
            style: TextStyle(fontSize: 11, color: context.t.textMuted),
          ),
          const SizedBox(width: 10),
          Container(width: 24, height: 1, color: context.t.border),
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
        // _selectedBook, _selectedChapter, _chapters all stay as they were.
        // Only the verse *text* is refreshed
        // because it comes from the new translation.
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
      _queue.add(item);
      _activeQueueItem = item;
      _activeSong = null;
    });
  }

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
          color: isActive
              ? context.t.accentBlue.withValues(alpha: 0.15)
              : context.t.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? context.t.accentBlue.withValues(alpha: 0.5)
                : context.t.border,
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
                    color: isActive
                        ? context.t.accentBlue
                        : context.t.textPrimary,
                  ),
                ),
                // Show which version this card came from
                Text(
                  item.version.abbreviation,
                  style: TextStyle(
                    fontSize: 9,
                    color: isActive
                        ? context.t.accentBlue.withValues(alpha: 0.7)
                        : context.t.textMuted,
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
                color: isActive ? context.t.accentBlue : context.t.textMuted,
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
  const _PreviewTextCard({
    required this.text,
    required this.textAlign,
    this.fontSize = 26,
  });

  final String text;
  final TextAlign textAlign;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
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
      child: SingleChildScrollView(
        child: Text(
          text,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: fontSize,
            height: 1.85,
            color: t.textPrimary,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
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