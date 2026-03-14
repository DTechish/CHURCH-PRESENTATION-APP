/// bible_text_validator_test.dart
///
/// Scans every verse in every Bible SQLite database and reports characters
/// that would look wrong on the projector screen.
///
/// HOW TO RUN (from your project root):
///   dart test test/bible_text_validator_test.dart --reporter=expanded
///
/// No Flutter plugins needed — opens the SQLite files directly from disk.
// ignore_for_file: avoid_print

import 'dart:io';
import 'package:test/test.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;

// ─────────────────────────────────────────────────────────────────────────────
// ADJUST THIS PATH if your assets folder is in a different location.
// This is relative to your project root (where pubspec.yaml lives).
// ─────────────────────────────────────────────────────────────────────────────
const String _assetBase = 'assets/database';

const Map<String, String> _versions = {
  'AMP':  '$_assetBase/AMP.SQLite3',
  'CSB':  '$_assetBase/CSB.SQLite3',
  'ESV':  '$_assetBase/ESV.SQLite3',
  'KJV':  '$_assetBase/KJV.SQLite3',
  'MSG':  '$_assetBase/MSG.SQLite3',
  'NASB': '$_assetBase/NASU.SQLite3',
  'NIV':  '$_assetBase/NIV.SQLite3',
  'NKJV': '$_assetBase/NKJV.SQLite3',
  'NLT':  '$_assetBase/NLT.SQLite3',
};

// ─────────────────────────────────────────────────────────────────────────────
// TEXT PROCESSING  (mirrors ScriptureQueueItem.toPlain from models.dart)
// ─────────────────────────────────────────────────────────────────────────────

