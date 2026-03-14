// ─────────────────────────────────────────────────────────────────────────────
// BIBLE SERVICE
// All SQLite database interaction lives here.
// HomeScreen owns a BibleService instance; panels never touch the DB directly.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;
import '../models.dart';
import '../utils/book_alias_resolver.dart';

class BibleService {
  Database? _db;
  bool get isReady => _db != null;

  // Book metadata — populated on first load
  List<String> books = [];
  final Map<String, int> bookNumberMap = {};
  final Map<int, String> bookByNumber = {};

  // ── Initialise ─────────────────────────────────────────────────────────────

  /// Load [version]'s SQLite asset into a temp file and open it.
  /// Calls [onDone] when ready (or on error — check [isReady]).
  Future<void> load(BibleVersion version, {required void Function() onDone}) async {
    try {
      // Close any previously open DB
      _db?.dispose();
      _db = null;
      books = [];
      bookNumberMap.clear();
      bookByNumber.clear();

      final data = await rootBundle.load('assets/database/${version.fileName}');
      final bytes = data.buffer.asUint8List();

      final tmp = File('${Directory.systemTemp.path}/${version.fileName}');
      await tmp.writeAsBytes(bytes, flush: true);

      _db = sqlite3.open(tmp.path);

      final rows = _db!.select(
        'SELECT book_number, long_name FROM books ORDER BY book_number',
      );
      for (final r in rows) {
        final num  = r['book_number'] as int;
        final name = r['long_name'] as String;
        books.add(name);
        bookNumberMap[name] = num;
        bookByNumber[num]   = name;
      }
    } catch (e) {
      debugLoadError = e.toString();
    }
    onDone();
  }

  String? debugLoadError;

  void dispose() {
    _db?.dispose();
    _db = null;
  }

  // ── Queries ────────────────────────────────────────────────────────────────

  /// Returns all chapter numbers for [book].
  List<int> chaptersForBook(String book) {
    final num = bookNumberMap[book];
    if (num == null || _db == null) return [];
    final rows = _db!.select(
      'SELECT DISTINCT chapter FROM verses WHERE book_number=? ORDER BY chapter',
      [num],
    );
    return rows.map((r) => r['chapter'] as int).toList();
  }

  /// Returns all verse rows {verse, text} for [book] [chapter].
  List<Map<String, dynamic>> versesForChapter(String book, int chapter) {
    final num = bookNumberMap[book];
    if (num == null || _db == null) return [];
    final rows = _db!.select(
      'SELECT verse, text FROM verses WHERE book_number=? AND chapter=? ORDER BY verse',
      [num, chapter],
    );
    return rows
        .map((r) => {'verse': r['verse'] as int, 'text': r['text'] as String? ?? ''})
        .toList();
  }

  /// Full-text search across all verses. Returns up to [limit] rows.
  List<Map<String, dynamic>> searchVerses(List<String> words, {int limit = 400}) {
    if (_db == null || words.isEmpty) return [];
    final conditions = words.map((_) => 'LOWER(v.text) LIKE ?').join(' OR ');
    final params = words.map((w) => '%$w%').toList();
    final rows = _db!.select(
      'SELECT v.book_number, v.chapter, v.verse, v.text '
      'FROM verses v WHERE $conditions LIMIT $limit',
      params,
    );
    return rows.map((r) => {
      'book_number': r['book_number'] as int,
      'chapter':     r['chapter'] as int,
      'verse':       r['verse'] as int,
      'text':        r['text'] as String? ?? '',
    }).toList();
  }

  /// Fetch all verses in a chapter and return a [ScriptureQueueItem]
  /// resolved from [ref] (e.g. "John 3:16", "Ps 23").
  /// Returns null if the reference cannot be resolved.
  ScriptureQueueItem? resolveReference(
    String ref,
    BibleVersion version,
  ) {
    if (_db == null) return null;
    try {
      String s = ref.trim();

      // Normalise "John 3 16" → "John 3:16"
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

      final full = BookAliasResolver.resolve(tokens.join(' '), books);
      if (full.isNotEmpty) {
        matchedBook = full;
        afterIdx = tokens.length;
      } else {
        for (int len = tokens.length - 1; len >= 1; len--) {
          final cand = BookAliasResolver.resolve(
              tokens.sublist(0, len).join(' '), books);
          if (cand.isNotEmpty) { matchedBook = cand; afterIdx = len; break; }
        }
      }
      if (matchedBook.isEmpty) return null;

      final rest = tokens.sublist(afterIdx).join(' ').trim();
      int? chapter, startVerse, endVerse;

      if (rest.isEmpty) {
        chapter = 1; startVerse = 1; endVerse = 1;
      } else if (!rest.contains(':')) {
        chapter = int.tryParse(rest); startVerse = 1; endVerse = 1;
      } else {
        final cv = rest.split(':');
        chapter = int.tryParse(cv[0].trim());
        final vr = cv[1].trim().split(RegExp(r'[-–—]'));
        startVerse = int.tryParse(vr[0].trim());
        endVerse = vr.length > 1 ? int.tryParse(vr[1].trim()) : startVerse;
      }
      if (chapter == null || startVerse == null) return null;
      endVerse ??= startVerse;

      final bookNum = bookNumberMap[matchedBook];
      if (bookNum == null) return null;

      final allRows = _db!.select(
        'SELECT verse, text FROM verses WHERE book_number=? AND chapter=? ORDER BY verse',
        [bookNum, chapter],
      );
      if (allRows.isEmpty) return null;

      final contentVerses = allRows
          .map((r) => {
                'verse': r['verse'] as int,
                'text': r['text'] as String? ?? '',
              })
          .where((r) =>
              ScriptureQueueItem.toPlain(r['text'] as String).isNotEmpty)
          .toList();
      if (contentVerses.isEmpty) return null;

      int liveIdx = 0;
      if (startVerse > 1) {
        final found = contentVerses
            .indexWhere((v) => (v['verse'] as int) >= startVerse!);
        if (found >= 0) liveIdx = found;
      }

      return ScriptureQueueItem(
        book: matchedBook,
        chapter: chapter,
        startVerse: contentVerses.first['verse'] as int,
        endVerse: contentVerses.last['verse'] as int,
        version: version,
        liveVerseIndex: liveIdx,
        verses: contentVerses,
      );
    } catch (e) {
      return null;
    }
  }
}

// ignore: non_constant_identifier_names
void debugPrint(String s) => print(s); // replace with proper logger if desired
