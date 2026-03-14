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
// ─────────────────────────────────────────────────────────────────────────────

class _BookAliasResolver {
  static const Map<String, String> _aliases = {
    'gen': 'Genesis',
    'ge': 'Genesis',
    'gn': 'Genesis',
    'exo': 'Exodus',
    'ex': 'Exodus',
    'exod': 'Exodus',
    'lev': 'Leviticus',
    'le': 'Leviticus',
    'lv': 'Leviticus',
    'num': 'Numbers',
    'nu': 'Numbers',
    'nm': 'Numbers',
    'nb': 'Numbers',
    'deu': 'Deuteronomy',
    'deut': 'Deuteronomy',
    'dt': 'Deuteronomy',
    'de': 'Deuteronomy',
    'jos': 'Joshua',
    'josh': 'Joshua',
    'jsh': 'Joshua',
    'jdg': 'Judges',
    'judg': 'Judges',
    'jg': 'Judges',
    'jgs': 'Judges',
    'rut': 'Ruth',
    'ru': 'Ruth',
    '1sa': '1 Samuel',
    '1sam': '1 Samuel',
    '1s': '1 Samuel',
    'i sam': '1 Samuel',
    'i samuel': '1 Samuel',
    '1samuel': '1 Samuel',
    '2sa': '2 Samuel',
    '2sam': '2 Samuel',
    '2s': '2 Samuel',
    'ii sam': '2 Samuel',
    'ii samuel': '2 Samuel',
    '2samuel': '2 Samuel',
    '1ki': '1 Kings',
    '1kgs': '1 Kings',
    '1k': '1 Kings',
    'i kings': '1 Kings',
    'i ki': '1 Kings',
    '1kings': '1 Kings',
    '2ki': '2 Kings',
    '2kgs': '2 Kings',
    '2k': '2 Kings',
    'ii kings': '2 Kings',
    '2kings': '2 Kings',
    '1ch': '1 Chronicles',
    '1chr': '1 Chronicles',
    '1chron': '1 Chronicles',
    'i chron': '1 Chronicles',
    '1chronicles': '1 Chronicles',
    '2ch': '2 Chronicles',
    '2chr': '2 Chronicles',
    '2chron': '2 Chronicles',
    'ii chron': '2 Chronicles',
    '2chronicles': '2 Chronicles',
    'ezr': 'Ezra',
    'ez': 'Ezra',
    'neh': 'Nehemiah',
    'ne': 'Nehemiah',
    'est': 'Esther',
    'esth': 'Esther',
    'es': 'Esther',
    'jb': 'Job',
    'psa': 'Psalms',
    'ps': 'Psalms',
    'psalm': 'Psalms',
    'pss': 'Psalms',
    'pro': 'Proverbs',
    'prov': 'Proverbs',
    'prv': 'Proverbs',
    'pr': 'Proverbs',
    'ecc': 'Ecclesiastes',
    'eccl': 'Ecclesiastes',
    'qoh': 'Ecclesiastes',
    'ec': 'Ecclesiastes',
    'sos': 'Song of Solomon',
    'sol': 'Song of Solomon',
    'song': 'Song of Solomon',
    'ss': 'Song of Solomon',
    'sng': 'Song of Solomon',
    'sg': 'Song of Solomon',
    'song of songs': 'Song of Solomon',
    'canticles': 'Song of Solomon',
    'isa': 'Isaiah',
    'is': 'Isaiah',
    'jer': 'Jeremiah',
    'je': 'Jeremiah',
    'jr': 'Jeremiah',
    'lam': 'Lamentations',
    'la': 'Lamentations',
    'eze': 'Ezekiel',
    'ezek': 'Ezekiel',
    'ezk': 'Ezekiel',
    'dan': 'Daniel',
    'da': 'Daniel',
    'dn': 'Daniel',
    'hos': 'Hosea',
    'ho': 'Hosea',
    'joe': 'Joel',
    'jl': 'Joel',
    'amo': 'Amos',
    'am': 'Amos',
    'oba': 'Obadiah',
    'ob': 'Obadiah',
    'obad': 'Obadiah',
    'jon': 'Jonah',
    'jnh': 'Jonah',
    'mic': 'Micah',
    'mc': 'Micah',
    'nah': 'Nahum',
    'na': 'Nahum',
    'hab': 'Habakkuk',
    'hb': 'Habakkuk',
    'zep': 'Zephaniah',
    'zeph': 'Zephaniah',
    'zp': 'Zephaniah',
    'hag': 'Haggai',
    'hg': 'Haggai',
    'zec': 'Zechariah',
    'zech': 'Zechariah',
    'zc': 'Zechariah',
    'mal': 'Malachi',
    'ml': 'Malachi',
    'mat': 'Matthew',
    'matt': 'Matthew',
    'mt': 'Matthew',
    'mar': 'Mark',
    'mrk': 'Mark',
    'mk': 'Mark',
    'luk': 'Luke',
    'lk': 'Luke',
    'joh': 'John',
    'jn': 'John',
    'jhn': 'John',
    'act': 'Acts',
    'ac': 'Acts',
    'rom': 'Romans',
    'ro': 'Romans',
    'rm': 'Romans',
    '1co': '1 Corinthians',
    '1cor': '1 Corinthians',
    'i cor': '1 Corinthians',
    '1corinthians': '1 Corinthians',
    '2co': '2 Corinthians',
    '2cor': '2 Corinthians',
    'ii cor': '2 Corinthians',
    '2corinthians': '2 Corinthians',
    'gal': 'Galatians',
    'ga': 'Galatians',
    'eph': 'Ephesians',
    'ep': 'Ephesians',
    'php': 'Philippians',
    'phil': 'Philippians',
    'pp': 'Philippians',
    'phl': 'Philippians',
    'col': 'Colossians',
    'co': 'Colossians',
    '1th': '1 Thessalonians',
    '1thes': '1 Thessalonians',
    '1thess': '1 Thessalonians',
    'i thess': '1 Thessalonians',
    '1thessalonians': '1 Thessalonians',
    '2th': '2 Thessalonians',
    '2thes': '2 Thessalonians',
    '2thess': '2 Thessalonians',
    'ii thess': '2 Thessalonians',
    '2thessalonians': '2 Thessalonians',
    '1ti': '1 Timothy',
    '1tim': '1 Timothy',
    'i tim': '1 Timothy',
    '1timothy': '1 Timothy',
    '2ti': '2 Timothy',
    '2tim': '2 Timothy',
    'ii tim': '2 Timothy',
    '2timothy': '2 Timothy',
    'tit': 'Titus',
    'ti': 'Titus',
    'phm': 'Philemon',
    'phlm': 'Philemon',
    'phile': 'Philemon',
    'heb': 'Hebrews',
    'he': 'Hebrews',
    'jas': 'James',
    'jm': 'James',
    '1pe': '1 Peter',
    '1pet': '1 Peter',
    '1pt': '1 Peter',
    'i pet': '1 Peter',
    '1peter': '1 Peter',
    '2pe': '2 Peter',
    '2pet': '2 Peter',
    '2pt': '2 Peter',
    'ii pet': '2 Peter',
    '2peter': '2 Peter',
    '1jo': '1 John',
    '1jn': '1 John',
    '1joh': '1 John',
    'i john': '1 John',
    '1john': '1 John',
    '2jo': '2 John',
    '2jn': '2 John',
    '2joh': '2 John',
    'ii john': '2 John',
    '2john': '2 John',
    '3jo': '3 John',
    '3jn': '3 John',
    '3joh': '3 John',
    'iii john': '3 John',
    '3john': '3 John',
    'jud': 'Jude',
    'jude': 'Jude',
    'rev': 'Revelation',
    're': 'Revelation',
    'rv': 'Revelation',
    'apoc': 'Revelation',
    'apocalypse': 'Revelation',
  };

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

  static String resolve(String input, List<String> canonicalBooks) {
    final q = input.trim().toLowerCase();
    if (q.isEmpty) return '';

    for (final b in canonicalBooks) {
      if (b.toLowerCase() == q) return b;
    }

    final aliasHit = _aliases[q];
    if (aliasHit != null) {
      final found = canonicalBooks.firstWhere(
        (b) => b.toLowerCase() == aliasHit.toLowerCase(),
        orElse: () => '',
      );
      if (found.isNotEmpty) return found;
    }

    if (q.length >= 2) {
      final prefixMatches = canonicalBooks
          .where((b) => b.toLowerCase().startsWith(q))
          .toList();
      if (prefixMatches.length == 1) return prefixMatches.first;
    }

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

    for (final entry in _aliases.entries) {
      final d = _lev(q, entry.key);
      if (d < bestDist) {
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
// DROPDOWN COORDINATOR — only one picker overlay open at a time
// ─────────────────────────────────────────────────────────────────────────────

class _DropdownCoordinator extends ChangeNotifier {
  String? _openId;

  /// Request to open [id]. Returns false if [id] was already open (toggle→close).
  bool requestOpen(String id) {
    if (_openId == id) {
      _openId = null;
      notifyListeners();
      return false;
    }
    _openId = id;
    notifyListeners();
    return true;
  }

  void notifyClosed(String id) {
    if (_openId == id) {
      _openId = null;
      notifyListeners();
    }
  }

  bool isOpen(String id) => _openId == id;
}

// ─────────────────────────────────────────────────────────────────────────────
// VERSE SEARCH RESULT
// ─────────────────────────────────────────────────────────────────────────────

class _VerseSearchResult {
  const _VerseSearchResult({
    required this.book,
    required this.bookNumber,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.score,
  });
  final String book;
  final int bookNumber;
  final int chapter;
  final int verse;
  final String text;
  final double score;
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextEditingController _searchController;
  late TextEditingController _songSearchController;

  // ── Live verse-text search ────────────────────────────────────────────────
  final FocusNode _searchFocus = FocusNode();
  final LayerLink _searchBarLink = LayerLink();
  OverlayEntry? _searchOverlay;
  List<_VerseSearchResult> _searchResults = [];

  /// Shared coordinator — ensures only one picker dropdown is open at a time.
  final _DropdownCoordinator _dropdownCoord = _DropdownCoordinator();

  BibleVersion _activeVersion = kBibleVersions.first;
  bool _versionLoading = false;

  Database? _database;
  bool _initialLoadDone = false;

  List<String> _bibleBooks = [];
  final Map<String, int> _bookNumberMap = {};
  final Map<int, String> _bookByNumber = {};

  String? _selectedBook;
  int? _selectedBookNumber;
  List<int> _chapters = [];

  int? _selectedChapter;
  List<Map<String, dynamic>> _verseList = [];

  // ── Range selection — independent of preview highlight ───────────────────
  // Set ONLY via the From/To dropdowns or Shift-click on a verse row.
  // Never cleared when the user taps a verse to preview it.
  int? _rangeFrom;
  int? _rangeTo;

  // Keep old names as getters so existing references still compile
  int? get _pickerFromVerse => _rangeFrom;
  int? get _pickerToVerse => _rangeTo;

  // ── Single-verse preview highlight (blue) — independent of range ──────────
  int?
  _previewVerseNum; // which verse number row has the blue preview highlight

  final ScrollController _verseOverviewScroll = ScrollController();

  static const double _kVerseRowHeight = 64.0;

  Map<String, String>? _selectedSong;
  SongSection? _selectedSection;

  /// A single verse being previewed in the centre panel — set by tapping/
  /// double-tapping a verse row. Does NOT add anything to the queue.
  ScriptureQueueItem? _previewVerse;

  final List<PlanSection> _sections = [
    PlanSection(title: 'Service', items: []),
  ];

  /// Flat ordered list of all items across all sections.
  List<ServiceItem> get _plan => _sections.expand((s) => s.items).toList();

  int _activeIndex = -1; // flat index into _plan

  ServiceItem? get _activeItem {
    final p = _plan;
    return _activeIndex >= 0 && _activeIndex < p.length
        ? p[_activeIndex]
        : null;
  }

  ScriptureQueueItem? get _activeQueueItem =>
      _activeItem?.type == ServiceItemType.scripture
      ? _activeItem!.scriptureItem
      : null;

  /// The single verse to project on screen.
  ScriptureQueueItem? get _projectedVerse {
    final si = _activeQueueItem;
    if (si == null || si.verses.isEmpty) return null;
    final idx = si.liveVerseIndex.clamp(0, si.verses.length - 1);
    final vRow = si.verses[idx];
    return ScriptureQueueItem(
      book: si.book,
      chapter: si.chapter,
      startVerse: vRow['verse'] as int,
      endVerse: vRow['verse'] as int,
      verses: [vRow],
      version: si.version,
    );
  }

  Map<String, String>? get _activeSong =>
      _activeItem?.type == ServiceItemType.song ? _activeItem!.song : null;

  // ── History shelf — auto-populated recently-shown items ──────────────────
  final List<ServiceItem> _history = [];
  static const int _kMaxHistory = 20;
  bool _shelfExpanded = true;

  String _serviceTitle = 'Morning Service';
  DateTime _serviceDate = DateTime.now();

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

  final FocusNode _keyboardFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _songSearchController = TextEditingController();
    _filteredSongs = _songs;
    _searchFocus.addListener(_onSearchFocusChange);
    _loadVersion(kBibleVersions.first, isInitialLoad: true);
    _loadServicePlan();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _songSearchController.dispose();
    _searchFocus.removeListener(_onSearchFocusChange);
    _searchFocus.dispose();
    _removeSearchOverlay();
    _dropdownCoord.dispose();
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

    return Focus(
      focusNode: _keyboardFocus,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        // If any child TextField currently has focus, let it consume the key
        // normally — do NOT intercept for presentation shortcuts.
        final primaryFocus = FocusManager.instance.primaryFocus;
        if (primaryFocus != null && primaryFocus != _keyboardFocus) {
          // A child widget (TextField, button, etc.) owns focus → pass through
          return KeyEventResult.ignored;
        }

        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.arrowRight ||
            key == LogicalKeyboardKey.arrowDown) {
          _stepForward();
          return KeyEventResult.handled;
        } else if (key == LogicalKeyboardKey.arrowLeft ||
            key == LogicalKeyboardKey.arrowUp) {
          _stepBack();
          return KeyEventResult.handled;
        } else if (key == LogicalKeyboardKey.space) {
          _goLive();
          return KeyEventResult.handled;
        } else if (key == LogicalKeyboardKey.keyB) {
          _clearProjector();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Fixed panel widths: scripture(340) + verse(300) + song(300) + plan(300)
          // + dividers(4) = 1244. Preview panel gets at least 420px so its
          // tab bar (4 tabs + search) and action bar (4 buttons) never overflow.
          const double kMinPreviewWidth = 420.0;
          const double kPlanWidth = 300.0;
          const double kFixedWidth = kPanelWidth + 300 + 300 + kPlanWidth + 4;
          const double kMinTotalWidth = kFixedWidth + kMinPreviewWidth;

          final availableWidth = constraints.maxWidth;
          final previewWidth = (availableWidth - kFixedWidth).clamp(
            kMinPreviewWidth,
            double.infinity,
          );
          final totalWidth = availableWidth < kMinTotalWidth
              ? kMinTotalWidth
              : availableWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: availableWidth < kMinTotalWidth
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            child: SizedBox(
              width: totalWidth,
              child: Row(
                children: [
                  SizedBox(
                    width: kPanelWidth,
                    child: Container(
                      color: context.t.surface,
                      child: Column(
                        children: [
                          Expanded(child: _buildScripturePanel()),
                          Divider(
                            color: context.t.border,
                            height: 1,
                            thickness: 1,
                          ),
                          Expanded(child: _buildSongPanel()),
                        ],
                      ),
                    ),
                  ),

                  VerticalDivider(width: 1, color: context.t.border),

                  SizedBox(width: 300, child: _buildChapterOverviewPanel()),

                  VerticalDivider(width: 1, color: context.t.border),

                  SizedBox(width: 300, child: _buildSongOverviewPanel()),

                  VerticalDivider(width: 1, color: context.t.border),

                  // ── PREVIEW + MEDIA PANEL ──────────────────────────────────
                  SizedBox(
                    width: previewWidth,
                    child: Container(
                      color: context.t.appBg,
                      child: Column(
                        children: [
                          Expanded(flex: 6, child: _buildDisplaySection()),
                          Flexible(flex: 4, child: _buildMediaPanel()),
                          _buildReferenceShelf(),
                        ],
                      ),
                    ),
                  ),

                  VerticalDivider(width: 1, color: context.t.border),

                  // ── SERVICE PLAN / QUEUE — far right vertical column ───────
                  SizedBox(width: kPlanWidth, child: _buildServicePlanPanel()),
                ],
              ),
            ),
          );
        },
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
        Expanded(child: _buildVersionLibrary()),
      ],
    );
  }

