// ─────────────────────────────────────────────────────────────────────────────
// HOME SCREEN  —  thin orchestrator
//
// This file owns ALL mutable state and wires the panel widgets together.
// It contains NO widget-building code beyond the top-level layout Row.
//
// If something looks wrong on screen → check the relevant widget file.
// If something behaves wrong (wrong data, wrong state change) → look here.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;

import '../app_theme.dart';
import '../models.dart';
import '../utils/book_alias_resolver.dart';
import 'projector_screen.dart';

// Panel widgets
import '../widgets/scripture_panel.dart';
import '../widgets/verse_overview_panel.dart';
import '../widgets/song_panel.dart';
import '../widgets/song_overview_panel.dart';
import '../widgets/preview_panel.dart';
import '../widgets/service_plan_panel.dart';
import '../widgets/media_panel.dart';
import '../widgets/shared_widgets.dart';

// ── Layout constants ───────────────────────────────────────────────────────
const double kPanelWidth = 340.0;
const double kPlanWidth = 300.0;

// ─────────────────────────────────────────────────────────────────────────────
// DROPDOWN COORDINATOR
// ─────────────────────────────────────────────────────────────────────────────

class _DropdownCoordinator extends ChangeNotifier {
  String? _openId;
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
  final int bookNumber, chapter, verse;
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
  // ── Controllers ───────────────────────────────────────────────────────────
  late TextEditingController _searchController;
  late TextEditingController _songSearchController;
  final TextEditingController _quickAddCtrl = TextEditingController();
  final TextEditingController _mediaSearchCtrl = TextEditingController();

  // ── Search overlay ────────────────────────────────────────────────────────
  final FocusNode _searchFocus = FocusNode();
  final LayerLink _searchBarLink = LayerLink();
  OverlayEntry? _searchOverlay;
  List<_VerseSearchResult> _searchResults = [];

  // ── Dropdown coordinator ──────────────────────────────────────────────────
  final _DropdownCoordinator _dropdownCoord = _DropdownCoordinator();

  // ── Bible database ────────────────────────────────────────────────────────
  BibleVersion _activeVersion = kBibleVersions.first;
  bool _versionLoading = false;
  Database? _database;
  bool _initialLoadDone = false;

  List<String> _bibleBooks = [];
  final Map<String, int> _bookNumberMap = {};
  final Map<int, String> _bookByNumber = {};

  // ── Passage selection ─────────────────────────────────────────────────────
  String? _selectedBook;
  int? _selectedBookNumber;
  List<int> _chapters = [];
  int? _selectedChapter;
  List<Map<String, dynamic>> _verseList = [];

  // ── Range & preview highlight ──────────────────────────────────────────────
  int? _rangeFrom;
  int? _rangeTo;
  int? get _pickerFromVerse => _rangeFrom;
  int? get _pickerToVerse => _rangeTo;
  int? _previewVerseNum;

  final ScrollController _verseOverviewScroll = ScrollController();
  static const double _kVerseRowHeight = 64.0;

  // ── Songs ─────────────────────────────────────────────────────────────────
  Map<String, String>? _selectedSong;
  SongSection? _selectedSection;

  final List<Map<String, String>> _songs = [
    {
      'title': 'Amazing Grace',
      'artist': 'John Newton',
      'lyrics':
          '[Verse 1]\nAmazing grace, how sweet the sound\nThat saved a wretch like me\n'
          'I once was lost but now am found\nWas blind but now I see\n'
          '[Chorus]\nMy chains are gone, I\'ve been set free\nMy God, my Savior has ransomed me\n'
          'And like a flood His mercy rains\nUnending love, amazing grace',
    },
    {
      'title': 'How Great Thou Art',
      'artist': 'Carl Boberg',
      'lyrics':
          '[Verse 1]\nO Lord my God, when I in awesome wonder\nConsider all the worlds thy hands have made\n'
          '[Chorus]\nThen sings my soul, my Savior God, to thee\nHow great thou art, how great thou art',
    },
    {
      'title': 'Jesus Loves Me',
      'artist': 'Traditional',
      'lyrics':
          '[Verse 1]\nJesus loves me, this I know\nFor the Bible tells me so\n'
          '[Chorus]\nYes, Jesus loves me\nThe Bible tells me so',
    },
  ];
  late List<Map<String, String>> _filteredSongs;

  // ── Service plan ──────────────────────────────────────────────────────────
  ScriptureQueueItem? _previewVerse;

