import 'package:flutter/material.dart';
import '../app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BIBLE VERSIONS
// ─────────────────────────────────────────────────────────────────────────────

class BibleVersion {
  const BibleVersion({
    required this.abbreviation,
    required this.fullName,
    required this.fileName,
  });

  final String abbreviation;
  final String fullName;
  final String fileName;

  String get assetPath => 'assets/database/$fileName';
}

const List<BibleVersion> kBibleVersions = [
  BibleVersion(abbreviation: 'AMP',  fullName: 'Amplified Bible',              fileName: 'AMP.SQLite3'),
  BibleVersion(abbreviation: 'CSB',  fullName: 'Christian Standard Bible',     fileName: 'CSB.SQLite3'),
  BibleVersion(abbreviation: 'ESV',  fullName: 'English Standard Version',     fileName: 'ESV.SQLite3'),
  BibleVersion(abbreviation: 'KJV',  fullName: 'King James Version',           fileName: 'KJV.SQLite3'),
  BibleVersion(abbreviation: 'MSG',  fullName: 'The Message',                  fileName: 'MSG.SQLite3'),
  BibleVersion(abbreviation: 'NASB', fullName: 'New American Standard Bible',  fileName: 'NASU.SQLite3'),
  BibleVersion(abbreviation: 'NIV',  fullName: 'New International Version',    fileName: 'NIV.SQLite3'),
  BibleVersion(abbreviation: 'NKJV', fullName: 'New King James Version',       fileName: 'NKJV.SQLite3'),
  BibleVersion(abbreviation: 'NLT',  fullName: 'New Living Translation',       fileName: 'NLT.SQLite3'),
];

