// ─────────────────────────────────────────────────────────────────────────────
// VERSE OVERVIEW PANEL  (column 2)
// Displays all verses for the selected chapter.
// Handles single-tap preview, double-tap go-live, right-click range selection.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models.dart';
import 'shared_widgets.dart';

class VerseOverviewPanel extends StatelessWidget {
  const VerseOverviewPanel({
    super.key,
    required this.selectedBook,
    required this.selectedChapter,
    required this.verseList,
    required this.rangeFrom,
    required this.rangeTo,
    required this.previewVerseNum,
    required this.activeQueueItem,
    required this.versionLoading,
    required this.scrollController,
    required this.onVerseTap,
    required this.onVerseDoubleTap,
    required this.onVerseRightClick,
    required this.onPrev,
    required this.onNext,
  });

  final String? selectedBook;
  final int? selectedChapter;
  final List<Map<String, dynamic>> verseList;
  final int? rangeFrom;
  final int? rangeTo;
  final int? previewVerseNum;
  final ScriptureQueueItem? activeQueueItem;
  final bool versionLoading;
  final ScrollController scrollController;

  final void Function(int verseNum) onVerseTap;
  final void Function(int verseNum) onVerseDoubleTap;
  final void Function(int verseNum) onVerseRightClick;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  static const double kRowHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      color: t.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────────────────
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
                    selectedBook != null && selectedChapter != null
                        ? '$selectedBook  ·  Ch. $selectedChapter'
                        : 'Verse Overview',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: t.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (verseList.isNotEmpty)
                  Text('${verseList.length}v',
                      style: TextStyle(fontSize: 10, color: t.textMuted)),
              ],
            ),
          ),

          // ── Verse list ────────────────────────────────────────────────────
          Expanded(
            child: versionLoading
                ? Center(child: CircularProgressIndicator(
                    color: t.accentBlue, strokeWidth: 2))
                : verseList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.menu_book_outlined, size: 36, color: t.textMuted),
                        const SizedBox(height: 10),
                        Text(
                          selectedBook == null
                              ? 'Select a book\n& chapter'
                              : 'Select a chapter',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: t.textMuted, height: 1.5),
                        ),
                      ],
                    ),
                  )
                : Material(
                    color: Colors.transparent,
                    child: ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.zero,
                      itemCount: _buildVerseRows().length,
                      itemBuilder: (context, index) {
                        final rows = _buildVerseRows();
                        final row = rows[index];
                        return SizedBox(
                          height: kRowHeight,
                          child: _VerseRow(
                            verseNum: row.startVerse,
                            endVerseNum: row.endVerse,
                            verseText: row.text,
                            rangeFrom: rangeFrom,
                            rangeTo: rangeTo,
                            previewVerseNum: previewVerseNum,
                            activeQueueItem: activeQueueItem,
                            selectedBook: selectedBook,
                            selectedChapter: selectedChapter,
                            onTap: () => onVerseTap(row.startVerse),
                            onDoubleTap: () => onVerseDoubleTap(row.startVerse),
                            onRightClick: () => onVerseRightClick(row.startVerse),
                          ),
                        );
                      },
                    ),
                  ),
          ),

          // ── Nav bar ────────────────────────────────────────────────────────
          OverviewNavBar(
            accent: t.accentBlue,
            onPrev: onPrev,
            onNext: onNext,
          ),
        ],
      ),
    );
  }

  List<({int startVerse, int endVerse, String text})> _buildVerseRows() {
    final rows = <({int startVerse, int endVerse, String text})>[];
    int i = 0;
    while (i < verseList.length) {
      final raw = (verseList[i]['text'] as String?) ?? '';
      final plain = ScriptureQueueItem.toPlain(raw);
      final startNum = verseList[i]['verse'] as int;
      if (plain.isEmpty) { i++; continue; }
      int endNum = startNum;
      int j = i + 1;
      while (j < verseList.length) {
        final nxt = ScriptureQueueItem.toPlain((verseList[j]['text'] as String?) ?? '');
        if (nxt.isNotEmpty) break;
        endNum = verseList[j]['verse'] as int;
        j++;
      }
      rows.add((startVerse: startNum, endVerse: endNum, text: plain));
      i = j;
    }
    return rows;
  }
}

