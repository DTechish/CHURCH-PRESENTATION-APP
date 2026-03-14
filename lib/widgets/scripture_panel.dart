// ─────────────────────────────────────────────────────────────────────────────
// SCRIPTURE PANEL  (left column, top half)
// Search bar + Book/Chapter/From/To passage picker + Bible version list.
// Pure display widget — all state lives in HomeScreen.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models.dart';
import 'shared_widgets.dart';

class ScripturePanel extends StatelessWidget {
  const ScripturePanel({
    super.key,
    required this.books,
    required this.chapters,
    required this.verseList,
    required this.selectedBook,
    required this.selectedChapter,
    required this.rangeFrom,
    required this.rangeTo,
    required this.activeVersion,
    required this.versionLoading,
    required this.searchController,
    required this.searchFocus,
    required this.searchBarLink,
    required this.dropdownCoord,
    required this.onBookSelected,
    required this.onChapterSelected,
    required this.onRangeFromChanged,
    required this.onRangeToChanged,
    required this.onAddToQueue,
    required this.onVersionSwitch,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
  });

  final List<String> books;
  final List<int> chapters;
  final List<Map<String, dynamic>> verseList;
  final String? selectedBook;
  final int? selectedChapter;
  final int? rangeFrom;
  final int? rangeTo;
  final BibleVersion activeVersion;
  final bool versionLoading;

  final TextEditingController searchController;
  final FocusNode searchFocus;
  final LayerLink searchBarLink;
  final dynamic dropdownCoord; // _DropdownCoordinator

  final void Function(String) onBookSelected;
  final void Function(int) onChapterSelected;
  final void Function(int?) onRangeFromChanged;
  final void Function(int?) onRangeToChanged;
  final VoidCallback onAddToQueue;
  final void Function(BibleVersion) onVersionSwitch;
  final void Function(String) onSearchChanged;
  final void Function(String) onSearchSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel(label: 'SCRIPTURE', accent: context.t.accentBlue),
        _buildSearchBar(context),
        _buildPassagePicker(context),
        Expanded(child: _buildVersionLibrary(context)),
      ],
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar(BuildContext context) {
    final t = context.t;
    return CompositedTransformTarget(
      link: searchBarLink,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.border)),
        ),
        child: TextField(
          controller: searchController,
          focusNode: searchFocus,
          onChanged: onSearchChanged,
          onSubmitted: onSearchSubmitted,
          style: TextStyle(fontSize: 13, color: t.textPrimary),
          decoration: InputDecoration(
            hintText: 'Jn 3:16  ·  john3  ·  god so loved the world',
            hintStyle: TextStyle(fontSize: 12, color: t.textMuted),
            prefixIcon: Icon(Icons.search_rounded, size: 17, color: t.textMuted),
            suffixIcon: IconButton(
              icon: Icon(Icons.arrow_forward_rounded, size: 16, color: t.accentBlue),
              tooltip: 'Go',
              splashRadius: 16,
              onPressed: () => onSearchSubmitted(searchController.text),
            ),
            filled: true,
            fillColor: t.appBg,
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
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
          ),
        ),
      ),
    );
  }

  // ── Passage picker ─────────────────────────────────────────────────────────

  Widget _buildPassagePicker(BuildContext context) {
    final t = context.t;
    final bool chapterReady = selectedBook != null && !versionLoading;
    final bool versesReady = chapterReady && selectedChapter != null && verseList.isNotEmpty;

    String rangeSummary = '';
    if (rangeFrom != null && rangeTo != null) {
      rangeSummary = 'v$rangeFrom – v$rangeTo';
    } else if (rangeFrom != null) {
      rangeSummary = 'from v$rangeFrom';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Book + Chapter row
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
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    color: t.textMuted, letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: _BookPickerField(
                      books: books,
                      selectedBook: selectedBook,
                      enabled: !versionLoading,
                      onSelected: onBookSelected,
                      coordinator: dropdownCoord,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: _ChapterPickerField(
                      chapters: chapters,
                      selectedChapter: selectedChapter,
                      enabled: chapterReady,
                      onSelected: onChapterSelected,
                      coordinator: dropdownCoord,
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
                      verses: verseList,
                      selectedVerse: rangeFrom,
                      enabled: versesReady,
                      coordinator: dropdownCoord,
                      onSelected: (v) {
                        onRangeFromChanged(v);
                        if (rangeTo != null && v != null && rangeTo! < v) {
                          onRangeToChanged(null);
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text('–', style: TextStyle(fontSize: 13, color: t.textMuted)),
                  ),
                  Expanded(
                    child: _VerseRangePickerField(
                      label: 'To',
                      verses: verseList,
                      selectedVerse: rangeTo,
                      enabled: versesReady,
                      minVerse: rangeFrom,
                      coordinator: dropdownCoord,
                      onSelected: onRangeToChanged,
                    ),
                  ),
                  if (rangeTo != null) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => onRangeToChanged(null),
                      child: Icon(Icons.close_rounded, size: 15, color: t.textMuted),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Add to Queue bar
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  rangeSummary.isNotEmpty ? rangeSummary : 'Double-tap verse to go live',
                  style: TextStyle(fontSize: 10, color: t.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: versesReady ? onAddToQueue : null,
                child: AnimatedOpacity(
                  opacity: versesReady ? 1.0 : 0.35,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: t.accentBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: t.accentBlue.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.playlist_add_rounded, size: 14, color: t.accentBlue),
                        const SizedBox(width: 5),
                        Text('Add to Queue',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                color: t.accentBlue)),
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

  // ── Bible version library ──────────────────────────────────────────────────

  Widget _buildVersionLibrary(BuildContext context) {
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
          child: Text('BIBLE VERSIONS',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                  color: t.textMuted, letterSpacing: 1.2)),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: kBibleVersions.length,
            separatorBuilder: (_, _) => Divider(height: 1, color: t.border),
            itemBuilder: (context, index) {
              final version = kBibleVersions[index];
              final bool isActive = version == activeVersion;
              final bool isLoading = isActive && versionLoading;
              return InkWell(
                onTap: () => onVersionSwitch(version),
                hoverColor: t.accentBlue.withValues(alpha: 0.05),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isActive ? t.accentBlue.withValues(alpha: 0.1) : Colors.transparent,
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isActive ? t.accentBlue : t.surfaceHigh,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: isActive ? t.accentBlue : t.border),
                        ),
                        child: isLoading
                            ? SizedBox(
                                height: 12,
                                child: Center(
                                  child: SizedBox(
                                    width: 10, height: 10,
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
                                  fontSize: 10, fontWeight: FontWeight.w800,
                                  color: isActive ? (t.isDark ? t.appBg : Colors.white) : t.textSecondary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(version.fullName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                              color: isActive ? t.accentBlue : t.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (isActive && !isLoading)
                        Icon(Icons.check_rounded, size: 14, color: t.accentBlue),
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
}

// ── Private section label ──────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.accent});
  final String label;
  final Color accent;
  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.menu_book_rounded, size: 13, color: accent),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: t.textPrimary)),
        ],
      ),
    );
  }
}