  final List<PlanSection> _sections = [
    PlanSection(title: 'Service', items: []),
  ];
  List<ServiceItem> get _plan => _sections.expand((s) => s.items).toList();
  int _activeIndex = -1;
  int _activeSectionIdx = 0;

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

  // ── History shelf ──────────────────────────────────────────────────────────
  final List<ServiceItem> _history = [];
  static const int _kMaxHistory = 20;
  bool _shelfExpanded = true;

  // ── Service meta ──────────────────────────────────────────────────────────
  String _serviceTitle = 'Morning Service';
  DateTime _serviceDate = DateTime.now();

  // ── Projector state ───────────────────────────────────────────────────────
  bool _projectorOpen = false;

  // ── Scroll controllers ────────────────────────────────────────────────────
  final ScrollController _planScroll = ScrollController();
  final FocusNode _keyboardFocus = FocusNode();

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

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
    _quickAddCtrl.dispose();
    _mediaSearchCtrl.dispose();
    _searchFocus.removeListener(_onSearchFocusChange);
    _searchFocus.dispose();
    _removeSearchOverlay();
    _dropdownCoord.dispose();
    _verseOverviewScroll.dispose();
    _planScroll.dispose();
    _keyboardFocus.dispose();
    _database?.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (!_initialLoadDone) {
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

    return Focus(
      focusNode: _keyboardFocus,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final primaryFocus = FocusManager.instance.primaryFocus;
        if (primaryFocus != null && primaryFocus != _keyboardFocus) {
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
          final previewWidth =
              constraints.maxWidth -
              kPanelWidth -
              1 // scripture panel + divider
              -
              300 -
              1 // verse overview + divider
              -
              300 -
              1 // song overview + divider
              -
              kPlanWidth -
              1; // plan panel + divider

          return Row(
            children: [
              // ── Col 1: Scripture + Songs ──────────────────────────────────
              SizedBox(
                width: kPanelWidth,
                child: Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: ScripturePanel(
                        books: _bibleBooks,
                        chapters: _chapters,
                        verseList: _verseList,
                        selectedBook: _selectedBook,
                        selectedChapter: _selectedChapter,
                        rangeFrom: _rangeFrom,
                        rangeTo: _rangeTo,
                        activeVersion: _activeVersion,
                        versionLoading: _versionLoading,
                        searchController: _searchController,
                        searchFocus: _searchFocus,
                        searchBarLink: _searchBarLink,
                        dropdownCoord: _dropdownCoord,
                        onBookSelected: _selectBook,
                        onChapterSelected: _selectChapter,
                        onRangeFromChanged: (v) => setState(() {
                          _rangeFrom = v;
                          if (_rangeTo != null && v != null && _rangeTo! < v) {
                            _rangeTo = null;
                          }
                        }),
                        onRangeToChanged: (v) => setState(() => _rangeTo = v),
                        onAddToQueue: _addPickerSelectionToQueue,
                        onVersionSwitch: _switchVersion,
                        onSearchChanged: _onSearchChanged,
                        onSearchSubmitted: _onSearchSubmitted,
                      ),
                    ),
                    VerticalDivider(width: 1, color: context.t.border),
                    Expanded(
                      flex: 1,
                      child: SongPanel(
                        songs: _filteredSongs,
                        selectedSong: _selectedSong,
                        searchController: _songSearchController,
                        onSearchChanged: _filterSongs,
                        onSongSelected: (song) => setState(() {
                          _selectedSong = song;
                          _selectedSection = null;
                        }),
                        onAddToQueue: () {
                          if (_selectedSong != null) {
                            setState(
                              () => _addItem(
                                ServiceItem(
                                  type: ServiceItemType.song,
                                  song: _selectedSong!,
                                ),
                              ),
                            );
                          }
                        },
                        onAddSong: () => _showSongEditorDialog(null),
                      ),
                    ),
                  ],
                ),
              ),

              VerticalDivider(width: 1, color: context.t.border),

              // ── Col 2: Verse overview ─────────────────────────────────────
              SizedBox(
                width: 300,
                child: VerseOverviewPanel(
                  selectedBook: _selectedBook,
                  selectedChapter: _selectedChapter,
                  verseList: _verseList,
                  rangeFrom: _rangeFrom,
                  rangeTo: _rangeTo,
                  previewVerseNum: _previewVerseNum,
                  activeQueueItem: _activeQueueItem,
                  versionLoading: _versionLoading,
                  scrollController: _verseOverviewScroll,
                  onVerseTap: _onVerseTap,
                  onVerseDoubleTap: _onVerseDoubleTap,
                  onVerseRightClick: _handleVerseRangeClick,
                  onPrev: _verseList.isEmpty ? null : _prevVerse,
                  onNext: _verseList.isEmpty ? null : _nextVerse,
                ),
              ),

              VerticalDivider(width: 1, color: context.t.border),

              // ── Col 3: Song overview ──────────────────────────────────────
              SizedBox(
                width: 300,
                child: SongOverviewPanel(
                  selectedSong: _selectedSong,
                  selectedSection: _selectedSection,
                  activeItem: _activeItem,
                  onSectionTap: (s) => setState(() => _selectedSection = s),
                  onSectionDoubleTap: (s) {
                    if (_selectedSong == null) return;
                    setState(() => _selectedSection = s);
                    _goLive();
                  },
                  onPrev: _selectedSong == null ? null : _prevSection,
                  onNext: _selectedSong == null ? null : _nextSection,
                  onEditSong: _showSongEditorDialog,
                ),
              ),

              VerticalDivider(width: 1, color: context.t.border),

              // ── Preview + Media ───────────────────────────────────────────
              SizedBox(
                width: previewWidth,
                child: Container(
                  color: context.t.appBg,
                  child: Column(
                    children: [
                      Expanded(
                        flex: 6,
                        child: PreviewPanel(
                          activeItem: _activeItem,
                          previewVerse: _previewVerse,
                          selectedSection: _selectedSection,
                          selectedSong: _selectedSong,
                          onGoLive: _goLive,
                          onClear: _clearProjector,
                          onAddBlack: _addBlackScreen,
                          onAddLogo: _addLogoSlide,
                          onAddAnnouncement: _showAnnouncementDialog,
                          onAddMessage: _showMessageDialog,
                        ),
                      ),
                      Flexible(flex: 4, child: const MediaPanel()),
                      _buildReferenceShelf(),
                    ],
                  ),
                ),
              ),

              VerticalDivider(width: 1, color: context.t.border),

              // ── Col 5: Service plan ───────────────────────────────────────
              SizedBox(
                width: kPlanWidth,
                child: ServicePlanPanel(
                  sections: _sections,
                  activeIndex: _activeIndex,
                  activeSectionIdx: _activeSectionIdx,
                  serviceTitle: _serviceTitle,
                  serviceDate: _serviceDate,
                  history: _history,
                  shelfExpanded: _shelfExpanded,
                  quickAddCtrl: _quickAddCtrl,
                  planScroll: _planScroll,
                  activeItem: _activeItem,
                  onSelectItem: _selectPlanItem,
                  onRemoveItem: _removePlanItem,
                  onSectionCollapse: (si) => setState(
                    () =>
                        _sections[si].isCollapsed = !_sections[si].isCollapsed,
                  ),
                  onSectionRename: _renameSection,
                  onSectionMergeUp: _mergeSectionUp,
                  onSectionDelete: _deleteSection,
                  onSectionAdd: _addSection,
                  onSetActiveSection: (si) =>
                      setState(() => _activeSectionIdx = si),
                  onQuickAdd: _quickAddItems,
                  onSave: _saveService,
                  onLoad: _showLoadServiceDialog,
                  onNew: _newService,
                  onEditTitle: _editServiceTitle,
                  onPickDate: _pickServiceDate,
                  onClearAll: _confirmClearPlan,
                  onShelfToggle: () =>
                      setState(() => _shelfExpanded = !_shelfExpanded),
                  onShelfClear: () => setState(() => _history.clear()),
                  onShelfItemTap: _activateHistoryItem,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REFERENCE SHELF (still rendered inline as it needs build context + state)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildReferenceShelf() =>
      const SizedBox.shrink(); // handled in ServicePlanPanel

  // ═══════════════════════════════════════════════════════════════════════════
  // PLAN MUTATION HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

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
    int rem = flatIdx;
    for (int s = 0; s < _sections.length; s++) {
      if (rem < _sections[s].items.length) {
        _sections[s].items.removeAt(rem);
        final len = _plan.length;
        if (len == 0) {
          _activeIndex = -1;
        } else if (_activeIndex >= len) {
          _activeIndex = len - 1;
        } else if (_activeIndex == flatIdx) {
          _activeIndex = _activeIndex.clamp(0, len - 1).toInt();
          return;
        }
      }
      rem -= _sections[s].items.length;
    }
  }

  void _replaceItemAt(int flatIdx, ServiceItem newItem) {
    int rem = flatIdx;
    for (int s = 0; s < _sections.length; s++) {
      if (rem < _sections[s].items.length) {
        _sections[s].items[rem] = newItem;
        return;
      }
      rem -= _sections[s].items.length;
    }
  }

  ServiceItem? _itemAt(int flatIdx) {
    int rem = flatIdx;
    for (int s = 0; s < _sections.length; s++) {
      if (rem < _sections[s].items.length) return _sections[s].items[rem];
      rem -= _sections[s].items.length;
    }
    return null;
  }

  void _clearAllItems() {
    for (final s in _sections) {
      s.items.clear();
    }
    _activeIndex = -1;
  }

  void _pushHistory(ServiceItem item) {
    _history.removeWhere((h) => h.id == item.id);
    _history.insert(0, item);
    if (_history.length > _kMaxHistory) _history.removeLast();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VERSE NAVIGATION (from overview panel)
  // ═══════════════════════════════════════════════════════════════════════════

  void _onVerseTap(int verseNum) {
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
      _activeIndex = -1;
    });
  }

  void _onVerseDoubleTap(int verseNum) {
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
        final vi = activeScripture.verses.indexWhere(
          (v) => (v['verse'] as int) == verseNum,
        );
        if (vi >= 0) {
          _replaceItemAt(
            _activeIndex,
            ServiceItem(
              id: _activeItem!.id,
              type: ServiceItemType.scripture,
              scriptureItem: activeScripture.withLiveIndex(vi),
            ),
          );
        } else {
          _activeIndex = -1;
        }
      } else {
        _activeIndex = -1;
      }
    });
    _goLive();
  }

  void _handleVerseRangeClick(int verseNum) {
    setState(() {
      if (_rangeFrom == null) {
        _rangeFrom = verseNum;
        _rangeTo = null;
      } else if (verseNum == _rangeFrom) {
        _rangeFrom = null;
        _rangeTo = null;
      } else if (_rangeTo == null) {
        if (verseNum < _rangeFrom!) {
          _rangeTo = _rangeFrom;
          _rangeFrom = verseNum;
        } else {
          _rangeTo = verseNum;
        }
      } else {
        _rangeFrom = verseNum;
        _rangeTo = null;
      }
    });
  }

  void _prevVerse() {
    final rows = _buildVerseRows();
    if (rows.isEmpty) return;
    final cur = rows.indexWhere((r) => r.startVerse == _previewVerseNum);
    final idx = cur <= 0 ? rows.length - 1 : cur - 1;
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
    _scrollVerseToIndex(idx);
  }

  void _nextVerse() {
    final rows = _buildVerseRows();
    if (rows.isEmpty) return;
    final cur = rows.indexWhere((r) => r.startVerse == _previewVerseNum);
    final idx = (cur < 0 || cur >= rows.length - 1) ? 0 : cur + 1;
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
    _scrollVerseToIndex(idx);
  }

  void _prevSection() {
    if (_selectedSong == null) return;
    final sections = parseSongSections(_selectedSong!['lyrics'] ?? '');
    final cur = sections.indexWhere(
      (s) =>
          s.label == _selectedSection?.label &&
          s.text == _selectedSection?.text,
    );
    final idx = cur <= 0 ? sections.length - 1 : cur - 1;
    setState(() => _selectedSection = sections[idx]);
  }

  void _nextSection() {
    if (_selectedSong == null) return;
    final sections = parseSongSections(_selectedSong!['lyrics'] ?? '');
    final cur = sections.indexWhere(
      (s) =>
          s.label == _selectedSection?.label &&
          s.text == _selectedSection?.text,
    );
    final idx = (cur < 0 || cur >= sections.length - 1) ? 0 : cur + 1;
    setState(() => _selectedSection = sections[idx]);
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

  void _scrollVerseToIndex(int idx) {
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

  // ═══════════════════════════════════════════════════════════════════════════
  // ADD TO QUEUE
  // ═══════════════════════════════════════════════════════════════════════════

  void _addPickerSelectionToQueue({int startAtVerse = 0}) {
    if (_selectedBook == null ||
        _selectedChapter == null ||
        _verseList.isEmpty) {
      return;
    }
    final allContent = _verseList
        .where(
          (v) =>
              ScriptureQueueItem.toPlain(v['text'] as String? ?? '').isNotEmpty,
        )
        .toList();
    if (allContent.isEmpty) return;
    final filtered = allContent.where((v) {
      final n = v['verse'] as int;
      if (_pickerFromVerse != null && n < _pickerFromVerse!) return false;
      if (_pickerToVerse != null && n > _pickerToVerse!) return false;
      return true;
    }).toList();
    final verses = filtered.isNotEmpty ? filtered : allContent;
    final item = ScriptureQueueItem(
      book: _selectedBook!,
      chapter: _selectedChapter!,
      startVerse: verses.first['verse'] as int,
      endVerse: verses.last['verse'] as int,
      verses: verses,
      version: _activeVersion,
      liveVerseIndex: 0,
    );
    setState(() {
      final existing = _plan.indexWhere(
        (si) =>
            si.type == ServiceItemType.scripture &&
            si.scriptureItem?.book == item.book &&
            si.scriptureItem?.chapter == item.chapter &&
            si.scriptureItem?.version.abbreviation == item.version.abbreviation,
      );
      if (existing >= 0) {
        _replaceItemAt(
          existing,
          ServiceItem(
            id: _itemAt(existing)?.id,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // PLAN ITEM SELECTION & NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════════

  void _selectPlanItem(int index) {
    final item = _itemAt(index);
    if (item?.type == ServiceItemType.scripture &&
        item?.scriptureItem != null) {
      setState(() => _activeIndex = index);
      _scrollPlanToIndex(index);
      _loadPickersFromScripture(item!.scriptureItem!);
      return;
    }
    setState(() {
      _activeIndex = index;
      _previewVerse = null;
    });
    _scrollPlanToIndex(index);
  }

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

  void _removePlanItem(int index) {
    setState(() {
      _removeItemAt(index);
    });
    _saveService(silent: true);
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

  void _activateHistoryItem(ServiceItem item) {
    final planIdx = _plan.indexWhere((p) => p.id == item.id);
    if (planIdx >= 0) setState(() => _activeIndex = planIdx);
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
        announcement: item.type == ServiceItemType.announcement ? item : null,
        showLogo: item.type == ServiceItemType.logo,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP FORWARD / BACK  (keyboard shortcuts)
  // ═══════════════════════════════════════════════════════════════════════════

  void _stepForward() {
    final item = _activeItem;
    if (item != null && item.type == ServiceItemType.scripture) {
      final si = item.scriptureItem!;
      if (si.liveVerseIndex < si.verses.length - 1) {
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
        _goLive();
        _saveService(silent: true);
        return;
      }
    }
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

  // ═══════════════════════════════════════════════════════════════════════════
  // PROJECTOR
  // ═══════════════════════════════════════════════════════════════════════════

  void _goLive() {
    if (_activeItem == null) return;
    final item = _activeItem!;
    _pushHistory(item);
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

  void _clearProjector() => ProjectorNotifier.instance.clear();

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

  // ═══════════════════════════════════════════════════════════════════════════
  // DATABASE & VERSION LOADING  (full logic preserved from original)
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

      String norm(String longName, String shortName) {
        final caps = RegExp(r'\b[A-Z]{2,}\b')
            .allMatches(longName)
            .map(
              (m) => m
                  .group(0)!
                  .split(' ')
                  .map(
                    (w) => w.isEmpty ? w : w[0] + w.substring(1).toLowerCase(),
                  )
                  .join(' '),
            )
            .toList();
        if (caps.isEmpty) return longName;
        String name = caps.join(' ');
        final prefix = RegExp(r'^(\d+)').firstMatch(shortName);
        if (prefix != null) {
          final d = prefix.group(1)!;
          if (!name.startsWith('$d ')) name = '$d $name';
        }
        return name;
      }

      final books = bookRows
          .map(
            (r) => norm(
              r['long_name'] as String,
              r['short_name'] as String? ?? '',
            ),
          )
          .toList();
      final bookMap = {
        for (int i = 0; i < bookRows.length; i++)
          books[i]: bookRows[i]['book_number'] as int,
      };
      final byNum = {
        for (int i = 0; i < bookRows.length; i++)
          bookRows[i]['book_number'] as int: books[i],
      };

      final curBookNum = _selectedBookNumber;
      final curChapter = _selectedChapter;
      List<Map<String, dynamic>> newVerseList = [];
      String? remappedBook = curBookNum != null ? byNum[curBookNum] : null;

      if (curBookNum != null && curChapter != null) {
        try {
          final rows = db.select(
            'SELECT verse, text FROM verses WHERE book_number = ? AND chapter = ? ORDER BY verse',
            [curBookNum, curChapter],
          );
          newVerseList = rows
              .map((r) => {'verse': r['verse'], 'text': r['text']})
              .toList();
        } catch (_) {}
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
          ..addAll(byNum);
        if (remappedBook != null) _selectedBook = remappedBook;
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
      debugPrint('❌ Chapters: $e');
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
      debugPrint('❌ Verses: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH (scripture)
  // ═══════════════════════════════════════════════════════════════════════════

  bool _looksLikeReference(String query) {
    final q = query.trim();
    if (q.isEmpty) return false;
    if (!RegExp(r'^[\d]?[a-zA-Z]').hasMatch(q)) return false;
    final tokens = q.split(RegExp(r'[\s:]+'));
    for (int len = tokens.length; len > 0; len--) {
      final candidate = tokens
          .sublist(0, len)
          .join(' ')
          .replaceAll(RegExp(r'\d+$'), '')
          .trim();
      if (candidate.length < 2) continue;
      if (BookAliasResolver.resolve(candidate, _bibleBooks).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  void _onSearchChanged(String value) {
    final q = value.trim();
    if (q.isEmpty) {
      _removeSearchOverlay();
      setState(() => _searchResults = []);
      return;
    }
    if (_looksLikeReference(q)) {
      _removeSearchOverlay();
      return;
    }
    if (q.length >= 3) {
      _runFullTextSearch(q);
    } else {
      _removeSearchOverlay();
    }
  }

  void _onSearchSubmitted(String value) {
    final q = value.trim();
    if (q.isEmpty) return;
    if (_looksLikeReference(q)) {
      _removeSearchOverlay();
      _parseAndJumpToReference(q);
      return;
    }
    if (_searchResults.isNotEmpty) {
      _navigateToSearchResult(_searchResults.first);
    }
  }

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
    if (matched == words.length) score += 2.0;
    if (plain.contains(fullQuery)) score += 4.0;
    if (matched == words.length) {
      int from = 0;
      bool inOrder = true;
      for (final w in words) {
        final idx = plain.indexOf(w, from);
        if (idx == -1) {
          inOrder = false;
          break;
        }
        from = idx + w.length;
      }
      if (inOrder) score += 3.0;
    }
    final wc = plain.split(RegExp(r'\s+')).length;
    if (wc > words.length) score -= (wc - words.length) * 0.05;
    return score;
  }

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
      final conditions = words.map((_) => 'LOWER(v.text) LIKE ?').join(' OR ');
      final params = words.map((w) => '%$w%').toList();
      final rows = _database!.select(
        'SELECT v.book_number, v.chapter, v.verse, v.text FROM verses v WHERE $conditions LIMIT 400',
        params,
      );
      final results = <_VerseSearchResult>[];
      for (final row in rows) {
        final raw = row['text'] as String? ?? '';
        final plain = raw
            .replaceAll(RegExp(r'<[^>]+>'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .toLowerCase()
            .trim();
        final score = _scoreVerse(plain, words, fullQuery);
        if (score <= 0) continue;
        results.add(
          _VerseSearchResult(
            book: _bookByNumber[row['book_number'] as int] ?? 'Unknown',
            bookNumber: row['book_number'] as int,
            chapter: row['chapter'] as int,
            verse: row['verse'] as int,
            text: raw,
            score: score,
          ),
        );
      }
      results.sort((a, b) {
        final cmp = b.score.compareTo(a.score);
        return cmp != 0 ? cmp : a.bookNumber.compareTo(b.bookNumber);
      });
      setState(() => _searchResults = results.take(12).toList());
      if (_searchResults.isNotEmpty) {
        _showSearchOverlay();
      } else {
        _removeSearchOverlay();
      }
    } catch (e) {
      debugPrint('Search error: $e');
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
    _searchOverlay = OverlayEntry(builder: (_) => _buildSearchOverlay());
    overlay.insert(_searchOverlay!);
  }

  void _removeSearchOverlay() {
    _searchOverlay?.remove();
    _searchOverlay = null;
  }

  Widget _buildSearchOverlay() {
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
                    separatorBuilder: (_, _) =>
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

  void _parseAndJumpToReference(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || _database == null) return;
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
    final full = BookAliasResolver.resolve(tokens.join(' '), _bibleBooks);
    if (full.isNotEmpty) {
      matchedBook = full;
      afterIdx = tokens.length;
    } else {
      for (int len = tokens.length - 1; len > 0; len--) {
        final resolved = BookAliasResolver.resolve(
          tokens.sublist(0, len).join(' '),
          _bibleBooks,
        );
        if (resolved.isNotEmpty) {
          matchedBook = resolved;
          afterIdx = len;
          break;
        }
      }
    }
    if (matchedBook.isEmpty) {
      _showRefError('Book not found: "${tokens.first}".');
      return;
    }
    final cvRaw = tokens.sublist(afterIdx).join('').replaceAll(' ', '');
    final colonIdx = cvRaw.indexOf(':');
    int? chapter, startVerse, endVerse;
    if (cvRaw.isNotEmpty) {
      if (colonIdx == -1) {
        chapter = int.tryParse(cvRaw);
      } else {
        chapter = int.tryParse(cvRaw.substring(0, colonIdx));
        final vp = cvRaw.substring(colonIdx + 1).split(RegExp(r'[\u2013\-]'));
        startVerse = int.tryParse(vp[0]);
        endVerse = vp.length > 1 ? int.tryParse(vp[1]) : startVerse;
      }
    }
    if (chapter != null) {
      final bn = _bookNumberMap[matchedBook];
      if (bn != null) {
        try {
          final chapRows = _database!.select(
            'SELECT DISTINCT chapter FROM verses WHERE book_number = ? ORDER BY chapter',
            [bn],
          );
          final valid = chapRows.map((r) => r['chapter'] as int).toList();
          if (valid.isNotEmpty && !valid.contains(chapter)) {
            _showRefError(
              '$matchedBook only has ${valid.last} chapter${valid.last == 1 ? "" : "s"}.',
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
        if (!mounted) return;
        final loaded = _verseList.map((v) => v['verse'] as int).toList();
        if (loaded.isEmpty) {
          _showRefError('No verses found for $matchedBook $chapter.');
          return;
        }
        final maxV = loaded.last;
        final minV = loaded.first;
        final clampedStart = startVerse!.clamp(minV, maxV);
        final clampedEnd = endVerse?.clamp(minV, maxV);
        if (!loaded.contains(clampedStart)) {
          _showRefError('$matchedBook $chapter only has verses $minV–$maxV.');
          return;
        }
        setState(() {
          _rangeFrom = clampedStart;
          _rangeTo = (clampedEnd != null && clampedEnd != clampedStart)
              ? clampedEnd
              : null;
        });
        Future.delayed(
          const Duration(milliseconds: 60),
          _scrollOverviewToSelection,
        );
      });
    });
  }

  void _showRefError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
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

  // ═══════════════════════════════════════════════════════════════════════════
  // SONGS
  // ═══════════════════════════════════════════════════════════════════════════

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

  void _showSongEditorDialog(Map<String, String>? existingSong) async {
    final result = await showSongEditorDialog(
      context,
      existingSong: existingSong,
    );
    if (result == null) return;
    setState(() {
      if (existingSong != null) {
        final idx = _songs.indexOf(existingSong);
        if (idx >= 0) _songs[idx] = result;
      } else {
        _songs.add(result);
      }
      _filteredSongs = _songs;
      _selectedSong = result;
      _selectedSection = null;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SERVICE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Directory> get _servicesDir async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/ChurchPresenter/services');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

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
      final plan = ServicePlan.fromJson(
        jsonDecode(await files.first.readAsString()) as Map<String, dynamic>,
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
      debugPrint('Load latest: $e');
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
                    final plan = ServicePlan.fromJson(
                      jsonDecode(await f.readAsString())
                          as Map<String, dynamic>,
                    );
                    if (plan == null || !mounted) return;
                    setState(() {
                      _serviceTitle = plan.title;
                      _serviceDate = plan.date;
                      _sections
                        ..clear()
                        ..addAll(plan.sections);
                      _activeIndex = -1;
                    });
                  } catch (e) {
                    debugPrint('Load: $e');
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
            setState(() {
              if (ctrl.text.trim().isNotEmpty) _serviceTitle = ctrl.text.trim();
            });
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
  // SECTION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

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
        content: DlgField(ctrl: ctrl, label: 'Section name', t: t),
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
        content: DlgField(ctrl: ctrl, label: 'Section name', t: t),
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
        _sections.removeAt(si);
      }
      
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
    ).then((ok) {
      if (ok == true) {
        setState(() {
          _clearAllItems();
          _activeIndex = -1;
        });
        _saveService(silent: true);
      }
    });
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
      final full = BookAliasResolver.resolve(tokens.join(' '), _bibleBooks);
      if (full.isNotEmpty) {
        matchedBook = full;
        afterIdx = tokens.length;
      } else {
        for (int len = tokens.length - 1; len >= 1; len--) {
          final cand = BookAliasResolver.resolve(
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
        final vr = cv[1].trim().split(RegExp(r'[-–—]'));
        startVerse = int.tryParse(vr[0].trim());
        endVerse = vr.length > 1 ? int.tryParse(vr[1].trim()) : startVerse;
      }
      if (chapter == null || startVerse == null) return null;
      endVerse ??= startVerse;
      final bookNum = _bookNumberMap[matchedBook];
      if (bookNum == null) return null;
      final allRows = _database!.select(
        'SELECT verse, text FROM verses WHERE book_number=? AND chapter=? ORDER BY verse',
        [bookNum, chapter],
      );
      if (allRows.isEmpty) return null;
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
      int liveIdx = 0;
      if (startVerse > 1) {
        final found = contentVerses.indexWhere(
          (v) => (v['verse'] as int) >= startVerse!,
        );
        if (found >= 0) liveIdx = found;
      }
      return ScriptureQueueItem(
        book: matchedBook,
        chapter: chapter,
        startVerse: contentVerses.first['verse'] as int,
        endVerse: contentVerses.last['verse'] as int,
        version: _activeVersion,
        liveVerseIndex: liveIdx,
        verses: contentVerses,
      );
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ANNOUNCEMENT & MESSAGE DIALOGS
  // (kept in home_screen since they call setState to add to plan)
  // ═══════════════════════════════════════════════════════════════════════════

  static const String _kDefaultAnnTitle = 'Weekly Announcements';
  static const String _kDefaultAnnBody =
      'Welcome to our service! We are glad you joined us today. '
      'Please silence your mobile phones and be respectful during worship.';
  static const List<String> _kDefaultBullets = [
    'Bible study holds every Wednesday at 6:00 PM',
    'Youth fellowship meets every Saturday at 4:00 PM',
    'Tithes and offerings will be received during worship',
    "First-timers are welcome to the visitors' lounge after service",
  ];

  void _showAnnouncementDialog() {
    final t = context.t;
    const amber = Color(0xFFE6A817);
    bool useDefault = true;
    final defTitleCtrl = TextEditingController(text: _kDefaultAnnTitle);
    final defBodyCtrl = TextEditingController(text: _kDefaultAnnBody);
    final defBullets = _kDefaultBullets
        .map((b) => TextEditingController(text: b))
        .toList();
    final newBulletCtrl = TextEditingController();
    final custTitleCtrl = TextEditingController();
    final custBodyCtrl = TextEditingController();
    final custBullets = <TextEditingController>[];
    final custNewCtrl = TextEditingController();

    String buildText({
      required TextEditingController body,
      required List<TextEditingController> bullets,
    }) {
      final buf = StringBuffer(body.text.trim());
      final valid = bullets
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
          final activeBullets = useDefault ? defBullets : custBullets;
          final activeNewCtrl = useDefault ? newBulletCtrl : custNewCtrl;

          void addBullet() {
            final txt = activeNewCtrl.text.trim();
            if (txt.isEmpty) return;
            setDlg(() {
              activeBullets.add(TextEditingController(text: txt));
              activeNewCtrl.clear();
            });
          }

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
                              AnnToggleChip(
                                label: 'Default',
                                selected: useDefault,
                                amber: amber,
                                t: t,
                                onTap: () => setDlg(() => useDefault = true),
                              ),
                              AnnToggleChip(
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
                          DlgField(ctrl: activeTitleCtrl, label: 'Title', t: t),
                          const SizedBox(height: 14),
                          DlgField(
                            ctrl: activeBodyCtrl,
                            label: 'Opening message',
                            t: t,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 18),
                          ...activeBullets.asMap().entries.map((e) {
                            final i = e.key;
                            final ctrl = e.value;
                            final canDelete =
                                !useDefault || i >= _kDefaultBullets.length;
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
                                  if (canDelete)
                                    InkWell(
                                      onTap: () => setDlg(
                                        () => activeBullets.removeAt(i),
                                      ),
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
                                      child: Icon(
                                        Icons.drag_handle_rounded,
                                        size: 14,
                                        color: t.textMuted.withValues(
                                          alpha: 0.35,
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
                                  onSubmitted: (_) => addBullet(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: t.textPrimary,
                                  ),
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
                                ),
                                child: const Text('Add'),
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
                            final fullText = buildText(
                              body: activeBodyCtrl,
                              bullets: activeBullets,
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
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DlgField(
                            ctrl: titleCtrl,
                            label: 'Heading (optional)',
                            t: t,
                          ),
                          const SizedBox(height: 14),
                          DlgField(
                            ctrl: bodyCtrl,
                            label: 'Message body',
                            t: t,
                            maxLines: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
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
}