// ── Individual verse row ───────────────────────────────────────────────────

class _VerseRow extends StatelessWidget {
  const _VerseRow({
    required this.verseNum,
    required this.endVerseNum,
    required this.verseText,
    required this.rangeFrom,
    required this.rangeTo,
    required this.previewVerseNum,
    required this.activeQueueItem,
    required this.selectedBook,
    required this.selectedChapter,
    required this.onTap,
    required this.onDoubleTap,
    required this.onRightClick,
  });

  final int verseNum;
  final int endVerseNum;
  final String verseText;
  final int? rangeFrom;
  final int? rangeTo;
  final int? previewVerseNum;
  final ScriptureQueueItem? activeQueueItem;
  final String? selectedBook;
  final int? selectedChapter;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onRightClick;

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    final bool isRangeAnchor = rangeFrom != null && verseNum == rangeFrom;
    final bool isRangeEnd    = rangeTo   != null && verseNum == rangeTo;
    final bool inRange       = rangeFrom != null && rangeTo != null &&
        verseNum >= rangeFrom! && verseNum <= rangeTo!;
    final bool isSelected    = verseNum == previewVerseNum;

    final liveVerseNum = activeQueueItem?.liveVerseNum;
    final bool isLive  = liveVerseNum != null &&
        verseNum == liveVerseNum &&
        activeQueueItem?.book == selectedBook &&
        activeQueueItem?.chapter == selectedChapter;

    final displayLabel = endVerseNum > verseNum
        ? '$verseNum–$endVerseNum' : '$verseNum';

    // Colour resolution (priority: LIVE > selected > range > plain)
    final Color deepBlueBg  = t.accentBlue.withValues(alpha: t.isDark ? 0.35 : 0.22);
    final Color lightBlueBg = t.rangeHighlight;
    final Color lightBlueDim= t.rangeHighlight.withValues(alpha: t.isDark ? 0.55 : 0.45);

    final Color bg;
    final Color leftBarColor;
    final double leftBarWidth;
    final Color textColor;
    final Color numColor;

    if (isLive) {
      bg = t.anchorHighlight; leftBarColor = t.accentBlue; leftBarWidth = 4;
      textColor = t.textPrimary; numColor = t.accentBlue;
    } else if (inRange && isSelected) {
      bg = deepBlueBg; leftBarColor = t.accentBlue; leftBarWidth = 3.5;
      textColor = t.textPrimary; numColor = t.accentBlue;
    } else if (isSelected) {
      bg = deepBlueBg; leftBarColor = t.accentBlue; leftBarWidth = 3.5;
      textColor = t.textPrimary; numColor = t.accentBlue;
    } else if (inRange) {
      bg = isRangeAnchor || isRangeEnd ? lightBlueBg : lightBlueDim;
      leftBarColor = isRangeAnchor || isRangeEnd
          ? t.accentBlue : t.accentBlue.withValues(alpha: 0.45);
      leftBarWidth = isRangeAnchor || isRangeEnd ? 2.5 : 1.5;
      textColor = t.textPrimary.withValues(alpha: 0.9);
      numColor  = t.accentBlue.withValues(alpha: 0.75);
    } else {
      bg = Colors.transparent; leftBarColor = Colors.transparent; leftBarWidth = 0;
      textColor = t.textSecondary; numColor = t.textMuted;
    }

    return InkWell(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onSecondaryTap: onRightClick,
      onLongPress: onRightClick,
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
              child: Text(displayLabel,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: numColor)),
            ),
            Expanded(
              child: Text(verseText,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, height: 1.35, color: textColor)),
            ),
            if (isRangeAnchor && !isLive) _Badge(label: 'FROM', color: t.accentBlue),
            if (isRangeEnd && !isRangeAnchor && !isLive) _Badge(label: 'TO', color: t.accentBlue),
            if (isLive) _Badge(label: 'LIVE', color: t.accentBlue, filled: true),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.filled = false});
  final String label;
  final Color color;
  final bool filled;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(3),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800,
              color: filled ? Colors.white : color, letterSpacing: 0.5)),
    );
  }
}
