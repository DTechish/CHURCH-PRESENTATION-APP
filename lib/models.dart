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
    String s = raw
        .replaceAll('\u2006', ' ')
        .replaceAll('\u2009', ' ')
        .replaceAll('¶', '')
        .replaceAll(RegExp(r'[\u24D0-\u24E9]'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
    final tagRe = RegExp(r'<(/?)(\\w+)(/?)|<pb/>');
    int cursor = 0;
    final stack = <String>[];

    void flush(String text) {
      if (text.isEmpty) return;
      text = text.replaceAll(RegExp(r'\[[\d†#*§‡]+\]'), '');
      text = text.replaceAll(RegExp(r'  +'), ' ');
      if (text.isEmpty) return;
      final style = stack.contains('i')
          ? SpanStyle.italic
          : stack.contains('e')
              ? SpanStyle.bold
              : SpanStyle.normal;
      spans.add(SpanToken(text, style));
    }

    for (final m in tagRe.allMatches(s)) {
      if (m.start < cursor) continue;
      flush(s.substring(cursor, m.start));
      cursor = m.end;
      final full = m.group(0)!;
      if (full == '<pb/>') {
        spans.add(const SpanToken('\n\n', SpanStyle.normal));
        continue;
      }
      final isClose = m.group(1) == '/';
      final tag = m.group(2)!;
      if (tag == 'f') {
        if (!isClose) {
          final closeIdx = s.indexOf('</f>', cursor);
          if (closeIdx != -1) cursor = closeIdx + 4;
        }
      } else if (tag == 'n') {
        if (!isClose) {
          stack.add('n');
        } else {
          stack.remove('n');
        }
      } else if (tag == 't') {
        if (isClose) spans.add(const SpanToken(' ', SpanStyle.normal));
      } else if (tag == 'i') {
        if (!isClose) {
          stack.add('i');
        } else {
          stack.remove('i');
        }
      } else if (tag == 'e') {
        if (!isClose) {
          stack.add('e');
        } else {
          stack.remove('e');
        }
      }
    }
    flush(s.substring(cursor));
    return spans;
  }

  static String toPlain(String raw) {
    String s = raw
        .replaceAll(RegExp(r'<f>[^<]*</f>'), '')
        .replaceAll('<pb/>', ' ')
        .replaceAll(RegExp(r'<[^>]{0,40}>'), '')
        .replaceAll(RegExp(r'[\u24D0-\u24E9]'), '')
        .replaceAll('¶', '')
        .replaceAll('\u2006', ' ')
        .replaceAll('\u2009', ' ')
        .replaceAll(RegExp(r'\[[\d†#*§‡]+\]'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&nbsp;', ' ');
    return s.replaceAll(RegExp(r'  +'), ' ').trim();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPAN TOKEN  (public — used by projector_screen too)
// ─────────────────────────────────────────────────────────────────────────────

enum SpanStyle { normal, italic, bold }

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
      case SpanStyle.normal:
        return base;
    }
  }
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
      case ServiceItemType.song:         return song?['artist'] ?? '';
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