// ── Book picker overlay field ──────────────────────────────────────────────

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
  final void Function(String) onSelected;
  final dynamic coordinator;
  @override
  State<_BookPickerField> createState() => _BookPickerFieldState();
}

class _BookPickerFieldState extends State<_BookPickerField> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  final _link = LayerLink();
  final _id = 'book';
  OverlayEntry? _overlay;
  List<String> _filtered = [];
  int _hovered = -1;

  @override
  void initState() {
    super.initState();
    _filtered = widget.books;
    _ctrl.text = widget.selectedBook ?? '';
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_BookPickerField old) {
    super.didUpdateWidget(old);
    if (old.selectedBook != widget.selectedBook) {
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
    if (!widget.coordinator.isOpen(_id)) _removeOverlay();
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
                        child: Text('No match',
                            style: TextStyle(fontSize: 12, color: t.textMuted)),
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
                          onExit:  (_) => setSt(() => _hovered = -1),
                          child: GestureDetector(
                            onTap: () => _pick(book),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isHov
                                    ? t.accentBlue.withValues(alpha: 0.12)
                                    : Colors.transparent,
                                border: Border(
                                  left: BorderSide(
                                    color: isHov ? t.accentBlue : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(book,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isHov ? t.accentBlue : t.textPrimary,
                                  )),
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
          contentPadding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
          suffixIcon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: t.textMuted),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: t.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: t.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: t.accentBlue, width: 1.5)),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: t.border.withValues(alpha: 0.4))),
        ),
      ),
    );
  }
}

// ── Chapter picker field ───────────────────────────────────────────────────

class _ChapterPickerField extends StatelessWidget {
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
  final void Function(int) onSelected;
  final dynamic coordinator;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final safeValue = (selectedChapter != null && chapters.contains(selectedChapter))
        ? selectedChapter
        : null;
    return DropdownButtonFormField<int>(
      initialValue: safeValue,
      onChanged: enabled ? (v) { if (v != null) onSelected(v); } : null,
      isExpanded: true,
      menuMaxHeight: 220,
      icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: t.textMuted),
      dropdownColor: t.surfaceHigh,
      style: TextStyle(fontSize: 13, color: t.textPrimary),
      decoration: InputDecoration(
        hintText: 'Ch',
        hintStyle: TextStyle(fontSize: 12, color: t.textMuted),
        isDense: true,
        filled: true,
        fillColor: enabled ? t.appBg : t.appBg.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: t.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: t.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: t.accentBlue, width: 1.5)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: t.border.withValues(alpha: 0.4))),
      ),
      items: chapters.map((c) => DropdownMenuItem(
        value: c,
        child: Text('$c', style: TextStyle(fontSize: 12, color: t.textPrimary)),
      )).toList(),
    );
  }
}

// ── Verse range From/To picker field ──────────────────────────────────────

class _VerseRangePickerField extends StatelessWidget {
  const _VerseRangePickerField({
    required this.label,
    required this.verses,
    required this.selectedVerse,
    required this.enabled,
    required this.coordinator,
    required this.onSelected,
    this.minVerse,
  });
  final String label;
  final List<Map<String, dynamic>> verses;
  final int? selectedVerse;
  final bool enabled;
  final dynamic coordinator;
  final void Function(int?) onSelected;
  final int? minVerse;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final filtered = minVerse != null
        ? verses.where((v) => (v['verse'] as int) >= minVerse!).toList()
        : verses;
    final safeValue = (selectedVerse != null &&
        filtered.any((v) => v['verse'] == selectedVerse))
        ? selectedVerse
        : null;

    return DropdownButtonFormField<int>(
      initialValue: safeValue,
      onChanged: enabled ? onSelected : null,
      isExpanded: true,
      menuMaxHeight: 220,
      icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: t.textMuted),
      dropdownColor: t.surfaceHigh,
      style: TextStyle(fontSize: 13, color: t.textPrimary),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(fontSize: 12, color: t.textMuted),
        isDense: true,
        filled: true,
        fillColor: enabled ? t.appBg : t.appBg.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: t.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: t.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: t.accentBlue, width: 1.5)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: t.border.withValues(alpha: 0.4))),
      ),
      items: filtered.map((v) {
        final n = v['verse'] as int;
        return DropdownMenuItem(
          value: n,
          child: Text('v$n', style: TextStyle(fontSize: 12, color: t.textPrimary)),
        );
      }).toList(),
    );
  }
}