// ─────────────────────────────────────────────────────────────────────────────
// SCRIPTURE QUEUE ITEM
// ─────────────────────────────────────────────────────────────────────────────

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
  final List<Map<String, dynamic>> verses;
  final BibleVersion version;

  String get reference => startVerse == endVerse
      ? '$book $chapter:$startVerse'
      : '$book $chapter:$startVerse–$endVerse';

  String get plainText {
    final buf = StringBuffer();
    bool first = true;
    for (int i = 0; i < verses.length; i++) {
      final raw = verses[i]['text'] as String? ?? '';
      final plain = toPlain(raw);
      if (plain.isEmpty) continue;
      final startNum = verses[i]['verse'] as int;
      int endNum = startNum;
      int j = i + 1;
      while (j < verses.length) {
        final nextRaw = toPlain(verses[j]['text'] as String? ?? '');
        if (nextRaw.isNotEmpty) break;
        endNum = verses[j]['verse'] as int;
        j++;
      }
      final label = endNum > startNum ? '$startNum–$endNum' : '$startNum';
      if (!first) buf.write('\n\n');
      buf.write('$label  $plain');
      first = false;
    }
    return buf.toString();
  }

  TextSpan buildRichText(TextStyle base) {
    final numStyle = base.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: (base.fontSize ?? 26) * 0.72,
      color: (base.color ?? Colors.white).withValues(alpha: 0.5),
    );
    final children = <InlineSpan>[];
    bool firstBlock = true;
    for (int i = 0; i < verses.length; i++) {
      final raw = verses[i]['text'] as String? ?? '';
      final spans = parseSpans(raw);
      final hasContent = spans.any((s) => s.text.trim().isNotEmpty);
      if (!hasContent) continue;
      final startNum = verses[i]['verse'] as int;
      int endNum = startNum;
      int j = i + 1;
      while (j < verses.length) {
        final nextRaw = verses[j]['text'] as String? ?? '';
        final nextSpans = parseSpans(nextRaw);
        if (nextSpans.any((s) => s.text.trim().isNotEmpty)) break;
        endNum = verses[j]['verse'] as int;
        j++;
      }
      final label = endNum > startNum ? '$startNum–$endNum  ' : '$startNum  ';
      if (!firstBlock) children.add(TextSpan(text: '\n\n', style: base));
      firstBlock = false;
      children.add(TextSpan(text: label, style: numStyle));
      for (final span in spans) {
        children.add(TextSpan(text: span.text, style: span.toTextStyle(base)));
      }
    }
    return TextSpan(children: children);
  }

  static List<SpanToken> parseSpans(String raw) {
    final spans = <SpanToken>[];

    // ── Step 1: normalise encoding ──────────────────────────────────────────
    String s = raw
        .replaceAll('\u2006', ' ')   // thin space
        .replaceAll('\u2009', ' ')   // thin space
        .replaceAll('\u00B6', '')    // pilcrow ¶
        .replaceAll('&amp;',  '&')
        .replaceAll('&lt;',   '<')
        .replaceAll('&gt;',   '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;',  "'")
        .replaceAll('&nbsp;', ' ');

    // Strip truncated tags at end of string (NASB: verses ending with '<p')
    s = s.replaceAll(RegExp(r'<[a-zA-Z]+$', multiLine: false), '');

    // ── Ensure spaces around <i>…</i> boundaries ────────────────────────────
    // Many versions store e.g. "word<i>it</i>was" or "</i>word" with no space.
    // Fix: if the char immediately before <i> or after </i> is alphanumeric,
    // inject a space so the italic word doesn't collide with surrounding text.
    s = s
        .replaceAllMapped(
          RegExp(r'(\w)(<i>)', caseSensitive: false),
          (m) => '${m[1]} ${m[2]}',
        )
        .replaceAllMapped(
          RegExp(r'(</i>)(\w)', caseSensitive: false),
          (m) => '${m[1]} ${m[2]}',
        );

    // ── Step 2: tokenise with a case-insensitive tag regex ──────────────────
    // Handles: <pb/> <br/> <f> </f> <i> </i> <e> </e> <n> </n>
    //          <t> </t> <J> </J>  (and any other unknown tags)
    final tagRe = RegExp(r'<(/?)\s*(\w+)\s*(/?)>|<(pb|br)/>', caseSensitive: false);
    int cursor = 0;
    // style stack — multiple flags can be open at once (e.g. italic inside J)
    final stack = <String>[];

    void flush(String text) {
      if (text.isEmpty) return;
      // Drop bare footnote-number fragments that leaked outside <f> tags:
      //   [1]  [†3]  [#§]  [52†]  ⓐ–ⓩ  Ⓐ–Ⓩ  ①–⑳
      text = text
          .replaceAll(RegExp(r'\[[\d†#*§‡ⓐ-ⓩ]+\]'), '')
          .replaceAll(RegExp(r'[\u24B6-\u24E9\u2460-\u2473]'), '') // circled letters/numbers
          .replaceAll(RegExp(r'  +'), ' ');
      if (text.trim().isEmpty) return;

      SpanStyle style;
      if (stack.contains('i')) {
        style = SpanStyle.italic;
      } else if (stack.contains('e')) {
        style = SpanStyle.bold;
      } else if (stack.contains('j')) {
        style = SpanStyle.jesus; // words of Jesus
      } else {
        style = SpanStyle.normal;
      }
      spans.add(SpanToken(text, style));
    }

    for (final m in tagRe.allMatches(s)) {
      if (m.start < cursor) continue;       // already consumed inside <f>
      flush(s.substring(cursor, m.start));
      cursor = m.end;

      // Self-closing tags: <pb/> <br/>
      final selfClose = m.group(4)?.toLowerCase();
      if (selfClose == 'pb') {
        spans.add(const SpanToken('\n\n', SpanStyle.normal));
        continue;
      }
      if (selfClose == 'br') {
        spans.add(const SpanToken('\n', SpanStyle.normal));
        continue;
      }

      final isClose = m.group(1) == '/';
      final tag = m.group(2)!.toLowerCase();

      switch (tag) {
        case 'f':
          // Footnote — drop everything until </f>
          if (!isClose) {
            final closeIdx = s.toLowerCase().indexOf('</f>', cursor);
            if (closeIdx != -1) cursor = closeIdx + 4;
          }
          break;
        case 'i':
          if (!isClose) {
            stack.add('i');
          } else {
            stack.remove('i');
          }
          break;
        case 'e':
          // Divine name (LORD) — bold small-caps style
          if (!isClose) {
            stack.add('e');
          } else {
            stack.remove('e');
          }
          break;
        case 'j':
          // Words of Jesus (KJV red-letter)
          if (!isClose) {
            stack.add('j');
          } else {
            stack.remove('j');
          }
          break;
        case 'n':
          // AMP / NLT clarification brackets — keep text, normal style
          if (!isClose) {
            stack.add('n');
          } else {
            stack.remove('n');
          }
          break;
        case 't':
          // Line wrapper — emit a space when closing so words don't run together
          if (isClose) spans.add(const SpanToken(' ', SpanStyle.normal));
          break;
        // Everything else: silently ignore the tag, keep inner text
      }
    }

    flush(s.substring(cursor));
    return spans;
  }

  static String toPlain(String raw) {
    // Strip <f>…</f> blocks first (greedy content inside)
    String s = raw.replaceAll(RegExp(r'<f>.*?</f>', caseSensitive: false), '');
    // Convert structural tags to whitespace
    s = s
        .replaceAll(RegExp(r'<pb/>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<br/>', caseSensitive: false), ' ')
        // Strip all remaining tags (case-insensitive, up to 40 chars)
        .replaceAll(RegExp(r'</?[a-zA-Z]{1,10}\s*/?>', caseSensitive: false), '')
        // Drop circled letters / footnote symbols
        .replaceAll(RegExp(r'[\u24B6-\u24E9\u2460-\u2473]'), '')
        .replaceAll('\u00B6', '')    // pilcrow
        .replaceAll('\u2006', ' ')   // thin space
        .replaceAll('\u2009', ' ')
        .replaceAll(RegExp(r'\[[\d†#*§‡]+\]'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&nbsp;', ' ');
    // NASB has verses that end with a truncated '<p' (no closing >) — strip it
    s = s.replaceAll(RegExp(r'<[a-zA-Z]+\s*\$'), '');
    return s.replaceAll(RegExp(r'  +'), ' ').trim();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPAN TOKEN  (public — used by projector_screen too)
// ─────────────────────────────────────────────────────────────────────────────

enum SpanStyle { normal, italic, bold, jesus }

class SpanToken {
  const SpanToken(this.text, this.style);
  final String text;
  final SpanStyle style;

  TextStyle toTextStyle(TextStyle base) {
    switch (style) {
      case SpanStyle.italic:
        return base.copyWith(fontStyle: FontStyle.italic);
      case SpanStyle.bold:
        return base.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8);
      case SpanStyle.jesus:
        return base.copyWith(color: const Color(0xFFE05252));
      case SpanStyle.normal:
        return base;
    }
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// SONG SECTIONS
// ─────────────────────────────────────────────────────────────────────────────

/// One displayable block of a song (Verse 1, Chorus, Bridge, etc.).
class SongSection {
  const SongSection({required this.label, required this.text});

  /// e.g. "Verse 1", "Chorus", "Bridge". Empty string for unlabelled songs.
  final String label;

  /// The lyric lines for this section only (header line excluded).
  final String text;

  bool get hasLabel => label.isNotEmpty;
}

/// Parse a lyrics string into [SongSection]s.
///
/// Sections are delimited by lines like [Verse 1] or [Chorus] (square brackets).
/// If no markers are present the whole text becomes one unlabelled section.
List<SongSection> parseSongSections(String lyrics) {
  if (lyrics.trim().isEmpty) return [];

  final lines = lyrics.split('\n');
  final headerRe = RegExp(r'^\[(.+)\]\s*$');

  final sections = <SongSection>[];
  String? currentLabel;
  final buffer = <String>[];

  void flush() {
    final text = buffer.join('\n').trim();
    if (text.isNotEmpty || currentLabel != null) {
      sections.add(SongSection(label: currentLabel ?? '', text: text));
    }
    buffer.clear();
  }

  for (final line in lines) {
    final m = headerRe.firstMatch(line.trim());
    if (m != null) {
      flush();
      currentLabel = m.group(1)!.trim();
    } else {
      buffer.add(line);
    }
  }
  flush();

  return sections.isEmpty
      ? [SongSection(label: '', text: lyrics.trim())]
      : sections;
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE PLAN — data model
// ─────────────────────────────────────────────────────────────────────────────

enum ServiceItemType { scripture, song, logo, announcement, black }

class ServiceItem {
  ServiceItem({
    required this.type,
    this.scriptureItem,
    this.song,
    this.announcementText,
    this.announcementTitle,
    String? id,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
  final ServiceItemType type;
  final ScriptureQueueItem? scriptureItem;
  final Map<String, String>? song;
  final String? announcementTitle;
  final String? announcementText;

  String get title {
    switch (type) {
      case ServiceItemType.scripture:    return scriptureItem?.reference ?? '—';
      case ServiceItemType.song:         return song?['title'] ?? '—';
      case ServiceItemType.announcement:
        return announcementTitle?.isNotEmpty == true
            ? announcementTitle!
            : (announcementText ?? 'Announcement');
      case ServiceItemType.logo:         return 'Church Logo';
      case ServiceItemType.black:        return 'Black Screen';
    }
  }

  String get subtitle {
    switch (type) {
      case ServiceItemType.scripture:    return scriptureItem?.version.abbreviation ?? '';
      case ServiceItemType.song:
        final label = song?['_sectionLabel'];
        return (label != null && label.isNotEmpty)
            ? '$label  ·  ${song?["artist"] ?? ""}'
            : song?['artist'] ?? '';
      case ServiceItemType.announcement:
        return announcementText != null
            ? announcementText!.length > 40
                ? '${announcementText!.substring(0, 40)}…'
                : announcementText!
            : '';
      case ServiceItemType.logo:         return 'Branded slide';
      case ServiceItemType.black:        return 'Clear screen';
    }
  }

  IconData get icon {
    switch (type) {
      case ServiceItemType.scripture:    return Icons.menu_book_rounded;
      case ServiceItemType.song:         return Icons.music_note_rounded;
      case ServiceItemType.announcement: return Icons.campaign_rounded;
      case ServiceItemType.logo:         return Icons.church_rounded;
      case ServiceItemType.black:        return Icons.circle_rounded;
    }
  }

  Color accentColor(AppTheme t) {
    switch (type) {
      case ServiceItemType.scripture:    return t.accentBlue;
      case ServiceItemType.song:         return t.accentPurple;
      case ServiceItemType.announcement: return const Color(0xFFE6A817);
      case ServiceItemType.logo:         return const Color(0xFF4CAF50);
      case ServiceItemType.black:        return const Color(0xFF777777);
    }
  }

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{'id': id, 'type': type.name};
    if (type == ServiceItemType.scripture && scriptureItem != null) {
      final si = scriptureItem!;
      m['book']        = si.book;
      m['chapter']     = si.chapter;
      m['startVerse']  = si.startVerse;
      m['endVerse']    = si.endVerse;
      m['versionAbbr'] = si.version.abbreviation;
      m['verses']      = si.verses;
    } else if (type == ServiceItemType.song) {
      m['song'] = song;
    } else if (type == ServiceItemType.announcement) {
      m['announcementTitle'] = announcementTitle;
      m['announcementText']  = announcementText;
    }
    return m;
  }

  static ServiceItem? fromJson(Map<String, dynamic> m) {
    try {
      final type = ServiceItemType.values.firstWhere((e) => e.name == m['type']);
      switch (type) {
        case ServiceItemType.scripture:
          final version = kBibleVersions.firstWhere(
            (v) => v.abbreviation == m['versionAbbr'],
            orElse: () => kBibleVersions.first,
          );
          return ServiceItem(
            id: m['id'] as String?,
            type: type,
            scriptureItem: ScriptureQueueItem(
              book:       m['book'] as String,
              chapter:    m['chapter'] as int,
              startVerse: m['startVerse'] as int,
              endVerse:   m['endVerse'] as int,
              version:    version,
              verses: (m['verses'] as List)
                  .map((v) => Map<String, dynamic>.from(v as Map))
                  .toList(),
            ),
          );
        case ServiceItemType.song:
          return ServiceItem(
            id: m['id'] as String?,
            type: type,
            song: Map<String, String>.from(m['song'] as Map),
          );
        case ServiceItemType.announcement:
          return ServiceItem(
            id: m['id'] as String?,
            type: type,
            announcementTitle: m['announcementTitle'] as String?,
            announcementText:  m['announcementText']  as String?,
          );
        case ServiceItemType.logo:
        case ServiceItemType.black:
          return ServiceItem(id: m['id'] as String?, type: type);
      }
    } catch (e) {
      debugPrint('ServiceItem.fromJson error: $e');
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE PLAN DOCUMENT — named, dated, saveable
// ─────────────────────────────────────────────────────────────────────────────

class ServicePlan {
  ServicePlan({
    required this.title,
    required this.date,
    required this.items,
    String? id,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
  String title;
  DateTime date;
  List<ServiceItem> items;

  /// File-safe name for saving, e.g. "2026-03-15_Morning-Service.json"
  String get fileName {
    final d = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final t = title.trim().replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(RegExp(r'\s+'), '-');
    return '${d}_$t.json';
  }

  Map<String, dynamic> toJson() => {
    'id':    id,
    'title': title,
    'date':  date.toIso8601String(),
    'items': items.map((e) => e.toJson()).toList(),
  };

  static ServicePlan? fromJson(Map<String, dynamic> m) {
    try {
      final items = (m['items'] as List)
          .map((e) => ServiceItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .whereType<ServiceItem>()
          .toList();
      return ServicePlan(
        id:    m['id'] as String? ?? '',
        title: m['title'] as String? ?? 'Untitled Service',
        date:  DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
        items: items,
      );
    } catch (_) {
      return null;
    }
  }
}