  Widget _buildPassagePicker() {
    final t = context.t;
    final bool chapterReady = _selectedBook != null && !_versionLoading;
    final bool versesReady =
        chapterReady && _selectedChapter != null && _verseList.isNotEmpty;

    final alreadyInPlan =
        versesReady &&
        _plan.any(
          (si) =>
              si.type == ServiceItemType.scripture &&
              si.scriptureItem?.book == _selectedBook &&
              si.scriptureItem?.chapter == _selectedChapter &&
              si.scriptureItem?.version.abbreviation ==
                  _activeVersion.abbreviation,
        );

    String rangeSummary = '';
    if (_pickerFromVerse != null && _pickerToVerse != null) {
      rangeSummary = 'v$_pickerFromVerse – v$_pickerToVerse';
    } else if (_pickerFromVerse != null) {
      rangeSummary = 'from v$_pickerFromVerse';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Book + Chapter + From/To pickers ────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                    child: _BookPickerField(
                      books: _bibleBooks,
                      selectedBook: _selectedBook,
                      enabled: !_versionLoading,
                      onSelected: _selectBook,
                      coordinator: _dropdownCoord,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: _ChapterPickerField(
                      chapters: _chapters,
                      selectedChapter: _selectedChapter,
                      enabled: chapterReady,
                      onSelected: _selectChapter,
                      coordinator: _dropdownCoord,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _VerseRangePickerField(
                      label: 'From',
                      verses: _verseList,
                      selectedVerse: _pickerFromVerse,
                      enabled: versesReady,
                      coordinator: _dropdownCoord,
                      onSelected: (v) => setState(() {
                        _rangeFrom = v;
                        if (_pickerToVerse != null &&
                            v != null &&
                            _pickerToVerse! < v) {
                          _rangeTo = null;
                        }
                      }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '–',
                      style: TextStyle(fontSize: 13, color: t.textMuted),
                    ),
                  ),
                  Expanded(
                    child: _VerseRangePickerField(
                      label: 'To',
                      verses: _verseList,
                      selectedVerse: _pickerToVerse,
                      enabled: versesReady,
                      minVerse: _pickerFromVerse,
                      coordinator: _dropdownCoord,
                      onSelected: (v) => setState(() => _rangeTo = v),
                    ),
                  ),
                  if (_pickerToVerse != null) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => _rangeTo = null),
                      child: Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: t.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // ── Add to Queue bar ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  rangeSummary.isNotEmpty
                      ? rangeSummary
                      : 'Double-tap verse to go live',
                  style: TextStyle(fontSize: 10, color: t.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: versesReady ? _addPickerSelectionToQueue : null,
                child: AnimatedOpacity(
                  opacity: versesReady ? 1.0 : 0.35,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: alreadyInPlan
                          ? t.accentBlue.withValues(alpha: 0.08)
                          : t.accentBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: t.accentBlue.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          alreadyInPlan
                              ? Icons.check_rounded
                              : Icons.playlist_add_rounded,
                          size: 14,
                          color: t.accentBlue,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          alreadyInPlan ? 'In Queue' : 'Add to Queue',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: t.accentBlue,
                          ),
                        ),
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

  Widget _buildVersionLibrary() {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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

        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: kBibleVersions.length,
            separatorBuilder: (_, _) => Divider(height: 1, color: t.border),
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
                      Container(
                        width: 44,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isActive ? t.accentBlue : t.surfaceHigh,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: isActive ? t.accentBlue : t.border,
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
                                      color: t.isDark ? t.appBg : Colors.white,
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

                      Expanded(
                        child: Text(
                          version.fullName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isActive ? t.accentBlue : t.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

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

  Widget _buildSearchBar() {
    return CompositedTransformTarget(
      link: _searchBarLink,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.t.border)),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          onChanged: _onSearchChanged,
          onSubmitted: _onSearchSubmitted,
          style: TextStyle(fontSize: 13, color: context.t.textPrimary),
          decoration: InputDecoration(
            hintText: 'Jn 3:16  ·  john3  ·  god so loved the world',
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
              onPressed: () => _onSearchSubmitted(_searchController.text),
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
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SERVICE PLAN PANEL
  // ═══════════════════════════════════════════════════════════════════════════

  final ScrollController _planScroll = ScrollController();
  // ── Plan mutation helpers (work on active section) ───────────────────────

  /// Active section index — which section new items are added to.
  int _activeSectionIdx = 0;

  void _addItem(ServiceItem item) {
    if (_sections.isEmpty) {
      _sections.add(PlanSection(title: 'Service', items: []));
      _activeSectionIdx = 0;
    }
    final idx = _activeSectionIdx.clamp(0, _sections.length - 1);
    _sections[idx].items.add(item);
    _activeIndex = _plan.length - 1;
  }

  void _removeItemAt(int flatIdx) {
    int remaining = flatIdx;
    for (int s = 0; s < _sections.length; s++) {
      if (remaining < _sections[s].items.length) {
        _sections[s].items.removeAt(remaining);
        final newLen = _plan.length;
        if (newLen == 0) {
          _activeIndex = -1;
        } else if (_activeIndex >= newLen) {
          _activeIndex = newLen - 1;
        } else if (_activeIndex == flatIdx) {
          _activeIndex = _activeIndex.clamp(0, newLen - 1).toInt();
        }
        return;
      }
      remaining -= _sections[s].items.length;
    }
  }

  void _replaceItemAt(int flatIdx, ServiceItem newItem) {
    int remaining = flatIdx;
    for (int s = 0; s < _sections.length; s++) {
      if (remaining < _sections[s].items.length) {
        _sections[s].items[remaining] = newItem;
        return;
      }
      remaining -= _sections[s].items.length;
    }
  }

  ServiceItem? _itemAt(int flatIdx) {
    int remaining = flatIdx;
    for (int s = 0; s < _sections.length; s++) {
      if (remaining < _sections[s].items.length) {
        return _sections[s].items[remaining];
      }
      remaining -= _sections[s].items.length;
    }
    return null;
  }

  void _clearAllItems() {
    for (final s in _sections) {
      s.items.clear();
    }
    _activeIndex = -1;
  }

  /// Push an item to the history shelf (deduplicates by id).
  void _pushHistory(ServiceItem item) {
    _history.removeWhere((h) => h.id == item.id);
    _history.insert(0, item);
    if (_history.length > _kMaxHistory) _history.removeLast();
  }

  /// Shows "John 3 · v16  (2/5)" — verse within passage + plan item number
  String _buildPlanPositionLabel() {
    if (_activeIndex < 0 || _plan.isEmpty) return '—';
    final item = _activeItem!;
    final planPos = '${_activeIndex + 1}/${_plan.length}';
    if (item.type == ServiceItemType.scripture && item.scriptureItem != null) {
      final si = item.scriptureItem!;
      final versePos = '${si.liveVerseIndex + 1}/${si.verses.length}';
      return 'v${si.liveVerseNum ?? '?'}  ·  $versePos  ($planPos)';
    }
    return planPos;
  }

  final TextEditingController _quickAddCtrl = TextEditingController();

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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: t.surfaceHigh,
              border: Border(bottom: BorderSide(color: t.border)),
            ),
            child: Row(
              children: [
                Icon(Icons.church_rounded, size: 13, color: t.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: GestureDetector(
                    onTap: _editServiceTitle,
                    child: Text(
                      _serviceTitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _pickServiceDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: t.appBg,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: t.border),
                    ),
                    child: Text(
                      '${_serviceDate.day}/${_serviceDate.month}/${_serviceDate.year}',
                      style: TextStyle(fontSize: 10, color: t.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _IconTip(
                  icon: Icons.save_rounded,
                  tooltip: 'Save service',
                  color: t.accentBlue,
                  onTap: _saveService,
                ),
                const SizedBox(width: 4),
                _IconTip(
                  icon: Icons.folder_open_rounded,
                  tooltip: 'Load saved service',
                  color: t.textSecondary,
                  onTap: _showLoadServiceDialog,
                ),
                const SizedBox(width: 4),
                _IconTip(
                  icon: Icons.add_circle_outline_rounded,
                  tooltip: 'New service',
                  color: t.textSecondary,
                  onTap: _newService,
                ),
              ],
            ),
          ),

          // ── Item count + clear ──────────────────────────────────────
          if (_plan.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: t.border)),
              ),
              child: Row(
                children: [
                  Text(
                    '${_plan.length} item${_plan.length == 1 ? "" : "s"}',
                    style: TextStyle(fontSize: 10, color: t.textMuted),
                  ),
                  const Spacer(),
                  _IconTip(
                    icon: Icons.delete_sweep_rounded,
                    tooltip: 'Clear all',
                    color: t.textMuted,
                    onTap: _confirmClearPlan,
                  ),
                ],
              ),
            ),

          Expanded(
            child: _plan.isEmpty && _sections.every((s) => s.items.isEmpty)
                ? _buildEmptyPlan(t)
                : _buildSectionedPlan(t),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOTTOM PANEL — MEDIA BROWSER
  // ═══════════════════════════════════════════════════════════════════════════

  String _mediaTab = 'Images'; // 'Images' | 'Videos' | 'Audio' | 'Backgrounds'
  String _mediaSearch = '';
  final TextEditingController _mediaSearchCtrl = TextEditingController();

  // Placeholder media items — replace with real file-system data later
  static const List<Map<String, dynamic>> _kPlaceholderMedia = [
    {
      'name': 'Worship Background 1',
      'type': 'image',
      'ext': 'JPG',
      'color': 0xFF1A3A4A,
    },
    {
      'name': 'Cross Silhouette',
      'type': 'image',
      'ext': 'PNG',
      'color': 0xFF2A1A4A,
    },
    {
      'name': 'Church Interior',
      'type': 'image',
      'ext': 'JPG',
      'color': 0xFF1A2A3A,
    },
    {
      'name': 'Sunrise Mountains',
      'type': 'image',
      'ext': 'JPG',
      'color': 0xFF3A2A1A,
    },
    {
      'name': 'Dove in Flight',
      'type': 'image',
      'ext': 'PNG',
      'color': 0xFF1A3A2A,
    },
    {
      'name': 'Sermon Intro',
      'type': 'video',
      'ext': 'MP4',
      'color': 0xFF2A1A1A,
    },
    {
      'name': 'Worship Loop',
      'type': 'video',
      'ext': 'MP4',
      'color': 0xFF1A1A3A,
    },
    {
      'name': 'Amazing Grace Instrumental',
      'type': 'audio',
      'ext': 'MP3',
      'color': 0xFF2A3A1A,
    },
    {
      'name': 'Offering Background',
      'type': 'image',
      'ext': 'JPG',
      'color': 0xFF3A1A2A,
    },
    {
      'name': 'Dark Gradient',
      'type': 'image',
      'ext': 'JPG',
      'color': 0xFF111111,
    },
  ];

  Widget _buildMediaPanel() {
    final t = context.t;
    final tabs = ['Images', 'Videos', 'Audio', 'Backgrounds'];

    final filtered = _kPlaceholderMedia.where((m) {
      final matchesTab = _mediaTab == 'Images'
          ? m['type'] == 'image' && m['name'] != 'Dark Gradient'
          : _mediaTab == 'Videos'
          ? m['type'] == 'video'
          : _mediaTab == 'Audio'
          ? m['type'] == 'audio'
          : m['type'] == 'image'; // Backgrounds = all images
      final matchesSearch =
          _mediaSearch.isEmpty ||
          (m['name'] as String).toLowerCase().contains(
            _mediaSearch.toLowerCase(),
          );
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
          // ── Header ──────────────────────────────────────────────────────
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
                Text(
                  'MEDIA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: t.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                // Import button
                Tooltip(
                  message: 'Import media files',
                  child: GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Import media — coming soon'),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: t.accentBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: t.accentBlue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 11,
                            color: t.accentBlue,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Import',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: t.accentBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Tab bar + search ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.border)),
            ),
            child: Row(
              children: [
                // Tabs
                ...tabs.map((tab) {
                  final isActive = _mediaTab == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _mediaTab = tab),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 130),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
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
                        child: Text(
                          tab,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isActive ? t.accentBlue : t.textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                // Search
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 140,
                      minWidth: 80,
                    ),
                    child: SizedBox(
                      height: 26,
                      child: TextField(
                        controller: _mediaSearchCtrl,
                        style: TextStyle(fontSize: 11, color: t.textPrimary),
                        onChanged: (v) => setState(() => _mediaSearch = v),
                        decoration: InputDecoration(
                          hintText: 'Search…',
                          hintStyle: TextStyle(
                            fontSize: 11,
                            color: t.textMuted,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 14,
                            color: t.textMuted,
                          ),
                          filled: true,
                          fillColor: t.appBg,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
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
                            borderSide: BorderSide(
                              color: t.accentBlue,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Media grid ──────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          size: 28,
                          color: t.textMuted,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No $_mediaTab found',
                          style: TextStyle(fontSize: 12, color: t.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap Import to add media files',
                          style: TextStyle(fontSize: 10, color: t.textMuted),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 130,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.4,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final item = filtered[i];
                      final isAudio = item['type'] == 'audio';
                      final isVideo = item['type'] == 'video';
                      return GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Send "${item['name']}" to projector — coming soon',
                            ),
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(item['color'] as int),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: t.border),
                          ),
                          child: Stack(
                            children: [
                              // Type icon centred
                              Center(
                                child: Icon(
                                  isAudio
                                      ? Icons.music_note_rounded
                                      : isVideo
                                      ? Icons.play_circle_outline_rounded
                                      : Icons.image_rounded,
                                  size: 24,
                                  color: Colors.white.withValues(alpha: 0.35),
                                ),
                              ),
                              // Bottom label
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    5,
                                    3,
                                    5,
                                    4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(5),
                                      bottomRight: Radius.circular(5),
                                    ),
                                  ),
                                  child: Text(
                                    item['name'] as String,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              // Ext badge
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    item['ext'] as String,
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
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
        ],
      ),
    );
  }

  Widget _buildSectionedPlan(AppTheme t) {
    // Build a flat list of widgets: section header + items (when not collapsed)
    return ListView(
      controller: _planScroll,
      children: [
        for (int si = 0; si < _sections.length; si++) ...[
          _buildSectionHeader(si, t),
          if (!_sections[si].isCollapsed) ...[
            // Items in this section
            ...() {
              // Calculate flat offset for this section
              int offset = 0;
              for (int k = 0; k < si; k++) {
                offset += _sections[k].items.length;
              }
              return List.generate(_sections[si].items.length, (ii) {
                return _buildPlanRow(offset + ii);
              });
            }(),
            // Drag-target drop zone (subtle) if section is active target
            if (_sections[si].items.isEmpty)
              Container(
                key: ValueKey('empty-$si'),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: si == _activeSectionIdx
                        ? t.accentBlue.withValues(alpha: 0.4)
                        : t.border.withValues(alpha: 0.4),
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    'No items — use quick-add or tap + on a verse/song',
                    style: TextStyle(fontSize: 10, color: t.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ],
        // Add section button at bottom
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: GestureDetector(
            onTap: _addSection,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: t.border, style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 13, color: t.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Add Section',
                    style: TextStyle(fontSize: 11, color: t.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(int si, AppTheme t) {
    final section = _sections[si];
    final isTarget = si == _activeSectionIdx;
    final count = section.items.length;

    return GestureDetector(
      onTap: () => setState(() => section.isCollapsed = !section.isCollapsed),
      onDoubleTap: () => _renameSection(si),
      child: Container(
        key: ValueKey('sec-$si'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isTarget
              ? t.accentBlue.withValues(alpha: 0.07)
              : t.surfaceHigh,
          border: Border(
            top: BorderSide(color: t.border),
            bottom: BorderSide(color: t.border),
            left: BorderSide(
              color: isTarget ? t.accentBlue : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            // Collapse chevron (visual indicator only — whole row is tappable)
            AnimatedRotation(
              turns: section.isCollapsed ? -0.25 : 0,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: t.textSecondary,
              ),
            ),
            const SizedBox(width: 6),

            // Section title (double-tap to rename)
            Expanded(
              child: Text(
                section.title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isTarget ? t.accentBlue : t.textSecondary,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Item count badge
            if (count > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: t.border,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9,
                    color: t.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],

            // Set as target (+ button — click to make this where new items go)
            Tooltip(
              message: isTarget
                  ? 'Adding items here'
                  : 'Add items to this section',
              child: GestureDetector(
                onTap: () => setState(() => _activeSectionIdx = si),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isTarget
                        ? t.accentBlue.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    isTarget
                        ? Icons.playlist_add_check_rounded
                        : Icons.playlist_add_rounded,
                    size: 14,
                    color: isTarget ? t.accentBlue : t.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),

            // Section menu
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.more_vert_rounded, size: 14, color: t.textMuted),
              iconSize: 14,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: t.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      const Text('Rename', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                if (_sections.length > 1)
                  PopupMenuItem(
                    value: 'merge_up',
                    enabled: si > 0,
                    child: Row(
                      children: [
                        Icon(
                          Icons.merge_rounded,
                          size: 14,
                          color: t.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Merge into above',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_outline_rounded,
                        size: 14,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Delete section',
                        style: TextStyle(fontSize: 12, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (val) {
                if (val == 'rename') _renameSection(si);
                if (val == 'merge_up') _mergeSectionUp(si);
                if (val == 'delete') _deleteSection(si);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addSection() async {
    final t = context.t;
    final ctrl = TextEditingController(text: 'Section ${_sections.length + 1}');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        title: Text(
          'New Section',
          style: TextStyle(color: t.textPrimary, fontSize: 15),
        ),
        content: _DlgField(ctrl: ctrl, label: 'Section name', t: t),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text('Add', style: TextStyle(color: t.accentBlue)),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    setState(() {
      _sections.add(PlanSection(title: name, items: []));
      _activeSectionIdx = _sections.length - 1;
    });
    _saveService();
  }

  void _renameSection(int si) async {
    final t = context.t;
    final ctrl = TextEditingController(text: _sections[si].title);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        title: Text(
          'Rename Section',
          style: TextStyle(color: t.textPrimary, fontSize: 15),
        ),
        content: _DlgField(ctrl: ctrl, label: 'Section name', t: t),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text('Save', style: TextStyle(color: t.accentBlue)),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    setState(() => _sections[si].title = name);
    _saveService();
  }

  void _mergeSectionUp(int si) {
    if (si <= 0 || si >= _sections.length) return;
    setState(() {
      _sections[si - 1].items.addAll(_sections[si].items);
      _sections.removeAt(si);
      _activeSectionIdx = _activeSectionIdx
          .clamp(0, _sections.length - 1)
          .toInt();
    });
    _saveService();
  }

  void _deleteSection(int si) async {
    final section = _sections[si];
    if (section.items.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.t.surface,
          title: const Text('Delete Section?', style: TextStyle(fontSize: 15)),
          content: Text(
            '"${section.title}" has ${section.items.length} item(s).\nThey will be moved to the section above.',
            style: TextStyle(fontSize: 13, color: context.t.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    setState(() {
      if (si > 0) {
        _sections[si - 1].items.addAll(section.items);
      } else if (_sections.length > 1) {
        _sections[1].items.insertAll(0, section.items);
      }
      _sections.removeAt(si);
      if (_sections.isEmpty) {
        _sections.add(PlanSection(title: 'Service', items: []));
      }
      _activeSectionIdx = _activeSectionIdx
          .clamp(0, _sections.length - 1)
          .toInt();
      _activeIndex = _activeIndex.clamp(-1, _plan.length - 1).toInt();
    });
    _saveService();
  }

  Widget _buildReferenceShelf() {
    final t = context.t;
    final hasItems = _history.isNotEmpty;
    if (!hasItems) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        border: Border(top: BorderSide(color: t.border, width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => setState(() => _shelfExpanded = !_shelfExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, size: 13, color: t.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    'Reference Shelf',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: t.textMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: t.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_history.length}',
                      style: TextStyle(
                        fontSize: 9,
                        color: t.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _history.clear()),
                    child: Tooltip(
                      message: 'Clear shelf',
                      child: Icon(
                        Icons.clear_all_rounded,
                        size: 14,
                        color: t.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _shelfExpanded
                        ? Icons.expand_more_rounded
                        : Icons.chevron_right_rounded,
                    size: 14,
                    color: t.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_shelfExpanded)
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                itemCount: _history.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, i) => _buildShelfChip(_history[i], t),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShelfChip(ServiceItem item, AppTheme t) {
    final accent = item.accentColor(t);
    final isActive = _activeItem?.id == item.id;

    return Tooltip(
      message:
          '${item.title}${item.subtitle.isNotEmpty ? "\n${item.subtitle}" : ""}',
      child: GestureDetector(
        onTap: () {
          // Find in plan and activate if present
          final planIdx = _plan.indexWhere((p) => p.id == item.id);
          if (planIdx >= 0) setState(() => _activeIndex = planIdx);
          // Re-project
          if (!_projectorOpen) {
            setState(() => _projectorOpen = true);
            Navigator.of(context)
                .push(
                  PageRouteBuilder(
                    opaque: true,
                    barrierColor: Colors.black,
                    pageBuilder: (_, _, _) => ProjectorScreen(
                      queueItem: item.scriptureItem,
                      song: item.song,
                      announcement: item.type == ServiceItemType.announcement
                          ? item
                          : null,
                      showLogo: item.type == ServiceItemType.logo,
                    ),
                    transitionDuration: const Duration(milliseconds: 300),
                    transitionsBuilder: (_, anim, _, child) =>
                        FadeTransition(opacity: anim, child: child),
                  ),
                )
                .then((_) => setState(() => _projectorOpen = false));
          } else {
            ProjectorNotifier.instance.update(
              queueItem: item.scriptureItem,
              song: item.song,
              announcement: item.type == ServiceItemType.announcement
                  ? item
                  : null,
              showLogo: item.type == ServiceItemType.logo,
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          constraints: const BoxConstraints(maxWidth: 140, minWidth: 60),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isActive ? accent.withValues(alpha: 0.18) : t.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive ? accent : t.border,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 11, color: isActive ? accent : t.textMuted),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isActive ? accent : t.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPlan(AppTheme t) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.playlist_add_rounded, size: 28, color: t.textMuted),
          const SizedBox(height: 10),
          Text(
            'Service plan is empty',
            style: TextStyle(fontSize: 12, color: t.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            'Type a reference above (John 3:16, Ps 23…)\nor add from the verse/song overview.',
            style: TextStyle(fontSize: 10, color: t.textMuted, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _showLoadServiceDialog,
            child: Text(
              'Load a saved service',
              style: TextStyle(
                fontSize: 11,
                color: t.accentBlue,
                decoration: TextDecoration.underline,
                decorationColor: t.accentBlue,
              ),
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
    final item = _itemAt(index) ?? _plan.first;
    final isActive = index == _activeIndex;
    final isDone = _activeIndex >= 0 && index < _activeIndex;
    final accent = item.accentColor(t);

    return InkWell(
      key: ValueKey(item.id),
      onTap: () => _selectPlanItem(index),
      hoverColor: accent.withValues(alpha: 0.05),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
            Icon(Icons.drag_indicator_rounded, size: 13, color: t.textMuted),
            const SizedBox(width: 6),

            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isActive ? accent.withValues(alpha: 0.2) : t.surfaceHigh,
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
                        fontSize: 11,
                        color: isDone ? t.textMuted : t.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  // Progress bar for scripture items
                  if (item.type == ServiceItemType.scripture &&
                      item.scriptureItem != null &&
                      item.scriptureItem!.verses.length > 1) ...[
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: item.scriptureItem!.verses.isEmpty
                            ? 0
                            : (item.scriptureItem!.liveVerseIndex + 1) /
                                  item.scriptureItem!.verses.length,
                        minHeight: 2,
                        backgroundColor: t.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDone ? t.textMuted : accent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

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
            Expanded(
              child: _SectionLabel(
                label: 'SONGS',
                accent: context.t.accentPurple,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Tooltip(
                message: 'Add new song',
                child: GestureDetector(
                  onTap: () => _showSongEditorDialog(null),
                  child: Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: context.t.accentPurple,
                  ),
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
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: context.t.border)),
          ),
          child: Row(
            children: [
              Text(
                'Double-tap to preview',
                style: TextStyle(fontSize: 10, color: context.t.textMuted),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  final song = _selectedSong;
                  if (song == null) return;
                  setState(
                    () => _addItem(
                      ServiceItem(type: ServiceItemType.song, song: song),
                    ),
                  );
                },
                child: Builder(
                  builder: (ctx) {
                    final t = ctx.t;
                    final canAdd = _selectedSong != null;
                    return AnimatedOpacity(
                      opacity: canAdd ? 1.0 : 0.35,
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: t.accentPurple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: t.accentPurple.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.playlist_add_rounded,
                              size: 14,
                              color: t.accentPurple,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Add to Queue',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: t.accentPurple,
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
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RIGHT PANEL — PREVIEW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDisplaySection() {
    final item = _activeItem;

    Widget preview;
    if (item == null) {
      if (_previewVerse != null) {
        preview = _buildScripturePreview(_previewVerse!);
      } else if (_selectedSection != null && _selectedSong != null) {
        final previewSong = Map<String, String>.from(_selectedSong!)
          ..['lyrics'] = _selectedSection!.text
          ..['_sectionLabel'] = _selectedSection!.label;
        preview = _buildSongPreview(previewSong);
      } else {
        preview = _buildWelcomeScreen();
      }
    } else {
      switch (item.type) {
        case ServiceItemType.scripture:
          // If a specific verse is being previewed (set by tapping the overview
          // or clicking a queue item), show that single verse — not all verses.
          preview = _buildScripturePreview(
            _previewVerse ?? item.scriptureItem!,
          );
        case ServiceItemType.song:
          preview = _buildSongPreview(item.song!);
        case ServiceItemType.announcement:
          preview = _buildAnnouncementPreview(item);
        case ServiceItemType.logo:
          preview = _buildLogoPreview();
        case ServiceItemType.black:
          preview = _buildBlackPreview();
      }
    }

    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Preview content ────────────────────────────────────────────
        Expanded(child: preview),

        // ── Action bar — Black / Logo / Announce / Message ────────────
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
                _PreviewActionButton(
                  icon: Icons.circle,
                  label: 'Black',
                  color: const Color(0xFF777777),
                  onTap: _addBlackScreen,
                ),
                const SizedBox(width: 6),
                _PreviewActionButton(
                  icon: Icons.church_rounded,
                  label: 'Logo',
                  color: const Color(0xFF4CAF50),
                  onTap: _addLogoSlide,
                ),
                const SizedBox(width: 6),
                _PreviewActionButton(
                  icon: Icons.campaign_rounded,
                  label: 'Announce',
                  color: const Color(0xFFE6A817),
                  onTap: _showAnnouncementDialog,
                ),
                const SizedBox(width: 6),
                _PreviewActionButton(
                  icon: Icons.message_rounded,
                  label: 'Message',
                  color: const Color(0xFF42A5F5),
                  onTap: _showMessageDialog,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MIDDLE COLUMN — CHAPTER VERSE OVERVIEW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildChapterOverviewPanel() {
    final t = context.t;

    return Container(
      color: t.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                : Material(
                    color: Colors.transparent,
                    child: Builder(
                      builder: (context) {
                        final rows = _buildVerseRows();
                        return ListView.builder(
                          controller: _verseOverviewScroll,
                          padding: EdgeInsets.zero,
                          itemCount: rows.length,
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            return SizedBox(
                              height: _kVerseRowHeight,
                              child: _buildOverviewVerseRow(
                                verseNum: row.startVerse,
                                endVerseNum: row.endVerse,
                                verseText: row.text,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),

          _buildOverviewNavBar(
            accent: t.accentBlue,
            onPrev: _verseList.isEmpty
                ? null
                : () {
                    final rows = _buildVerseRows();
                    if (rows.isEmpty) return;
                    // Move the deep-blue selected verse to the previous row
                    final cur = rows.indexWhere(
                      (r) => r.startVerse == _previewVerseNum,
                    );
                    final idx = (cur <= 0) ? rows.length - 1 : cur - 1;
                    final row = rows[idx];
                    final vRow = _verseList.firstWhere(
                      (v) => (v['verse'] as int) == row.startVerse,
                      orElse: () => {},
                    );
                    if (vRow.isEmpty) return;
                    setState(() {
                      _previewVerseNum = row.startVerse;
                      _previewVerse = ScriptureQueueItem(
                        book: _selectedBook!,
                        chapter: _selectedChapter!,
                        startVerse: row.startVerse,
                        endVerse: row.startVerse,
                        verses: [vRow],
                        version: _activeVersion,
                      );
                    });
                    // Scroll so the newly selected verse is visible
                    Future.delayed(const Duration(milliseconds: 50), () {
                      if (!_verseOverviewScroll.hasClients) return;
                      final offset = (idx * _kVerseRowHeight - 80).clamp(
                        0.0,
                        _verseOverviewScroll.position.maxScrollExtent,
                      );
                      _verseOverviewScroll.animateTo(
                        offset,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                    });
                  },
            onNext: _verseList.isEmpty
                ? null
                : () {
                    final rows = _buildVerseRows();
                    if (rows.isEmpty) return;
                    // Move the deep-blue selected verse to the next row
                    final cur = rows.indexWhere(
                      (r) => r.startVerse == _previewVerseNum,
                    );
                    final idx = (cur < 0 || cur >= rows.length - 1)
                        ? 0
                        : cur + 1;
                    final row = rows[idx];
                    final vRow = _verseList.firstWhere(
                      (v) => (v['verse'] as int) == row.startVerse,
                      orElse: () => {},
                    );
                    if (vRow.isEmpty) return;
                    setState(() {
                      _previewVerseNum = row.startVerse;
                      _previewVerse = ScriptureQueueItem(
                        book: _selectedBook!,
                        chapter: _selectedChapter!,
                        startVerse: row.startVerse,
                        endVerse: row.startVerse,
                        verses: [vRow],
                        version: _activeVersion,
                      );
                    });
                    Future.delayed(const Duration(milliseconds: 50), () {
                      if (!_verseOverviewScroll.hasClients) return;
                      final offset = (idx * _kVerseRowHeight - 80).clamp(
                        0.0,
                        _verseOverviewScroll.position.maxScrollExtent,
                      );
                      _verseOverviewScroll.animateTo(
                        offset,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                    });
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

    final sections = song != null
        ? parseSongSections(song['lyrics'] ?? '')
        : <SongSection>[];

    return Container(
      color: t.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                      child: Icon(
                        Icons.edit_rounded,
                        size: 13,
                        color: t.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: song == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.music_note_outlined,
                          size: 36,
                          color: t.textMuted,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Select a song\nfrom the list',
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
                    padding: EdgeInsets.zero,
                    itemCount: sections.length,
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      final isSelected =
                          _selectedSection?.label == section.label &&
                          _selectedSection?.text == section.text;
                      final isLive =
                          _activeItem?.type == ServiceItemType.song &&
                          _activeItem?.song?['title'] == song['title'] &&
                          _activeItem?.song?['_sectionLabel'] == section.label;

                      return InkWell(
                        onTap: () => setState(() => _selectedSection = section),
                        onDoubleTap: () {
                          final sectionSong = Map<String, String>.from(song)
                            ..['lyrics'] = section.text
                            ..['_sectionLabel'] = section.label;
                          setState(() {
                            _selectedSection = section;
                          });
                          _goLive();
                        },
                        hoverColor: t.accentPurple.withValues(alpha: 0.05),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
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
                                    if (section.hasLabel)
                                      Text(
                                        section.label,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isLive || isSelected
                                              ? t.accentPurple
                                              : t.textSecondary,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    if (section.hasLabel)
                                      const SizedBox(height: 3),
                                    Text(
                                      section.text,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
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
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
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

          _buildOverviewNavBar(
            accent: t.accentPurple,
            extraButton: IconButton(
              icon: Icon(Icons.add_rounded, size: 16, color: t.accentPurple),
              tooltip: 'Add / edit song',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () => _showSongEditorDialog(song),
            ),
            onPrev: sections.isEmpty
                ? null
                : () {
                    final cur = sections.indexWhere(
                      (s) =>
                          s.label == _selectedSection?.label &&
                          s.text == _selectedSection?.text,
                    );
                    final idx = (cur <= 0) ? sections.length - 1 : cur - 1;
                    setState(() => _selectedSection = sections[idx]);
                  },
            onNext: sections.isEmpty
                ? null
                : () {
                    final cur = sections.indexWhere(
                      (s) =>
                          s.label == _selectedSection?.label &&
                          s.text == _selectedSection?.text,
                    );
                    final idx = (cur < 0 || cur >= sections.length - 1)
                        ? 0
                        : cur + 1;
                    setState(() => _selectedSection = sections[idx]);
                  },
          ),
        ],
      ),
    );
  }

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
          if (extraButton != null) ...[const SizedBox(width: 4), extraButton],
          const Spacer(),
          _NavBtn(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Previous',
            accent: accent,
            enabled: onPrev != null,
            onTap: onPrev ?? () {},
          ),
          const SizedBox(width: 2),
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

  List<({int startVerse, int endVerse, String text})> _buildVerseRows() {
    final rows = <({int startVerse, int endVerse, String text})>[];
    int i = 0;
    while (i < _verseList.length) {
      final raw = (_verseList[i]['text'] as String?) ?? '';
      final plain = ScriptureQueueItem.toPlain(raw);
      final startNum = _verseList[i]['verse'] as int;
      if (plain.isEmpty) {
        i++;
        continue;
      }
      int endNum = startNum;
      int j = i + 1;
      while (j < _verseList.length) {
        final nxt = ScriptureQueueItem.toPlain(
          (_verseList[j]['text'] as String?) ?? '',
        );
        if (nxt.isNotEmpty) break;
        endNum = _verseList[j]['verse'] as int;
        j++;
      }
      rows.add((startVerse: startNum, endVerse: endNum, text: plain));
      i = j;
    }
    return rows;
  }

  void _showSongEditorDialog(Map<String, String>? existingSong) {
    final titleCtrl = TextEditingController(text: existingSong?['title'] ?? '');
    final artistCtrl = TextEditingController(
      text: existingSong?['artist'] ?? '',
    );

    final sections = existingSong != null
        ? parseSongSections(existingSong['lyrics'] ?? '')
        : [SongSection(label: 'Verse 1', text: '')];

    final labelCtrls = sections
        .map((s) => TextEditingController(text: s.label))
        .toList();
    final textCtrls = sections
        .map((s) => TextEditingController(text: s.text))
        .toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlg) {
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
              final buf = StringBuffer();
              for (int i = 0; i < labelCtrls.length; i++) {
                final lbl = labelCtrls[i].text.trim();
                final body = textCtrls[i].text.trim();
                if (lbl.isNotEmpty) buf.writeln('[$lbl]');
                if (body.isNotEmpty) buf.write(body);
                if (i < labelCtrls.length - 1) buf.write('\n');
              }
              final newSong = {
                'title': titleCtrl.text.trim(),
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
                _selectedSong = newSong;
                _selectedSection = null;
              });
              Navigator.pop(ctx);
            }

            return AlertDialog(
              backgroundColor: t.surface,
              title: Text(
                existingSong != null ? 'Edit Song' : 'Add Song',
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _DlgField(
                              ctrl: titleCtrl,
                              label: 'Song title',
                              t: t,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _DlgField(
                              ctrl: artistCtrl,
                              label: 'Artist / Author',
                              t: t,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      for (int i = 0; i < labelCtrls.length; i++) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 110,
                              child: _DlgField(
                                ctrl: labelCtrls[i],
                                label: 'Label',
                                t: t,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _DlgField(
                                ctrl: textCtrls[i],
                                label: 'Lyrics',
                                t: t,
                                maxLines: 5,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.remove_circle_outline_rounded,
                                size: 18,
                                color: t.textMuted,
                              ),
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

                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final lbl in [
                            'Verse',
                            'Chorus',
                            'Bridge',
                            'Pre-Chorus',
                            'Outro',
                            'Intro',
                          ])
                            ActionChip(
                              label: Text(
                                '+ $lbl',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: t.textSecondary,
                                ),
                              ),
                              backgroundColor: t.surfaceHigh,
                              side: BorderSide(color: t.border),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              onPressed: () {
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
                            label: Text(
                              '+ Custom',
                              style: TextStyle(
                                fontSize: 11,
                                color: t.textSecondary,
                              ),
                            ),
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
                  style: FilledButton.styleFrom(
                    backgroundColor: t.accentPurple,
                  ),
                  child: Text(existingSong != null ? 'Save' : 'Add Song'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildOverviewVerseRow({
    required int verseNum,
    int? endVerseNum,
    required String verseText,
  }) {
    final t = context.t;

    // ── LIGHT BLUE range highlight — set by search (e.g. Gen5:1-5) or
    //    From/To dropdowns. Independent from the tap-preview highlight.
    // ── DEEP BLUE selected highlight — set by tapping a verse row.
    //    Both can coexist: tapping inside a range shows deep-blue on
    //    light-blue so you always know both the range and your position.
    //
    // Colours (dark-theme first, light-theme second):
    //   Light blue range fill : rangeHighlight (from AppTheme)
    //   Light blue range bar  : accentBlue @ 50%
    //   Deep blue selected    : accentBlue @ 80% fill + full bar

    final bool isRangeAnchor = _rangeFrom != null && verseNum == _rangeFrom;
    final bool isRangeEnd = _rangeTo != null && verseNum == _rangeTo;
    final bool inRange =
        _rangeFrom != null &&
        _rangeTo != null &&
        verseNum >= _rangeFrom! &&
        verseNum <= _rangeTo!;

    // ── DEEP BLUE selected highlight — set by single tap ─────────────────
    final bool isSelected = verseNum == _previewVerseNum;

    // ── LIVE — currently projected verse ─────────────────────────────────
    final liveVerseNum = _activeQueueItem?.liveVerseNum;
    final bool isLive =
        liveVerseNum != null &&
        verseNum == liveVerseNum &&
        _activeQueueItem?.book == _selectedBook &&
        _activeQueueItem?.chapter == _selectedChapter;

    final displayLabel = (endVerseNum != null && endVerseNum > verseNum)
        ? '$verseNum–$endVerseNum'
        : '$verseNum';

    // ── Colour resolution ─────────────────────────────────────────────────
    // Priority: LIVE > selected-inside-range > selected > range > plain
    final Color bg;
    final Color leftBarColor;
    final double leftBarWidth;
    final Color textColor;
    final Color numColor;

    // Deep-blue fill for selected verse (whole-row saturation)
    final Color deepBlueBg = t.accentBlue.withValues(
      alpha: t.isDark ? 0.35 : 0.22,
    );
    // Light-blue fill for range rows
    final Color lightBlueBg = t.rangeHighlight;
    final Color lightBlueBgDim = t.rangeHighlight.withValues(
      alpha: t.isDark ? 0.55 : 0.45,
    );

    if (isLive) {
      bg = t.anchorHighlight;
      leftBarColor = t.accentBlue;
      leftBarWidth = 4;
      textColor = t.textPrimary;
      numColor = t.accentBlue;
    } else if (inRange && isSelected) {
      // Verse is both in the range AND the currently selected verse —
      // show deep blue on top (range is visible via lighter bg of neighbours)
      bg = deepBlueBg;
      leftBarColor = t.accentBlue;
      leftBarWidth = 3.5;
      textColor = t.textPrimary;
      numColor = t.accentBlue;
    } else if (isSelected) {
      // Tap-selected verse outside any range — deep blue
      bg = deepBlueBg;
      leftBarColor = t.accentBlue;
      leftBarWidth = 3.5;
      textColor = t.textPrimary;
      numColor = t.accentBlue;
    } else if (inRange) {
      // Range rows — light blue; anchor/end rows are slightly stronger
      bg = isRangeAnchor || isRangeEnd ? lightBlueBg : lightBlueBgDim;
      leftBarColor = isRangeAnchor || isRangeEnd
          ? t.accentBlue
          : t.accentBlue.withValues(alpha: 0.45);
      leftBarWidth = isRangeAnchor || isRangeEnd ? 2.5 : 1.5;
      textColor = t.textPrimary.withValues(alpha: 0.9);
      numColor = t.accentBlue.withValues(alpha: 0.75);
    } else {
      bg = Colors.transparent;
      leftBarColor = Colors.transparent;
      leftBarWidth = 0;
      textColor = t.textSecondary;
      numColor = t.textMuted;
    }

    return InkWell(
      onTap: () {
        // Single tap: show this verse in the preview panel.
        // The range and the queue are NOT touched — range stays sticky,
        // queue item stays active so the user can still go-live later.
        if (_selectedBook == null || _selectedChapter == null) return;
        final vRow = _verseList.firstWhere(
          (v) => (v['verse'] as int) == verseNum,
          orElse: () => {},
        );
        if (vRow.isEmpty) return;

        setState(() {
          _previewVerseNum = verseNum;
          _previewVerse = ScriptureQueueItem(
            book: _selectedBook!,
            chapter: _selectedChapter!,
            startVerse: verseNum,
            endVerse: verseNum,
            verses: [vRow],
            version: _activeVersion,
          );
          // Deselect any active queue item so _buildDisplaySection uses
          // the simple _previewVerse path — avoids any queue-item state
          // interfering with what's shown in the preview panel.
          // The queue item is NOT removed from the plan, just deselected.
          _activeIndex = -1;
          // _rangeFrom / _rangeTo intentionally NOT touched
        });
      },
      onDoubleTap: () {
        // Double tap: preview this verse and go live.
        // If this verse is inside the active queue item's range, advance
        // the live index to it. Otherwise deselect the queue and go live
        // with a standalone single-verse item.
        if (_selectedBook == null || _selectedChapter == null) return;
        final vRow = _verseList.firstWhere(
          (v) => (v['verse'] as int) == verseNum,
          orElse: () => {},
        );
        if (vRow.isEmpty) return;

        final activeScripture = _activeQueueItem;
        final queueMatchesChapter =
            activeScripture != null &&
            activeScripture.book == _selectedBook &&
            activeScripture.chapter == _selectedChapter;

        setState(() {
          _previewVerseNum = verseNum;
          _previewVerse = ScriptureQueueItem(
            book: _selectedBook!,
            chapter: _selectedChapter!,
            startVerse: verseNum,
            endVerse: verseNum,
            verses: [vRow],
            version: _activeVersion,
          );
          if (queueMatchesChapter) {
            final verseIdx = activeScripture!.verses.indexWhere(
              (v) => (v['verse'] as int) == verseNum,
            );
            if (verseIdx >= 0) {
              // Verse is inside the stored range — advance live index
              _replaceItemAt(
                _activeIndex,
                ServiceItem(
                  id: _activeItem!.id,
                  type: ServiceItemType.scripture,
                  scriptureItem: activeScripture.withLiveIndex(verseIdx),
                ),
              );
            } else {
              // Verse is outside stored range — deselect queue, go live
              // with the standalone preview
              _activeIndex = -1;
            }
          } else {
            _activeIndex = -1;
          }
          // _rangeFrom / _rangeTo intentionally NOT touched
        });
        _goLive();
      },
      // Right-click / long-press → set/extend the range anchor
      onSecondaryTap: () => _handleVerseRangeClick(verseNum),
      onLongPress: () => _handleVerseRangeClick(verseNum),
      hoverColor: t.accentBlue.withValues(alpha: 0.05),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            left: BorderSide(color: leftBarColor, width: leftBarWidth),
            bottom: BorderSide(color: t.border, width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 38,
              child: Text(
                displayLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: numColor,
                ),
              ),
            ),
            Expanded(
              child: Text(
                verseText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, height: 1.35, color: textColor),
              ),
            ),
            // Badge: FROM marker
            if (isRangeAnchor && !isLive)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: t.accentBlue.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: t.accentBlue.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'FROM',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    color: t.accentBlue,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            // Badge: TO marker
            if (isRangeEnd && !isRangeAnchor && !isLive)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: t.accentBlue.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: t.accentBlue.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'TO',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    color: t.accentBlue,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            // Badge: LIVE
            if (isLive)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: t.accentBlue,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Right-click / long-press on a verse row to set the range anchor/end.
  /// First call sets _rangeFrom; second call (on a different verse) sets _rangeTo.
  /// Calling on the same verse as _rangeFrom clears the whole range.
  void _handleVerseRangeClick(int verseNum) {
    setState(() {
      if (_rangeFrom == null) {
        // No range yet — set anchor
        _rangeFrom = verseNum;
        _rangeTo = null;
      } else if (verseNum == _rangeFrom) {
        // Tapped anchor again — clear range
        _rangeFrom = null;
        _rangeTo = null;
      } else if (_rangeTo == null) {
        // Have anchor, no end yet — set end (swap if needed)
        if (verseNum < _rangeFrom!) {
          _rangeTo = _rangeFrom;
          _rangeFrom = verseNum;
        } else {
          _rangeTo = verseNum;
        }
      } else {
        // Range already complete — start fresh from this verse
        _rangeFrom = verseNum;
        _rangeTo = null;
      }
    });
  }

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
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Verse text card — fills available space ──────────────────
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(36, 36, 36, 28),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: t.accentBlue.withValues(alpha: 0.25),
                  width: t.isDark ? 1 : 1.5,
                ),
                boxShadow: t.isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Verse text — expands to fill card
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: RichText(
                          textAlign: TextAlign.left,
                          text: item.buildRichText(
                            TextStyle(
                              fontSize: 38,
                              height: 1.75,
                              color: t.textPrimary,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Divider
                  Container(height: 1, color: t.border),

                  const SizedBox(height: 14),

                  // Reference — right-aligned, with version badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Version pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: t.accentBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: t.accentBlue.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          item.version.abbreviation,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: t.accentBlue,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Reference — book chapter:verse
                      Text(
                        item.reference,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: t.accentBlue,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          _buildGoLiveBar(accent: t.accentBlue),
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
    const amber = Color(0xFFE6A817);
    final t = context.t;
    final lines = (item.announcementText ?? '').split('\n');
    final bodyLines = <String>[];
    final bulletLines = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('•')) {
        bulletLines.add(trimmed.substring(1).trim());
      } else if (trimmed.isNotEmpty) {
        bodyLines.add(trimmed);
      }
    }
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewHeader(
            title: item.announcementTitle?.isNotEmpty == true
                ? item.announcementTitle!
                : 'Announcement',
            subtitle: 'Weekly church announcement',
            accent: amber,
            badgeLabel: 'ANNOUNCE',
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: t.border, width: t.isDark ? 1 : 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.campaign_rounded,
                        color: amber,
                        size: 16,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'ANNOUNCEMENT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: amber.withValues(alpha: 0.85),
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (bodyLines.isNotEmpty) ...[
                    Text(
                      bodyLines.join(' '),
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.7,
                        color: t.textPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (bulletLines.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: t.surfaceHigh,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: t.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: bulletLines
                            .map(
                              (bp) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      margin: const EdgeInsets.only(
                                        top: 7,
                                        right: 12,
                                      ),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: amber,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        bp,
                                        style: TextStyle(
                                          fontSize: 15,
                                          height: 1.55,
                                          color: t.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          _buildGoLiveBar(accent: amber),
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
                    Icon(
                      Icons.church_rounded,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
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

  Widget _buildGoLiveBar({bool? isScripture, Color? accent}) {
    final t = context.t;
    final a = accent ?? (isScripture == true ? t.accentBlue : t.accentPurple);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
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
            label: const Text('Clear', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.t.surface,
                shape: BoxShape.circle,
                border: Border.all(color: context.t.border),
              ),
              child: Icon(
                Icons.church_rounded,
                size: 44,
                color: context.t.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Church Presentation',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: context.t.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Select a verse or song to begin',
              style: TextStyle(fontSize: 13, color: context.t.textSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 360,
              child: Container(
                padding: const EdgeInsets.all(20),
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
                    const SizedBox(height: 12),
                    _TipRow(
                      icon: Icons.menu_book_rounded,
                      color: context.t.accentBlue,
                      text:
                          'Pick a version from the Bible Versions list on the left',
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
                          'Use the Book, Chapter, From & To dropdowns to pick any passage',
                    ),
                    _TipRow(
                      icon: Icons.touch_app_rounded,
                      color: context.t.accentBlue,
                      text:
                          'Tap to preview  ·  Double-tap to go live  ·  Right-click to set range',
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
            ),
          ],
        );

        // Scale the whole card down if the available height is tight
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: content,
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATABASE  &  VERSION SWITCHING
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadVersion(
    BibleVersion version, {
    bool isInitialLoad = false,
  }) async {
    setState(() {
      if (!isInitialLoad) _versionLoading = true;
    });

    try {
      final data = await rootBundle.load(version.assetPath);
      final bytes = data.buffer.asUint8List();

      final safeFileName = version.fileName.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );
      final tempFile = File('${Directory.systemTemp.path}/$safeFileName');
      await tempFile.writeAsBytes(bytes);

      _database?.dispose();
      final db = sqlite3.open(tempFile.path);

      final bookRows = db.select(
        'SELECT book_number, long_name, short_name FROM books ORDER BY book_number',
      );

      // NKJV stores verbose titles like "The Gospel According to MARK".
      // Extract a clean, standard display name from every version:
      //   1. Pull out all ALL-CAPS words and title-case them → "Mark"
      //   2. Prefix with the numeric book prefix from short_name if present
      //      e.g. short_name "1Co" → prefix "1 " → "1 Corinthians"
      //   3. Fall back to long_name as-is when no caps pattern found.
      String normaliseBookName(String longName, String shortName) {
        // Collect sequences of all-caps letters (≥2 chars, may contain spaces)
        final capsWords = RegExp(r'\b[A-Z]{2,}\b').allMatches(longName).map((
          m,
        ) {
          // Title-case each word
          return m
              .group(0)!
              .split(' ')
              .map((w) => w.isEmpty ? w : w[0] + w.substring(1).toLowerCase())
              .join(' ');
        }).toList();
        if (capsWords.isEmpty) return longName; // no all-caps → use as-is

        String name = capsWords.join(' ');

        // Add numeric prefix from short_name: "1Co" → "1 ", "2Sa" → "2 "
        final prefixMatch = RegExp(r'^(\d+)').firstMatch(shortName);
        if (prefixMatch != null) {
          final digit = prefixMatch.group(1)!;
          // Only prepend if name doesn't already start with that digit
          if (!name.startsWith('$digit ')) name = '$digit $name';
        }

        return name;
      }

      final List<String> books = bookRows
          .map(
            (r) => normaliseBookName(
              r['long_name'] as String,
              r['short_name'] as String? ?? '',
            ),
          )
          .toList();
      final Map<String, int> bookMap = {
        for (int i = 0; i < bookRows.length; i++)
          books[i]: bookRows[i]['book_number'] as int,
      };
      final Map<int, String> byNumber = {
        for (int i = 0; i < bookRows.length; i++)
          bookRows[i]['book_number'] as int: books[i],
      };

      final int? currentBookNum = _selectedBookNumber;
      final int? currentChapter = _selectedChapter;
      List<Map<String, dynamic>> newVerseList = [];
      String? remappedBookName = currentBookNum != null
          ? byNumber[currentBookNum]
          : null;

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

        if (remappedBookName != null) _selectedBook = remappedBookName;

        _verseList = newVerseList;

        _versionLoading = false;
        _initialLoadDone = true;
      });

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
        _selectedBookNumber = bookNumber;
        _chapters = rows.map((r) => r['chapter'] as int).toList();
        _selectedChapter = null;
        _verseList = [];
        _rangeFrom = null;
        _rangeTo = null;
        _previewVerseNum = null;
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
        _previewVerseNum = null;
        if (_verseList.isNotEmpty) {
          _rangeFrom = _verseList.first['verse'] as int;
        } else {
          _rangeFrom = null;
          _rangeTo = null;
        }
      });
    } catch (e) {
      debugPrint('❌ Verses error: $e');
    }
  }

  /// Add the entire current chapter as a single plan item.
  /// [startAtVerse] = the verse index to start projecting from (default 0).
  void _addPickerSelectionToQueue({int startAtVerse = 0}) {
    if (_selectedBook == null ||
        _selectedChapter == null ||
        _verseList.isEmpty) {
      return;
    }

    // Build list of verses with real content (skip empty MSG slots)
    final allContent = <Map<String, dynamic>>[];
    for (int i = 0; i < _verseList.length; i++) {
      final raw = _verseList[i]['text'] as String? ?? '';
      if (ScriptureQueueItem.toPlain(raw).isNotEmpty) {
        allContent.add(_verseList[i]);
      }
    }
    if (allContent.isEmpty) return;

    // Apply From/To verse range if set
    final fromV = _pickerFromVerse;
    final toV = _pickerToVerse;
    final contentVerses = allContent.where((v) {
      final n = v['verse'] as int;
      if (fromV != null && n < fromV) return false;
      if (toV != null && n > toV) return false;
      return true;
    }).toList();
    final filtered = contentVerses.isNotEmpty ? contentVerses : allContent;

    final firstV = filtered.first['verse'] as int;
    final lastV = filtered.last['verse'] as int;

    // Start at first verse of selection
    int liveIdx = 0;

    final item = ScriptureQueueItem(
      book: _selectedBook!,
      chapter: _selectedChapter!,
      startVerse: firstV,
      endVerse: lastV,
      verses: filtered,
      version: _activeVersion,
      liveVerseIndex: liveIdx,
    );

    setState(() {
      // If this book+chapter already exists in the plan, just update it in place
      final existing = _plan.indexWhere(
        (si) =>
            si.type == ServiceItemType.scripture &&
            si.scriptureItem?.book == item.book &&
            si.scriptureItem?.chapter == item.chapter &&
            si.scriptureItem?.version.abbreviation == item.version.abbreviation,
      );

      if (existing >= 0) {
        final existingItem = _itemAt(existing);
        _replaceItemAt(
          existing,
          ServiceItem(
            id: existingItem?.id,
            type: ServiceItemType.scripture,
            scriptureItem: item,
          ),
        );
        _activeIndex = existing;
      } else {
        _addItem(
          ServiceItem(type: ServiceItemType.scripture, scriptureItem: item),
        );
        _activeIndex = _plan.length - 1;
      }
    });
    _saveService(silent: true);
  }

  /// When the operator taps a verse in the overview, if that book+chapter
  /// is already in the plan, advance the live index to that verse and project.
  /// This is the primary way to navigate within a passage during a service.
  void _jumpToVerseInPlan(int verseNum) {
    if (_selectedBook == null || _selectedChapter == null) return;
    final planIdx = _plan.indexWhere(
      (si) =>
          si.type == ServiceItemType.scripture &&
          si.scriptureItem?.book == _selectedBook &&
          si.scriptureItem?.chapter == _selectedChapter &&
          si.scriptureItem?.version.abbreviation == _activeVersion.abbreviation,
    );
    if (planIdx < 0) return; // not in plan yet — just highlight

    final si = (_itemAt(planIdx))!.scriptureItem!;
    final verseIdx = si.verses.indexWhere(
      (v) => (v['verse'] as int) >= verseNum,
    );
    if (verseIdx < 0) return;

    final updated = si.withLiveIndex(verseIdx);
    setState(() {
      _replaceItemAt(
        planIdx,
        ServiceItem(
          id: _itemAt(planIdx)?.id,
          type: ServiceItemType.scripture,
          scriptureItem: updated,
        ),
      );
      _activeIndex = planIdx;
    });
    _scrollPlanToIndex(planIdx);
    _goLive();
    _saveService(silent: true);
  }

  void _selectPlanItem(int index) {
    final item = _itemAt(index);

    if (item?.type == ServiceItemType.scripture &&
        item?.scriptureItem != null) {
      final si = item!.scriptureItem!;

      // ── Treat this exactly like the user typed the reference in the
      //    search bar. Call _selectBook → _selectChapter (the same path
      //    the picker uses) so _verseList is built identically and verse
      //    taps work perfectly afterwards.

      // 1. Mark this queue item as active FIRST (before book/chapter load)
      setState(() => _activeIndex = index);
      _scrollPlanToIndex(index);

      // Load book → chapter via the exact same picker path the user uses,
      // so _verseList is built identically and all verse-row taps work.
      _loadPickersFromScripture(si);
      return;
    }

    // Non-scripture item — just mark active
    setState(() {
      _activeIndex = index;
      _previewVerse = null;
    });
    _scrollPlanToIndex(index);
  }

  /// Load a ScriptureQueueItem into the pickers using the exact same path
  /// as when a user types a reference. Guarantees _verseList is built
  /// identically so verse-row taps always work.
  void _loadPickersFromScripture(ScriptureQueueItem si) {
    _selectBook(si.book);
    Future.delayed(const Duration(milliseconds: 80), () {
      _selectChapter(si.chapter);
      Future.delayed(const Duration(milliseconds: 80), () {
        setState(() {
          _rangeFrom = si.startVerse;
          _rangeTo = si.endVerse != si.startVerse ? si.endVerse : null;
          _previewVerseNum = si.liveVerseNum;
          final firstRow = si.verses.isNotEmpty ? si.verses[0] : null;
          if (firstRow != null) {
            _previewVerse = ScriptureQueueItem(
              book: si.book,
              chapter: si.chapter,
              startVerse: si.startVerse,
              endVerse: si.startVerse,
              verses: [firstRow],
              version: si.version,
            );
          }
        });
        Future.delayed(
          const Duration(milliseconds: 60),
          _scrollOverviewToSelection,
        );
      });
    });
  }

  void _scrollVerseOverviewToLive(int idx) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_verseOverviewScroll.hasClients) return;
      final offset = (idx * _kVerseRowHeight).clamp(
        0.0,
        _verseOverviewScroll.position.maxScrollExtent,
      );
      _verseOverviewScroll.animateTo(
        offset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _removePlanItem(int index) {
    setState(() {
      _removeItemAt(index);
      if (_activeIndex >= _plan.length) {
        _activeIndex = _plan.length - 1;
      }
    });
    _saveService(silent: true);
  }

  void _stepForward() {
    final item = _activeItem;
    if (item != null && item.type == ServiceItemType.scripture) {
      final si = item.scriptureItem!;
      if (si.liveVerseIndex < si.verses.length - 1) {
        // Advance within current passage
        final next = si.withLiveIndex(si.liveVerseIndex + 1);
        setState(() {
          _replaceItemAt(
            _activeIndex,
            ServiceItem(
              id: item.id,
              type: ServiceItemType.scripture,
              scriptureItem: next,
            ),
          );
          _rangeFrom = next.liveVerseNum;
        });
        _scrollVerseOverviewToLive(next.liveVerseIndex);
        _goLive(); // push to projector
        _saveService(silent: true);
        return;
      }
    }
    // Move to next plan item
    if (_activeIndex < _plan.length - 1) {
      setState(() => _activeIndex++);
      _scrollPlanToIndex(_activeIndex);
      final next = _activeItem;
      if (next?.type == ServiceItemType.scripture &&
          next?.scriptureItem != null) {
        _loadPickersFromScripture(next!.scriptureItem!);
      }
    }
  }

  void _stepBack() {
    final item = _activeItem;
    if (item != null && item.type == ServiceItemType.scripture) {
      final si = item.scriptureItem!;
      if (si.liveVerseIndex > 0) {
        // Go back within current passage
        final prev = si.withLiveIndex(si.liveVerseIndex - 1);
        setState(() {
          _replaceItemAt(
            _activeIndex,
            ServiceItem(
              id: item.id,
              type: ServiceItemType.scripture,
              scriptureItem: prev,
            ),
          );
          _rangeFrom = prev.liveVerseNum;
        });
        _scrollVerseOverviewToLive(prev.liveVerseIndex);
        _goLive();
        _saveService(silent: true);
        return;
      }
    }
    // Move to previous plan item
    if (_activeIndex > 0) {
      setState(() => _activeIndex--);
      _scrollPlanToIndex(_activeIndex);
      final prev = _activeItem;
      if (prev?.type == ServiceItemType.scripture &&
          prev?.scriptureItem != null) {
        _loadPickersFromScripture(prev!.scriptureItem!);
      }
    }
  }

  void _addBlackScreen() {
    setState(() {
      _addItem(ServiceItem(type: ServiceItemType.black));
      _activeIndex = _plan.length - 1;
    });
    _saveService(silent: true);
  }

  void _addLogoSlide() {
    setState(() {
      _addItem(ServiceItem(type: ServiceItemType.logo));
      _activeIndex = _plan.length - 1;
    });
    _saveService(silent: true);
  }

  void _confirmClearPlan() {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear service plan?'),
        content: const Text(
          'This will remove all items. This cannot be undone.',
        ),
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
        setState(() {
          _clearAllItems();
          _activeIndex = -1;
        });
        _saveService(silent: true);
      }
    });
  }

  // ── Default announcement content ──────────────────────────────────────────
  static const String _kDefaultAnnouncementTitle = 'Weekly Announcements';
  static const String _kDefaultAnnouncementBody =
      'Welcome to our service! We are glad you joined us today. '
      'Please silence your mobile phones and be respectful during worship.';
  static const List<String> _kDefaultBulletPoints = [
    'Bible study holds every Wednesday at 6:00 PM',
    'Youth fellowship meets every Saturday at 4:00 PM',
    'Tithes and offerings will be received during worship',
    "First-timers are welcome to the visitors' lounge after service",
  ];

  void _showAnnouncementDialog() {
    final t = context.t;
    const amber = Color(0xFFE6A817);
    bool useDefault = true;

    final defTitleCtrl = TextEditingController(
      text: _kDefaultAnnouncementTitle,
    );
    final defBodyCtrl = TextEditingController(text: _kDefaultAnnouncementBody);
    final defBulletCtrls = _kDefaultBulletPoints
        .map((b) => TextEditingController(text: b))
        .toList();
    final newBulletCtrl = TextEditingController();

    final custTitleCtrl = TextEditingController();
    final custBodyCtrl = TextEditingController();
    final custBulletCtrls = <TextEditingController>[];
    final custNewBulletCtrl = TextEditingController();

    String buildFullText({
      required TextEditingController bodyCtrl,
      required List<TextEditingController> bulletCtrls,
    }) {
      final buf = StringBuffer(bodyCtrl.text.trim());
      final valid = bulletCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (valid.isNotEmpty) {
        buf.write('\n\n');
        for (final b in valid) {
          buf.write('• $b\n');
        }
      }
      return buf.toString().trimRight();
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final activeTitleCtrl = useDefault ? defTitleCtrl : custTitleCtrl;
          final activeBodyCtrl = useDefault ? defBodyCtrl : custBodyCtrl;
          final activeBulletCtrls = useDefault
              ? defBulletCtrls
              : custBulletCtrls;
          final activeNewCtrl = useDefault ? newBulletCtrl : custNewBulletCtrl;

          void addBullet() {
            final txt = activeNewCtrl.text.trim();
            if (txt.isEmpty) return;
            setDlg(() {
              activeBulletCtrls.add(TextEditingController(text: txt));
              activeNewCtrl.clear();
            });
          }

          bool canDelete(int i) =>
              !useDefault || i >= _kDefaultBulletPoints.length;

          return Dialog(
            backgroundColor: t.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: amber.withValues(alpha: 0.08),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                      border: Border(bottom: BorderSide(color: t.border)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.campaign_rounded,
                          color: amber,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Add Announcement',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: t.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: t.appBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: t.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _AnnToggleChip(
                                label: 'Default',
                                selected: useDefault,
                                amber: amber,
                                t: t,
                                onTap: () => setDlg(() => useDefault = true),
                              ),
                              _AnnToggleChip(
                                label: 'Custom',
                                selected: !useDefault,
                                amber: amber,
                                t: t,
                                onTap: () => setDlg(() => useDefault = false),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (useDefault)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: amber.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: amber.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 13,
                                    color: amber.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Pre-filled with your church\'s weekly defaults. Edit any text, remove extras, or add new bullets.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: t.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          _DlgField(
                            ctrl: activeTitleCtrl,
                            label: 'Title',
                            t: t,
                          ),
                          const SizedBox(height: 14),
                          _DlgField(
                            ctrl: activeBodyCtrl,
                            label: 'Opening message',
                            t: t,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Text(
                                'BULLET POINTS',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: t.textMuted,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: amber.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  '${activeBulletCtrls.length}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: amber,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...activeBulletCtrls.asMap().entries.map((e) {
                            final i = e.key;
                            final ctrl = e.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: t.appBg,
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(color: t.border),
                              ),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: amber,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: ctrl,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: t.textPrimary,
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 10,
                                            ),
                                        hintText: 'Bullet text…',
                                        hintStyle: TextStyle(
                                          fontSize: 12,
                                          color: t.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (canDelete(i))
                                    InkWell(
                                      onTap: () => setDlg(
                                        () => activeBulletCtrls.removeAt(i),
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 14,
                                          color: t.textMuted,
                                        ),
                                      ),
                                    )
                                  else
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Tooltip(
                                        message: 'Default — text is editable',
                                        child: Icon(
                                          Icons.drag_handle_rounded,
                                          size: 14,
                                          color: t.textMuted.withValues(
                                            alpha: 0.35,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: activeNewCtrl,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: t.textPrimary,
                                  ),
                                  onSubmitted: (_) => addBullet(),
                                  decoration: InputDecoration(
                                    hintText: useDefault
                                        ? 'Add extra bullet point…'
                                        : 'Add bullet point…',
                                    hintStyle: TextStyle(
                                      fontSize: 12,
                                      color: t.textMuted,
                                    ),
                                    filled: true,
                                    fillColor: t.appBg,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(7),
                                      borderSide: BorderSide(color: t.border),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(7),
                                      borderSide: BorderSide(color: t.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(7),
                                      borderSide: const BorderSide(
                                        color: amber,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: addBullet,
                                style: FilledButton.styleFrom(
                                  backgroundColor: amber,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                                child: const Icon(Icons.add, size: 18),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: t.border)),
                    ),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            foregroundColor: t.textSecondary,
                          ),
                          child: const Text('Cancel'),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () {
                            final fullText = buildFullText(
                              bodyCtrl: activeBodyCtrl,
                              bulletCtrls: activeBulletCtrls,
                            );
                            final title = activeTitleCtrl.text.trim();
                            if (fullText.isNotEmpty || title.isNotEmpty) {
                              setState(() {
                                _addItem(
                                  ServiceItem(
                                    type: ServiceItemType.announcement,
                                    announcementTitle: title,
                                    announcementText: fullText,
                                  ),
                                );
                                _activeIndex = _plan.length - 1;
                              });
                              _saveService(silent: true);
                            }
                            Navigator.pop(ctx);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text(
                            'Add to Plan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Message dialog ────────────────────────────────────────────────────────
  void _showMessageDialog() {
    final t = context.t;
    const msgBlue = Color(0xFF42A5F5);

    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          return Dialog(
            backgroundColor: t.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ────────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: msgBlue.withValues(alpha: 0.08),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                      border: Border(bottom: BorderSide(color: t.border)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.message_rounded,
                          color: msgBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Add Message Slide',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: t.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Body ──────────────────────────────────────────────────
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: msgBlue.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: msgBlue.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 13,
                                  color: msgBlue.withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Display a custom text message on the projector — great for welcome greetings, scripture titles, or short notices.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: t.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _DlgField(
                            ctrl: titleCtrl,
                            label: 'Heading (optional)',
                            t: t,
                          ),
                          const SizedBox(height: 14),
                          _DlgField(
                            ctrl: bodyCtrl,
                            label: 'Message body',
                            t: t,
                            maxLines: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ── Footer ────────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: t.border)),
                    ),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            foregroundColor: t.textSecondary,
                          ),
                          child: const Text('Cancel'),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () {
                            final title = titleCtrl.text.trim();
                            final body = bodyCtrl.text.trim();
                            if (title.isNotEmpty || body.isNotEmpty) {
                              setState(() {
                                _addItem(
                                  ServiceItem(
                                    type: ServiceItemType.announcement,
                                    announcementTitle: title.isEmpty
                                        ? 'Message'
                                        : title,
                                    announcementText: body,
                                  ),
                                );
                                _activeIndex = _plan.length - 1;
                              });
                              _saveService(silent: true);
                            }
                            Navigator.pop(ctx);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: msgBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text(
                            'Add to Plan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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

  bool _projectorOpen = false;

  void _goLive() {
    if (_activeItem == null) return;
    final item = _activeItem!;

    _pushHistory(item); // track for reference shelf

    if (item.type == ServiceItemType.black) {
      _clearProjector();
      return;
    }

    if (!_projectorOpen) {
      setState(() => _projectorOpen = true);
      Navigator.of(context)
          .push(
            PageRouteBuilder(
              opaque: true,
              barrierColor: Colors.black,
              pageBuilder: (_, _, _) => ProjectorScreen(
                queueItem: _projectedVerse ?? _activeQueueItem,
                song: _activeSong,
                announcement: item.type == ServiceItemType.announcement
                    ? item
                    : null,
                showLogo: item.type == ServiceItemType.logo,
              ),
              transitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder: (_, anim, _, child) =>
                  FadeTransition(opacity: anim, child: child),
            ),
          )
          .then((_) => setState(() => _projectorOpen = false));
    } else {
      ProjectorNotifier.instance.update(
        queueItem: _projectedVerse ?? _activeQueueItem,
        song: _activeSong,
        announcement: item.type == ServiceItemType.announcement ? item : null,
        showLogo: item.type == ServiceItemType.logo,
      );
    }
  }

  void _clearProjector() {
    ProjectorNotifier.instance.clear();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SERVICE MANAGEMENT — save / load / new
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Directory> get _servicesDir async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/ChurchPresenter/services');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// Save the current service. Pass [silent] = true to suppress the snackbar.
  Future<void> _saveService({bool silent = false}) async {
    try {
      final plan = ServicePlan(
        title: _serviceTitle,
        date: _serviceDate,
        sections: List.from(_sections),
      );
      final dir = await _servicesDir;
      final file = File('${dir.path}/${plan.fileName}');
      await file.writeAsString(jsonEncode(plan.toJson()));
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved "${plan.title}"'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Save failed: $e');
    }
  }

  Future<void> _loadServicePlan() async {
    try {
      final dir = await _servicesDir;
      final files =
          dir
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.json'))
              .toList()
            ..sort(
              (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
            );
      if (files.isEmpty) return;
      final raw = await files.first.readAsString();
      final plan = ServicePlan.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (plan == null || plan.allItems.isEmpty) return;
      if (!mounted) return;
      setState(() {
        _serviceTitle = plan.title;
        _serviceDate = plan.date;
        _sections
          ..clear()
          ..addAll(plan.sections);
        _activeIndex = -1;
        _activeSectionIdx = (plan.sections.length - 1)
            .clamp(0, plan.sections.length - 1)
            .toInt();
      });
    } catch (e) {
      debugPrint('Load latest service failed: $e');
    }
  }

  void _newService() {
    if (_plan.isEmpty) {
      _resetServiceState();
      return;
    }
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New service?'),
        content: const Text(
          'This will clear the current plan. Save first if needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('New service'),
          ),
        ],
      ),
    ).then((ok) {
      if (ok == true) _resetServiceState();
    });
  }

  void _resetServiceState() => setState(() {
    _sections
      ..clear()
      ..add(PlanSection(title: 'Service', items: []));
    _activeIndex = -1;
    _activeSectionIdx = 0;
    _serviceTitle = 'Morning Service';
    _serviceDate = DateTime.now();
  });

  Future<void> _showLoadServiceDialog() async {
    final dir = await _servicesDir;
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList()
          ..sort(
            (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
          );

    if (!mounted) return;

    if (files.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No saved services found.')));
      return;
    }

    final t = context.t;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        title: Text(
          'Load service',
          style: TextStyle(
            color: t.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: 420,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: files.length,
            separatorBuilder: (_, _) => Divider(color: t.border, height: 1),
            itemBuilder: (_, i) {
              final f = files[i];
              final name = f.uri.pathSegments.last
                  .replaceAll('.json', '')
                  .replaceAll('_', ' ');
              final mod = f.statSync().modified;
              return ListTile(
                dense: true,
                title: Text(
                  name,
                  style: TextStyle(fontSize: 13, color: t.textPrimary),
                ),
                subtitle: Text(
                  'Saved ${mod.day}/${mod.month}/${mod.year} ${mod.hour}:${mod.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 10, color: t.textMuted),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: t.textMuted,
                  ),
                  tooltip: 'Delete',
                  onPressed: () async {
                    await f.delete();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final raw = await f.readAsString();
                    final plan = ServicePlan.fromJson(
                      jsonDecode(raw) as Map<String, dynamic>,
                    );
                    if (plan == null) return;
                    if (!mounted) return;
                    setState(() {
                      _serviceTitle = plan.title;
                      _serviceDate = plan.date;
                      _sections
                        ..clear()
                        ..addAll(plan.sections);
                      _activeIndex = -1;
                    });
                  } catch (e) {
                    debugPrint('Load failed: $e');
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: t.textMuted)),
          ),
        ],
      ),
    );
  }

  void _editServiceTitle() {
    final ctrl = TextEditingController(text: _serviceTitle);
    final t = context.t;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        title: Text(
          'Service title',
          style: TextStyle(
            color: t.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(fontSize: 14, color: t.textPrimary),
          onSubmitted: (_) {
            setState(
              () => _serviceTitle = ctrl.text.trim().isEmpty
                  ? _serviceTitle
                  : ctrl.text.trim(),
            );
            Navigator.pop(ctx);
          },
          decoration: InputDecoration(
            hintText: 'e.g. Sunday Morning Service',
            hintStyle: TextStyle(color: t.textMuted),
            filled: true,
            fillColor: t.appBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: t.border),
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
              if (ctrl.text.trim().isNotEmpty) {
                setState(() => _serviceTitle = ctrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickServiceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _serviceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null) setState(() => _serviceDate = picked);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUICK-ADD
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _quickAddItems(String raw) async {
    if (raw.trim().isEmpty) return;
    _quickAddCtrl.clear();

    final parts = raw
        .split(RegExp(r'[,;]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    int added = 0;
    for (final part in parts) {
      final lower = part.toLowerCase();

      if (lower == 'black' || lower == 'black screen') {
        setState(() => _addItem(ServiceItem(type: ServiceItemType.black)));
        added++;
        continue;
      }
      if (lower == 'logo') {
        setState(() => _addItem(ServiceItem(type: ServiceItemType.logo)));
        added++;
        continue;
      }

      final songMatch = _songs.firstWhere(
        (s) => (s['title'] ?? '').toLowerCase().contains(lower),
        orElse: () => {},
      );
      if (songMatch.isNotEmpty) {
        setState(
          () => _addItem(
            ServiceItem(type: ServiceItemType.song, song: songMatch),
          ),
        );
        added++;
        continue;
      }

      final item = await _resolveReferenceToQueueItem(part);
      if (item != null) {
        setState(
          () => _addItem(
            ServiceItem(type: ServiceItemType.scripture, scriptureItem: item),
          ),
        );
        added++;
      }
    }

    if (added > 0) {
      setState(() => _activeIndex = _plan.length - 1);
      _saveService(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added $added item${added == 1 ? "" : "s"} to service plan',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not resolve any items — check the references'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<ScriptureQueueItem?> _resolveReferenceToQueueItem(String ref) async {
    // FIX: was _databaseLoaded (undefined); use _database != null instead
    if (_database == null) return null;
    try {
      String s = ref.trim();

      final sp = s.split(RegExp(r'\s+'));
      if (!s.contains(':') && sp.length == 3) {
        final c = int.tryParse(sp[sp.length - 2]);
        final v = int.tryParse(sp[sp.length - 1]);
        if (c != null && v != null) {
          s = '${sp.sublist(0, sp.length - 2).join(' ')} $c:$v';
        }
      }
      s = s.replaceFirstMapped(
        RegExp(r'^(\d?[a-zA-Z\s]+?)(\d)'),
        (m) => '${m[1]} ${m[2]}',
      );

      final tokens = s.trim().split(RegExp(r'\s+'));
      String matchedBook = '';
      int afterIdx = 0;
      final full = _BookAliasResolver.resolve(tokens.join(' '), _bibleBooks);
      if (full.isNotEmpty) {
        matchedBook = full;
        afterIdx = tokens.length;
      } else {
        for (int len = tokens.length - 1; len >= 1; len--) {
          final cand = _BookAliasResolver.resolve(
            tokens.sublist(0, len).join(' '),
            _bibleBooks,
          );
          if (cand.isNotEmpty) {
            matchedBook = cand;
            afterIdx = len;
            break;
          }
        }
      }
      if (matchedBook.isEmpty) return null;

      final rest = tokens.sublist(afterIdx).join(' ').trim();
      int? chapter, startVerse, endVerse;

      if (rest.isEmpty) {
        chapter = 1;
        startVerse = 1;
        endVerse = 1;
      } else if (!rest.contains(':')) {
        chapter = int.tryParse(rest);
        startVerse = 1;
        endVerse = 1;
      } else {
        final cv = rest.split(':');
        chapter = int.tryParse(cv[0].trim());
        final verseRange = cv[1].trim().split(RegExp(r'[-–—]'));
        startVerse = int.tryParse(verseRange[0].trim());
        endVerse = verseRange.length > 1
            ? int.tryParse(verseRange[1].trim())
            : startVerse;
      }
      if (chapter == null || startVerse == null) return null;
      endVerse ??= startVerse;

      final bookNum = _bookNumberMap[matchedBook];
      if (bookNum == null) return null;

      // Always fetch the WHOLE chapter — navigation happens in the overview
      final allRows = _database!.select(
        'SELECT verse, text FROM verses WHERE book_number=? AND chapter=? ORDER BY verse',
        [bookNum, chapter],
      );
      if (allRows.isEmpty) return null;

      // Filter to content verses (non-empty after tag stripping)
      final contentVerses = allRows
          .map(
            (r) => {
              'verse': r['verse'] as int,
              'text': r['text'] as String? ?? '',
            },
          )
          .where(
            (r) => ScriptureQueueItem.toPlain(r['text'] as String).isNotEmpty,
          )
          .toList();
      if (contentVerses.isEmpty) return null;

      // Find the starting index based on the typed verse number
      int liveIdx = 0;
      if (startVerse > 1) {
        final found = contentVerses.indexWhere(
          (v) => (v['verse'] as int) >= startVerse!,
        );
        if (found >= 0) liveIdx = found;
      }

      final firstV = contentVerses.first['verse'] as int;
      final lastV = contentVerses.last['verse'] as int;

      return ScriptureQueueItem(
        book: matchedBook,
        chapter: chapter,
        startVerse: firstV,
        endVerse: lastV,
        version: _activeVersion,
        liveVerseIndex: liveIdx,
        verses: contentVerses,
      );
    } catch (e) {
      debugPrint('Resolve reference failed for "$ref": $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SMART SEARCH — live full-text verse search + reference detection
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns true if [query] looks like a scripture reference
  /// (recognisable book name/alias followed by optional chapter/verse digits).
  bool _looksLikeReference(String query) {
    final q = query.trim();
    if (q.isEmpty) return false;
    // Must start with letters (optionally preceded by a digit for "1John" etc.)
    if (!RegExp(r'^[\d]?[a-zA-Z]').hasMatch(q)) return false;
    // Try resolving any prefix of the space/colon-split tokens as a book name
    final tokens = q.split(RegExp(r'[\s:]+'));
    for (int len = tokens.length; len > 0; len--) {
      final candidate = tokens
          .sublist(0, len)
          .join(' ')
          .replaceAll(RegExp(r'\d+$'), '')
          .trim();
      if (candidate.length < 2) continue;
      if (_BookAliasResolver.resolve(candidate, _bibleBooks).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  /// Called on every keystroke in the scripture search bar.
  void _onSearchChanged(String value) {
    final q = value.trim();
    if (q.isEmpty) {
      _removeSearchOverlay();
      setState(() => _searchResults = []);
      return;
    }
    // Reference-style input: no live overlay, just wait for Enter.
    if (_looksLikeReference(q)) {
      _removeSearchOverlay();
      return;
    }
    // Free-text: need at least 3 chars before searching.
    if (q.length >= 3) {
      _runFullTextSearch(q);
    } else {
      _removeSearchOverlay();
    }
  }

  /// Called when Enter is pressed or the Go button is tapped.
  void _onSearchSubmitted(String value) {
    final q = value.trim();
    if (q.isEmpty) return;
    if (_looksLikeReference(q)) {
      _removeSearchOverlay();
      _parseAndJumpToReference(q);
      return;
    }
    // Free-text: navigate to top result if available.
    if (_searchResults.isNotEmpty) {
      _navigateToSearchResult(_searchResults.first);
    }
  }

  /// Score a verse against the query words.
  ///
  /// Scoring rationale:
  ///   +1.0  per matched query word (partial)
  ///   +2.0  bonus when ALL query words are present
  ///   +4.0  bonus when the full phrase appears verbatim
  ///   +3.0  bonus when all words appear in order (proximity)
  ///   −0.1  per extra word in verse beyond query length (prefer shorter verses)
  double _scoreVerse(String plain, List<String> words, String fullQuery) {
    double score = 0;
    int matched = 0;

    for (final w in words) {
      if (plain.contains(w)) {
        score += 1.0;
        matched++;
      }
    }
    if (matched == 0) return 0;

    // All-words bonus
    if (matched == words.length) score += 2.0;

    // Verbatim phrase bonus
    if (plain.contains(fullQuery)) score += 4.0;

    // Word-order proximity bonus: check if words appear in order
    // by walking through the plain text looking for each word sequentially.
    if (matched == words.length) {
      int searchFrom = 0;
      bool inOrder = true;
      for (final w in words) {
        final idx = plain.indexOf(w, searchFrom);
        if (idx == -1) {
          inOrder = false;
          break;
        }
        searchFrom = idx + w.length;
      }
      if (inOrder) score += 3.0;
    }

    // Small penalty for very long verses (prefer concise matches)
    final verseWordCount = plain.split(RegExp(r'\s+')).length;
    if (verseWordCount > words.length) {
      score -= (verseWordCount - words.length) * 0.05;
    }

    return score;
  }

  /// Query the DB and rank results. Shows overlay with up to 12 hits.
  void _runFullTextSearch(String query) {
    if (_database == null) return;

    final fullQuery = query.toLowerCase().trim();
    final words = fullQuery
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 2)
        .toSet()
        .toList();
    if (words.isEmpty) {
      _removeSearchOverlay();
      return;
    }

    try {
      // Build SQL: at least one word must match — let Dart do precise scoring.
      final conditions = words.map((_) => "LOWER(v.text) LIKE ?").join(' OR ');
      final params = words.map((w) => '%$w%').toList();

      final rows = _database!.select(
        'SELECT v.book_number, v.chapter, v.verse, v.text '
        'FROM verses v WHERE $conditions LIMIT 400',
        params,
      );

      final results = <_VerseSearchResult>[];
      for (final row in rows) {
        final raw = row['text'] as String? ?? '';
        // Strip markup tags for plain scoring
        final plain = raw
            .replaceAll(RegExp(r'<[^>]+>'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .toLowerCase()
            .trim();

        final score = _scoreVerse(plain, words, fullQuery);
        if (score <= 0) continue;

        final bookNum = row['book_number'] as int;
        results.add(
          _VerseSearchResult(
            book: _bookByNumber[bookNum] ?? 'Unknown',
            bookNumber: bookNum,
            chapter: row['chapter'] as int,
            verse: row['verse'] as int,
            text: raw,
            score: score,
          ),
        );
      }

      // Sort: highest score first; tie-break by book order (canonical order)
      results.sort((a, b) {
        final cmp = b.score.compareTo(a.score);
        if (cmp != 0) return cmp;
        return a.bookNumber.compareTo(b.bookNumber);
      });

      setState(() => _searchResults = results.take(12).toList());

      if (_searchResults.isNotEmpty) {
        _showSearchOverlay();
      } else {
        _removeSearchOverlay();
      }
    } catch (e) {
      debugPrint('Full-text search error: $e');
    }
  }

  void _navigateToSearchResult(_VerseSearchResult result) {
    _removeSearchOverlay();
    _searchController.clear();
    setState(() => _searchResults = []);
    _selectBook(result.book);
    Future.delayed(const Duration(milliseconds: 80), () {
      _selectChapter(result.chapter);
      Future.delayed(const Duration(milliseconds: 80), () {
        setState(() => _rangeFrom = result.verse);
        Future.delayed(
          const Duration(milliseconds: 60),
          _scrollOverviewToSelection,
        );
      });
    });
  }

  void _onSearchFocusChange() {
    if (!_searchFocus.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_searchFocus.hasFocus) _removeSearchOverlay();
      });
    }
  }

  void _showSearchOverlay() {
    _removeSearchOverlay();
    final overlay = Overlay.of(context);
    _searchOverlay = OverlayEntry(builder: (_) => _buildSearchOverlayWidget());
    overlay.insert(_searchOverlay!);
  }

  void _removeSearchOverlay() {
    _searchOverlay?.remove();
    _searchOverlay = null;
  }

  Widget _buildSearchOverlayWidget() {
    final t = AppTheme.of(context);
    return Positioned(
      width: kPanelWidth - 24,
      child: CompositedTransformFollower(
        link: _searchBarLink,
        showWhenUnlinked: false,
        offset: const Offset(12, 52),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(10),
          color: t.surfaceHigh,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: StatefulBuilder(
                builder: (ctx, setSt) {
                  final results = _searchResults;
                  if (results.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        'No verses found',
                        style: TextStyle(fontSize: 12, color: t.textMuted),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: results.length,
                    // ignore: unnecessary_underscores
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: t.border),
                    itemBuilder: (_, i) {
                      final r = results[i];
                      final ref = '${r.book} ${r.chapter}:${r.verse}';
                      final plain = r.text
                          .replaceAll(RegExp(r'<[^>]+>'), '')
                          .trim();
                      final preview = plain.length > 90
                          ? '${plain.substring(0, 90)}…'
                          : plain;
                      return InkWell(
                        onTap: () => _navigateToSearchResult(r),
                        hoverColor: t.accentBlue.withValues(alpha: 0.08),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: t.accentBlue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  ref,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: t.accentBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                preview,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: t.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Reference error helper ───────────────────────────────────────────────
  void _showRefError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFB00020),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _parseAndJumpToReference(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;
    if (_database == null) return;

    String normalised = trimmed;

    final sp = normalised.split(RegExp(r'\s+'));
    if (!normalised.contains(':') && sp.length == 3) {
      final c = int.tryParse(sp[sp.length - 2]);
      final v = int.tryParse(sp[sp.length - 1]);
      if (c != null && v != null) {
        normalised = '${sp.sublist(0, sp.length - 2).join(' ')} $c:$v';
      }
    }

    normalised = normalised.replaceFirstMapped(
      RegExp(r'^(\d?[a-zA-Z\s]+?)(\d)'),
      (m) => '${m[1]} ${m[2]}',
    );

    final ref = normalised.trim();
    final tokens = ref.split(RegExp(r'\s+'));

    String matchedBook = '';
    int afterIdx = 0;

    final fullCandidate = _BookAliasResolver.resolve(
      tokens.join(' '),
      _bibleBooks,
    );
    if (fullCandidate.isNotEmpty) {
      matchedBook = fullCandidate;
      afterIdx = tokens.length;
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

    // ── Book not found ────────────────────────────────────────────────────
    if (matchedBook.isEmpty) {
      // Extract what the user typed as the book portion for a helpful message
      final bookGuess = tokens.first;
      _showRefError(
        'Book not found: "$bookGuess". Check spelling or try an abbreviation (e.g. "Gen", "Rev", "1Co").',
      );
      return;
    }

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

    // ── Validate chapter before touching any pickers ──────────────────────
    if (chapter != null) {
      final bookNum = _bookNumberMap[matchedBook];
      if (bookNum != null) {
        try {
          final chapRows = _database!.select(
            'SELECT DISTINCT chapter FROM verses WHERE book_number = ? ORDER BY chapter',
            [bookNum],
          );
          final validChapters = chapRows
              .map((r) => r['chapter'] as int)
              .toList();
          if (validChapters.isNotEmpty && !validChapters.contains(chapter)) {
            final maxCh = validChapters.last;
            _showRefError(
              '$matchedBook only has $maxCh chapter${maxCh == 1 ? "" : "s"} — chapter $chapter doesn\'t exist.',
            );
            return;
          }
        } catch (_) {}
      }
    }

    _selectBook(matchedBook);
    _searchController.clear();

    if (chapter == null) return;

    Future.delayed(const Duration(milliseconds: 80), () {
      _selectChapter(chapter!);

      if (startVerse == null) return;

      Future.delayed(const Duration(milliseconds: 80), () {
        // ── Validate verses against what was actually loaded ────────────
        if (!mounted) return;
        final loadedVerses = _verseList.map((v) => v['verse'] as int).toList();
        if (loadedVerses.isEmpty) {
          _showRefError('No verses found for $matchedBook $chapter.');
          return;
        }
        final maxVerse = loadedVerses.last;
        final minVerse = loadedVerses.first;

        // Clamp end verse silently (e.g. typed v30 but chapter only has 25)
        final clampedEnd = endVerse != null
            ? endVerse!.clamp(minVerse, maxVerse)
            : null;
        final clampedStart = startVerse!.clamp(minVerse, maxVerse);

        // Warn if start verse is completely out of range
        if (!loadedVerses.contains(clampedStart)) {
          _showRefError(
            '$matchedBook $chapter only has verses $minVerse–$maxVerse. Verse $startVerse doesn\'t exist.',
          );
          return;
        }

        // Soft warning if end was clamped
        if (clampedEnd != null && clampedEnd != endVerse) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$matchedBook $chapter only has $maxVerse verses — range clamped to v$clampedStart–v$clampedEnd.',
                style: const TextStyle(fontSize: 13),
              ),
              backgroundColor: const Color(0xFF5C4200),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }

        setState(() {
          _rangeFrom = clampedStart;
          if (clampedEnd != null && clampedEnd != clampedStart) {
            _rangeTo = clampedEnd;
          } else {
            _rangeTo = null;
          }
        });
        Future.delayed(
          const Duration(milliseconds: 60),
          _scrollOverviewToSelection,
        );
      });
    });
  }

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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.accent});
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.t.surfaceHigh,
        border: Border(bottom: BorderSide(color: context.t.border)),
      ),
      child: Row(
        children: [
          Icon(
            label == 'SONGS'
                ? Icons.music_note_rounded
                : Icons.menu_book_rounded,
            size: 13,
            color: accent,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.t.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

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
    final T? safeValue = (value != null && items.contains(value))
        ? value
        : null;

    return DropdownButtonFormField<T>(
      initialValue: safeValue,
      onChanged: onChanged,
      isExpanded: true,
      menuMaxHeight: 220,
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
              child: Text(
                labelBuilder(v),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: context.t.textPrimary),
              ),
            ),
          )
          .toList(),
    );
  }
}

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

class _PreviewTextCard extends StatelessWidget {
  const _PreviewTextCard({
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
      fontSize: fontSize,
      height: 1.85,
      color: t.textPrimary,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
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
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: textAlign == TextAlign.center
            ? Alignment.center
            : Alignment.centerLeft,
        child: child,
      ),
    );
  }
}

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

class _IconTip extends StatelessWidget {
  const _IconTip({
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

class _PreviewActionButton extends StatelessWidget {
  const _PreviewActionButton({
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
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: t.textPrimary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        onExit: (_) => setState(() => _hovered = false),
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

// ── Compact book picker — shows a small filtered overlay, not a full-screen list ──

// ─────────────────────────────────────────────────────────────────────────────
// VERSE RANGE SELECTOR  —  inline pill strip, click-to-set from/to
// ─────────────────────────────────────────────────────────────────────────────
//
// UX:
//   • If nothing selected: click any verse → sets "from", "to" stays null (whole
//     chapter from that point).
//   • If "from" is set but no "to": click a verse AFTER from → sets "to".
//     Click a verse BEFORE from → resets range to that new start.
//   • If both set: click anywhere → resets to just that verse as new "from".
//   • Hover preview: hovering shows what the second endpoint would be.
//   • A small "Clear" chip is shown when any selection is active.

class _VerseRangeSelector extends StatefulWidget {
  const _VerseRangeSelector({
    required this.verses,
    required this.fromVerse,
    required this.toVerse,
    required this.onRangeChanged,
  });

  final List<Map<String, dynamic>> verses;
  final int? fromVerse;
  final int? toVerse;
  final void Function(int? from, int? to) onRangeChanged;

  @override
  State<_VerseRangeSelector> createState() => _VerseRangeSelectorState();
}

class _VerseRangeSelectorState extends State<_VerseRangeSelector> {
  int? _hovered;

  void _onTap(int vNum) {
    final from = widget.fromVerse;
    final to = widget.toVerse;

    if (from == null) {
      // Nothing selected yet → set from
      widget.onRangeChanged(vNum, null);
    } else if (to == null) {
      // From set, to not set
      if (vNum == from) {
        // Tapped same verse → clear
        widget.onRangeChanged(null, null);
      } else if (vNum > from) {
        // Extend range
        widget.onRangeChanged(from, vNum);
      } else {
        // Tapped before from → restart
        widget.onRangeChanged(vNum, null);
      }
    } else {
      // Both set → restart from tapped verse
      if (vNum == from && to == from) {
        widget.onRangeChanged(null, null);
      } else {
        widget.onRangeChanged(vNum, null);
      }
    }
  }

  bool _isInRange(int vNum) {
    final from = widget.fromVerse;
    final to = widget.toVerse ?? widget.fromVerse;
    if (from == null) return false;
    return vNum >= from && vNum <= (to ?? from);
  }

  bool _isInHoverPreview(int vNum) {
    final from = widget.fromVerse;
    final hov = _hovered;
    if (from == null || hov == null || widget.toVerse != null) return false;
    if (hov <= from) return false; // only preview extending right
    return vNum > from && vNum <= hov;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final verses = widget.verses;
    final from = widget.fromVerse;
    final to = widget.toVerse;
    final hasSelection = from != null;
    final hasRange = from != null && to != null && to != from;

    // Label summary
    String summary;
    if (!hasSelection) {
      summary = 'Tap to select verse range';
    } else if (!hasRange) {
      summary = 'v$from  → tap another to set end';
    } else {
      summary = 'v$from – v$to';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with label + clear button
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            children: [
              Text(
                'VERSES',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: t.textMuted,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  summary,
                  style: TextStyle(
                    fontSize: 10,
                    color: hasRange ? t.accentBlue : t.textMuted,
                    fontWeight: hasRange ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasSelection)
                GestureDetector(
                  onTap: () => widget.onRangeChanged(null, null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: t.accentBlue.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: t.accentBlue,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Pill strip
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: verses.map((v) {
            final vNum = v['verse'] as int;
            final isFrom = vNum == from;
            final isTo = vNum == to;
            final inRange = _isInRange(vNum);
            final inPreview = _isInHoverPreview(vNum);

            Color bg;
            Color border;
            Color textColor;

            if (isFrom || isTo) {
              bg = t.accentBlue;
              border = t.accentBlue;
              textColor = Colors.white;
            } else if (inRange) {
              bg = t.accentBlue.withValues(alpha: 0.22);
              border = t.accentBlue.withValues(alpha: 0.5);
              textColor = t.accentBlue;
            } else if (inPreview) {
              bg = t.accentBlue.withValues(alpha: 0.10);
              border = t.accentBlue.withValues(alpha: 0.30);
              textColor = t.accentBlue.withValues(alpha: 0.8);
            } else if (_hovered == vNum) {
              bg = t.surfaceHigh;
              border = t.accentBlue.withValues(alpha: 0.4);
              textColor = t.textPrimary;
            } else {
              bg = t.surfaceHigh;
              border = t.border;
              textColor = t.textSecondary;
            }

            return MouseRegion(
              onEnter: (_) => setState(() => _hovered = vNum),
              onExit: (_) => setState(() => _hovered = null),
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _onTap(vNum),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: border, width: 1),
                  ),
                  child: Text(
                    '$vNum',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: (isFrom || isTo)
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VERSE RANGE PICKER  (legacy — kept for coordinator wiring, no longer shown)
// ─────────────────────────────────────────────────────────────────────────────

class _VerseRangePickerField extends StatefulWidget {
  const _VerseRangePickerField({
    required this.label,
    required this.verses,
    required this.selectedVerse,
    required this.enabled,
    required this.onSelected,
    required this.coordinator,
    this.minVerse,
  });
  final String label;
  final List<Map<String, dynamic>> verses;
  final int? selectedVerse;
  final bool enabled;
  final ValueChanged<int?> onSelected;
  final _DropdownCoordinator coordinator;
  final int? minVerse;

  @override
  State<_VerseRangePickerField> createState() => _VerseRangePickerFieldState();
}

class _VerseRangePickerFieldState extends State<_VerseRangePickerField> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _overlay;
  int _hovered = -1;

  String get _id => 'verse_${widget.label}';

  @override
  void initState() {
    super.initState();
    widget.coordinator.addListener(_onCoordChange);
  }

  @override
  void didUpdateWidget(_VerseRangePickerField old) {
    super.didUpdateWidget(old);
    if (old.coordinator != widget.coordinator) {
      old.coordinator.removeListener(_onCoordChange);
      widget.coordinator.addListener(_onCoordChange);
    }
  }

  @override
  void dispose() {
    widget.coordinator.removeListener(_onCoordChange);
    _removeOverlay();
    super.dispose();
  }

  void _onCoordChange() {
    if (!widget.coordinator.isOpen(_id)) _removeOverlay();
  }

  List<Map<String, dynamic>> get _filtered => widget.minVerse == null
      ? widget.verses
      : widget.verses
            .where((v) => (v['verse'] as int) >= widget.minVerse!)
            .toList();

  void _toggle() {
    if (_overlay != null) {
      _removeOverlay();
      widget.coordinator.notifyClosed(_id);
      return;
    }
    if (widget.coordinator.requestOpen(_id)) _showOverlay();
  }

  void _pick(int v) {
    _removeOverlay();
    widget.coordinator.notifyClosed(_id);
    widget.onSelected(v);
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    _overlay = OverlayEntry(
      builder: (ctx) {
        final t = AppTheme.of(context);
        final items = _filtered;
        return Positioned(
          width: 120,
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: const Offset(0, 38),
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              color: t.surfaceHigh,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: StatefulBuilder(
                  builder: (ctx, setSt) {
                    if (items.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'No verses',
                          style: TextStyle(fontSize: 12, color: t.textMuted),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final vNum = items[i]['verse'] as int;
                        final isHov = _hovered == i;
                        final isSel = vNum == widget.selectedVerse;
                        return MouseRegion(
                          onEnter: (_) => setSt(() => _hovered = i),
                          onExit: (_) => setSt(() => _hovered = -1),
                          child: GestureDetector(
                            onTap: () => _pick(vNum),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: isHov || isSel
                                    ? t.accentBlue.withValues(alpha: 0.12)
                                    : Colors.transparent,
                                border: Border(
                                  left: BorderSide(
                                    color: isHov || isSel
                                        ? t.accentBlue
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                'v$vNum',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isHov || isSel
                                      ? t.accentBlue
                                      : t.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final label = widget.selectedVerse != null
        ? 'v${widget.selectedVerse}'
        : null;
    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onTap: widget.enabled ? _toggle : null,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.enabled ? t.appBg : t.appBg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.border),
          ),
          child: Row(
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 10,
                  color: t.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label ?? '—',
                  style: TextStyle(
                    fontSize: 12,
                    color: label != null ? t.textPrimary : t.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: t.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAPTER PICKER  —  compact overlay, same style as _BookPickerField
// ─────────────────────────────────────────────────────────────────────────────

class _ChapterPickerField extends StatefulWidget {
  const _ChapterPickerField({
    required this.chapters,
    required this.selectedChapter,
    required this.enabled,
    required this.onSelected,
    required this.coordinator,
  });
  final List<int> chapters;
  final int? selectedChapter;
  final bool enabled;
  final ValueChanged<int?> onSelected;
  final _DropdownCoordinator coordinator;

  @override
  State<_ChapterPickerField> createState() => _ChapterPickerFieldState();
}

class _ChapterPickerFieldState extends State<_ChapterPickerField> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _overlay;
  int _hovered = -1;

  static const String _id = 'chapter';

  @override
  void initState() {
    super.initState();
    widget.coordinator.addListener(_onCoordChange);
  }

  @override
  void didUpdateWidget(_ChapterPickerField old) {
    super.didUpdateWidget(old);
    if (old.coordinator != widget.coordinator) {
      old.coordinator.removeListener(_onCoordChange);
      widget.coordinator.addListener(_onCoordChange);
    }
  }

  @override
  void dispose() {
    widget.coordinator.removeListener(_onCoordChange);
    _removeOverlay();
    super.dispose();
  }

  void _onCoordChange() {
    if (!widget.coordinator.isOpen(_id)) _removeOverlay();
  }

  void _toggle() {
    if (_overlay != null) {
      _removeOverlay();
      widget.coordinator.notifyClosed(_id);
      return;
    }
    if (widget.coordinator.requestOpen(_id)) _showOverlay();
  }

  void _pick(int ch) {
    _removeOverlay();
    widget.coordinator.notifyClosed(_id);
    widget.onSelected(ch);
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    _overlay = OverlayEntry(
      builder: (ctx) {
        final t = AppTheme.of(context);
        return Positioned(
          width: 110,
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: const Offset(0, 38),
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              color: t.surfaceHigh,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: StatefulBuilder(
                  builder: (ctx, setSt) {
                    if (widget.chapters.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'No chapters',
                          style: TextStyle(fontSize: 12, color: t.textMuted),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shrinkWrap: true,
                      itemCount: widget.chapters.length,
                      itemBuilder: (_, i) {
                        final ch = widget.chapters[i];
                        final isHov = _hovered == i;
                        final isSel = ch == widget.selectedChapter;
                        return MouseRegion(
                          onEnter: (_) => setSt(() => _hovered = i),
                          onExit: (_) => setSt(() => _hovered = -1),
                          child: GestureDetector(
                            onTap: () => _pick(ch),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isHov || isSel
                                    ? t.accentBlue.withValues(alpha: 0.12)
                                    : Colors.transparent,
                                border: Border(
                                  left: BorderSide(
                                    color: isHov || isSel
                                        ? t.accentBlue
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Ch. $ch',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isHov || isSel
                                      ? t.accentBlue
                                      : t.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final label = widget.selectedChapter != null
        ? 'Ch. ${widget.selectedChapter}'
        : null;
    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onTap: widget.enabled ? _toggle : null,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: widget.enabled ? t.appBg : t.appBg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label ?? 'Ch.',
                  style: TextStyle(
                    fontSize: 13,
                    color: label != null ? t.textPrimary : t.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: t.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookPickerField extends StatefulWidget {
  const _BookPickerField({
    required this.books,
    required this.selectedBook,
    required this.enabled,
    required this.onSelected,
    required this.coordinator,
  });

  final List<String> books;
  final String? selectedBook;
  final bool enabled;
  final ValueChanged<String> onSelected;
  final _DropdownCoordinator coordinator;

  @override
  State<_BookPickerField> createState() => _BookPickerFieldState();
}

class _BookPickerFieldState extends State<_BookPickerField> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();
  final LayerLink _link = LayerLink();
  OverlayEntry? _overlay;
  List<String> _filtered = [];
  int _hovered = -1;

  static const String _id = 'book';

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.selectedBook ?? '';
    _focus.addListener(_onFocusChange);
    widget.coordinator.addListener(_onCoordChange);
  }

  @override
  void didUpdateWidget(_BookPickerField old) {
    super.didUpdateWidget(old);
    if (widget.selectedBook != old.selectedBook) {
      _ctrl.text = widget.selectedBook ?? '';
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    }
    if (old.coordinator != widget.coordinator) {
      old.coordinator.removeListener(_onCoordChange);
      widget.coordinator.addListener(_onCoordChange);
    }
  }

  @override
  void dispose() {
    widget.coordinator.removeListener(_onCoordChange);
    _removeOverlay();
    _ctrl.dispose();
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    super.dispose();
  }

  void _onCoordChange() {
    if (!widget.coordinator.isOpen(_id)) {
      _removeOverlay();
    }
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!_focus.hasFocus) {
          _ctrl.text = widget.selectedBook ?? '';
          _removeOverlay();
          widget.coordinator.notifyClosed(_id);
        }
      });
    }
  }

  void _onChanged(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? widget.books
          : widget.books.where((b) => b.toLowerCase().contains(q)).toList();
      _hovered = -1;
    });
    if (widget.coordinator.requestOpen(_id)) {
      _showOverlay();
    } else {
      // Already open — just rebuild the overlay content
      _overlay?.markNeedsBuild();
    }
  }

  void _pick(String book) {
    _ctrl.text = book;
    _ctrl.selection = TextSelection.collapsed(offset: book.length);
    _removeOverlay();
    widget.coordinator.notifyClosed(_id);
    _focus.unfocus();
    widget.onSelected(book);
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    _overlay = OverlayEntry(
      builder: (ctx) {
        final t = AppTheme.of(context);
        return Positioned(
          width: 220,
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: const Offset(0, 38),
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              color: t.surfaceHigh,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: StatefulBuilder(
                  builder: (ctx, setSt) {
                    if (_filtered.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'No match',
                          style: TextStyle(fontSize: 12, color: t.textMuted),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shrinkWrap: true,
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final book = _filtered[i];
                        final isHov = _hovered == i;
                        return MouseRegion(
                          onEnter: (_) => setSt(() => _hovered = i),
                          onExit: (_) => setSt(() => _hovered = -1),
                          child: GestureDetector(
                            onTap: () => _pick(book),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isHov
                                    ? t.accentBlue.withValues(alpha: 0.12)
                                    : Colors.transparent,
                                border: Border(
                                  left: BorderSide(
                                    color: isHov
                                        ? t.accentBlue
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                book,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isHov ? t.accentBlue : t.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return CompositedTransformTarget(
      link: _link,
      child: TextField(
        controller: _ctrl,
        focusNode: _focus,
        enabled: widget.enabled,
        style: TextStyle(fontSize: 13, color: t.textPrimary),
        onChanged: _onChanged,
        onTap: () {
          _filtered = widget.books;
          _showOverlay();
        },
        decoration: InputDecoration(
          hintText: 'Book',
          hintStyle: TextStyle(fontSize: 12, color: t.textMuted),
          isDense: true,
          filled: true,
          fillColor: widget.enabled ? t.appBg : t.appBg.withValues(alpha: 0.5),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 9,
            horizontal: 12,
          ),
          suffixIcon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: t.textMuted,
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
            borderSide: BorderSide(color: t.accentBlue, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: t.border.withValues(alpha: 0.4)),
          ),
        ),
      ),
    );
  }
}

class _AnnToggleChip extends StatelessWidget {
  const _AnnToggleChip({
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
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.black : t.textSecondary,
          ),
        ),
      ),
    );
  }
}

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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
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