String _toPlain(String raw) {
  String s = raw.replaceAll(RegExp(r'<f>.*?</f>', caseSensitive: false), '');

  s = s
      .replaceAll(RegExp(r'<pb/>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<br/>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'</?[a-zA-Z]{1,10}\s*/?>', caseSensitive: false), '')
      .replaceAll(RegExp(r'[\u24B6-\u24E9\u2460-\u2473]'), '') // circled letters/numbers
      .replaceAll('\u00B6', '')   // pilcrow ¶
      .replaceAll('\u2006', ' ')  // six-per-em space
      .replaceAll('\u2009', ' ')  // thin space
      .replaceAll(RegExp(r'\[[\d†#*§‡]+\]'), '') // footnote markers [1] [†]
      .replaceAll('&amp;',  '&')
      .replaceAll('&lt;',   '<')
      .replaceAll('&gt;',   '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;',  "'")
      .replaceAll('&nbsp;', ' ');

  // NASB: truncated tag at end of string e.g. "<p" with no closing >
  s = s.replaceAll(RegExp(r'<[a-zA-Z]+\s*$'), '');

  return s.replaceAll(RegExp(r'  +'), ' ').trim();
}

// ─────────────────────────────────────────────────────────────────────────────
// ALLOWED CHARACTER SET
// ─────────────────────────────────────────────────────────────────────────────

bool _isAllowed(String ch) {
  final cp = ch.codeUnitAt(0);

  if (cp >= 0x41 && cp <= 0x5A) return true; // A–Z
  if (cp >= 0x61 && cp <= 0x7A) return true; // a–z
  if (cp >= 0x30 && cp <= 0x39) return true; // 0–9

  if (ch == ' ' || ch == '\n' || ch == '\t') return true;

  const allowed = {
    // Punctuation
    ',', '.', ':', ';', '!', '?',
    // Dashes
    '-', '\u2013', '\u2014',         //  -  –  —
    // Brackets (AMP/NLT use both for clarification text)
    '(', ')', '[', ']',
    // Quotes & apostrophes
    "'", '\u2018', '\u2019',         //  '  '  '
    '"', '\u201C', '\u201D',         //  "  "  "
    // Misc
    '&', '%', r'$', '#', '/', '\\', '*',
  };

  return allowed.contains(ch);
}

// ─────────────────────────────────────────────────────────────────────────────
// SUSPECT CHARACTER FINDER
// ─────────────────────────────────────────────────────────────────────────────

class _Hit {
  const _Hit(this.char, this.codePoint, this.context);
  final String char;
  final int    codePoint;
  final String context;
}

List<_Hit> _findSuspects(String text) {
  final hits = <_Hit>[];
  for (int i = 0; i < text.length; i++) {
    final ch = text[i];
    if (!_isAllowed(ch)) {
      final start = (i - 20).clamp(0, text.length);
      final end   = (i + 20).clamp(0, text.length);
      final ctx   = text.substring(start, end).replaceAll('\n', '↵');
      hits.add(_Hit(ch, ch.codeUnitAt(0), '…$ctx…'));
    }
  }
  return hits;
}

// ─────────────────────────────────────────────────────────────────────────────
// SCHEMA DETECTION
// ─────────────────────────────────────────────────────────────────────────────

String? _pick(List<String> cols, List<String> candidates) {
  for (final c in candidates) {
    if (cols.contains(c.toLowerCase())) return c;
  }
  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
// THE TESTS
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('Bible text — projector character validation', () {
    for (final entry in _versions.entries) {
      final abbr = entry.key;
      final path = entry.value;

      test('$abbr — no unexpected characters survive toPlain()', () {
        // ── 1. Open database directly from disk ──────────────────────────────
        final file = File(path);
        if (!file.existsSync()) {
          fail('[$abbr] File not found at "$path". '
               'Check the _assetBase constant at the top of this test.');
        }

        final db = sqlite3.open(path, mode: OpenMode.readOnly);

        try {
          // ── 2. Find the verse table ────────────────────────────────────────
          final tables = db
              .select("SELECT name FROM sqlite_master WHERE type='table'")
              .map((r) => (r['name'] as String))
              .toList();

          String? verseTable = _pick(
            tables.map((t) => t.toLowerCase()).toList(),
            ['verses', 'verse', 'bible', 'kjv', 'book_verse'],
          );
          verseTable ??= tables.isNotEmpty ? tables.first : null;

          if (verseTable == null) {
            fail('[$abbr] Database has no tables. Found: $tables');
          }

          // ── 3. Find columns ────────────────────────────────────────────────
          final cols = db
              .select('PRAGMA table_info($verseTable)')
              .map((r) => (r['name'] as String).toLowerCase())
              .toList();

          final textCol    = _pick(cols, ['text', 't', 'scripture', 'verse_text', 'versetext', 'content']);
          final bookCol    = _pick(cols, ['book_name', 'book', 'b', 'bname', 'book_title']);
          final chapterCol = _pick(cols, ['chapter', 'c', 'chap']);
          final verseCol   = _pick(cols, ['verse', 'v', 'ver', 'verse_number', 'versenum']);

          if (textCol == null) {
            fail('[$abbr] Cannot find a text column in "$verseTable". '
                 'Columns present: $cols');
          }

          print('\n${'═' * 60}');
          print('[$abbr]  table: $verseTable');
          print('         text=$textCol  book=$bookCol  '
                'chapter=$chapterCol  verse=$verseCol');

          // ── 4. Query every verse ───────────────────────────────────────────
          final selectCols = [
            ?bookCol,
            ?chapterCol,
            ?verseCol,
            textCol,
          ].join(', ');

          final rows = db.select('SELECT $selectCols FROM $verseTable');

          // ── 5. Validate ────────────────────────────────────────────────────
          // Group by unique char to keep output readable.
          final findings = <String, List<String>>{};
          int totalVerses    = 0;
          int affectedVerses = 0;

          for (final row in rows) {
            totalVerses++;
            final raw = (row[textCol] as String?) ?? '';
            if (raw.trim().isEmpty) continue;

            final processed = _toPlain(raw);
            if (processed.isEmpty) continue;

            final hits = _findSuspects(processed);
            if (hits.isEmpty) continue;

            affectedVerses++;

            final book    = bookCol    != null ? '${row[bookCol]}'    : '?';
            final chapter = chapterCol != null ? '${row[chapterCol]}' : '?';
            final verse   = verseCol   != null ? '${row[verseCol]}'   : '?';
            final loc = '$book $chapter:$verse';

            for (final h in hits) {
              final key =
                  '"${h.char}"  '
                  'U+${h.codePoint.toRadixString(16).toUpperCase().padLeft(4, '0')}';
              findings.putIfAbsent(key, () => []).add('    $loc  →  ${h.context}');
            }
          }

          // ── 6. Print report ────────────────────────────────────────────────
          print('\n[$abbr]  Scanned $totalVerses verses  |  '
                '$affectedVerses affected  |  '
                '${findings.length} distinct suspect chars\n');

          if (findings.isEmpty) {
            print('[$abbr]  ✅  ALL CLEAR\n');
          } else {
            print('[$abbr]  ⚠️  SUSPECT CHARACTERS:\n');
            for (final e in findings.entries) {
              final locations = e.value;
              final shown     = locations.take(5);
              final extra     = locations.length - 5;

              print('  ${e.key}  (${locations.length} occurrence${locations.length == 1 ? '' : 's'})');
              for (final l in shown) {
                print(l);
              }
              if (extra > 0) print('    … and $extra more');
              print('');
            }
          }

          // ── 7. Assert ──────────────────────────────────────────────────────
          // Comment this expect() out if you just want the printed report
          // without failing CI — then re-enable once you've reviewed the output.
          expect(
            findings,
            isEmpty,
            reason: '[$abbr] ${findings.length} suspect character type(s) '
                    'found in $affectedVerses/$totalVerses verses. '
                    'See printed output above.',
          );
        } finally {
          db.dispose();
        }
      });
    }
  });
}