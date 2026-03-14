// ─────────────────────────────────────────────────────────────────────────────
// SERVICE PLAN PANEL  (far right column)
// Shows the ordered service plan list with collapsible sections,
// quick-add bar, and the reference history shelf.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models.dart';
import 'shared_widgets.dart';

class ServicePlanPanel extends StatelessWidget {
  const ServicePlanPanel({
    super.key,
    required this.sections,
    required this.activeIndex,
    required this.activeSectionIdx,
    required this.serviceTitle,
    required this.serviceDate,
    required this.history,
    required this.shelfExpanded,
    required this.quickAddCtrl,
    required this.planScroll,
    required this.activeItem,
    required this.onSelectItem,
    required this.onRemoveItem,
    required this.onSectionCollapse,
    required this.onSectionRename,
    required this.onSectionMergeUp,
    required this.onSectionDelete,
    required this.onSectionAdd,
    required this.onSetActiveSection,
    required this.onQuickAdd,
    required this.onSave,
    required this.onLoad,
    required this.onNew,
    required this.onEditTitle,
    required this.onPickDate,
    required this.onClearAll,
    required this.onShelfToggle,
    required this.onShelfClear,
    required this.onShelfItemTap,
  });

  final List<PlanSection> sections;
  final int activeIndex;
  final int activeSectionIdx;
  final String serviceTitle;
  final DateTime serviceDate;
  final List<ServiceItem> history;
  final bool shelfExpanded;
  final TextEditingController quickAddCtrl;
  final ScrollController planScroll;
  final ServiceItem? activeItem;

  final void Function(int) onSelectItem;
  final void Function(int) onRemoveItem;
  final void Function(int) onSectionCollapse;
  final void Function(int) onSectionRename;
  final void Function(int) onSectionMergeUp;
  final void Function(int) onSectionDelete;
  final VoidCallback onSectionAdd;
  final void Function(int) onSetActiveSection;
  final void Function(String) onQuickAdd;
  final VoidCallback onSave;
  final VoidCallback onLoad;
  final VoidCallback onNew;
  final VoidCallback onEditTitle;
  final VoidCallback onPickDate;
  final VoidCallback onClearAll;
  final VoidCallback onShelfToggle;
  final VoidCallback onShelfClear;
  final void Function(ServiceItem) onShelfItemTap;

  List<ServiceItem> get _plan => sections.expand((s) => s.items).toList();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.border, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Plan header ──────────────────────────────────────────────────
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
                    onTap: onEditTitle,
                    child: Text(serviceTitle,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: t.textPrimary),
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
                GestureDetector(
                  onTap: onPickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: t.appBg, borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: t.border),
                    ),
                    child: Text(
                      '${serviceDate.day}/${serviceDate.month}/${serviceDate.year}',
                      style: TextStyle(fontSize: 10, color: t.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconTip(icon: Icons.save_rounded, tooltip: 'Save service',
                    color: t.accentBlue, onTap: onSave),
                const SizedBox(width: 4),
                IconTip(icon: Icons.folder_open_rounded, tooltip: 'Load saved service',
                    color: t.textSecondary, onTap: onLoad),
                const SizedBox(width: 4),
                IconTip(icon: Icons.add_circle_outline_rounded, tooltip: 'New service',
                    color: t.textSecondary, onTap: onNew),
              ],
            ),
          ),

          // ── Quick-add bar ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.border)),
            ),
            child: TextField(
              controller: quickAddCtrl,
              style: TextStyle(fontSize: 12, color: t.textPrimary),
              onSubmitted: onQuickAdd,
              decoration: InputDecoration(
                hintText: 'Quick-add: John 3:16, Amazing Grace, black…',
                hintStyle: TextStyle(fontSize: 11, color: t.textMuted),
                isDense: true,
                filled: true,
                fillColor: t.appBg,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                suffixIcon: IconButton(
                  icon: Icon(Icons.add_rounded, size: 16, color: t.accentBlue),
                  tooltip: 'Add items',
                  onPressed: () => onQuickAdd(quickAddCtrl.text),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(7),
                    borderSide: BorderSide(color: t.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7),
                    borderSide: BorderSide(color: t.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7),
                    borderSide: BorderSide(color: t.accentBlue, width: 1.5)),
              ),
            ),
          ),

          // ── Item count + clear ───────────────────────────────────────────
          if (_plan.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: t.border)),
              ),
              child: Row(
                children: [
                  Text('${_plan.length} item${_plan.length == 1 ? "" : "s"}',
                      style: TextStyle(fontSize: 10, color: t.textMuted)),
                  const Spacer(),
                  IconTip(icon: Icons.delete_sweep_rounded, tooltip: 'Clear all',
                      color: t.textMuted, onTap: onClearAll),
                ],
              ),
            ),

          // ── Plan list ────────────────────────────────────────────────────
          Expanded(
            child: _plan.isEmpty && sections.every((s) => s.items.isEmpty)
                ? _EmptyPlan(t: t, onLoad: onLoad)
                : _SectionedPlan(
                    sections: sections,
                    activeIndex: activeIndex,
                    activeSectionIdx: activeSectionIdx,
                    planScroll: planScroll,
                    onSelectItem: onSelectItem,
                    onRemoveItem: onRemoveItem,
                    onSectionCollapse: onSectionCollapse,
                    onSectionRename: onSectionRename,
                    onSectionMergeUp: onSectionMergeUp,
                    onSectionDelete: onSectionDelete,
                    onSectionAdd: onSectionAdd,
                    onSetActiveSection: onSetActiveSection,
                  ),
          ),

          // ── Reference shelf ──────────────────────────────────────────────
          _ReferenceShelf(
            history: history,
            shelfExpanded: shelfExpanded,
            activeItem: activeItem,
            onToggle: onShelfToggle,
            onClear: onShelfClear,
            onItemTap: onShelfItemTap,
          ),
        ],
      ),
    );
  }
}

// ── Empty plan placeholder ─────────────────────────────────────────────────

class _EmptyPlan extends StatelessWidget {
  const _EmptyPlan({required this.t, required this.onLoad});
  final AppTheme t;
  final VoidCallback onLoad;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.playlist_add_rounded, size: 28, color: t.textMuted),
        const SizedBox(height: 10),
        Text('Service plan is empty', style: TextStyle(fontSize: 12, color: t.textMuted)),
        const SizedBox(height: 4),
        Text('Type a reference above (John 3:16, Ps 23…)\nor add from the verse/song overview.',
            style: TextStyle(fontSize: 10, color: t.textMuted, height: 1.5),
            textAlign: TextAlign.center),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: onLoad,
          child: Text('Load a saved service',
              style: TextStyle(fontSize: 11, color: t.accentBlue,
                  decoration: TextDecoration.underline,
                  decorationColor: t.accentBlue)),
        ),
      ]),
    );
  }
}

// ── Sectioned plan list ────────────────────────────────────────────────────

class _SectionedPlan extends StatelessWidget {
  const _SectionedPlan({
    required this.sections,
    required this.activeIndex,
    required this.activeSectionIdx,
    required this.planScroll,
    required this.onSelectItem,
    required this.onRemoveItem,
    required this.onSectionCollapse,
    required this.onSectionRename,
    required this.onSectionMergeUp,
    required this.onSectionDelete,
    required this.onSectionAdd,
    required this.onSetActiveSection,
  });

  final List<PlanSection> sections;
  final int activeIndex;
  final int activeSectionIdx;
  final ScrollController planScroll;
  final void Function(int) onSelectItem;
  final void Function(int) onRemoveItem;
  final void Function(int) onSectionCollapse;
  final void Function(int) onSectionRename;
  final void Function(int) onSectionMergeUp;
  final void Function(int) onSectionDelete;
  final VoidCallback onSectionAdd;
  final void Function(int) onSetActiveSection;


  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ListView(
      controller: planScroll,
      children: [
        for (int si = 0; si < sections.length; si++) ...[
          _SectionHeader(
            si: si,
            section: sections[si],
            isTarget: si == activeSectionIdx,
            canMergeUp: sections.length > 1,
            t: t,
            onCollapse: () => onSectionCollapse(si),
            onRename: () => onSectionRename(si),
            onMergeUp: () => onSectionMergeUp(si),
            onDelete: () => onSectionDelete(si),
            onSetTarget: () => onSetActiveSection(si),
          ),
          if (!sections[si].isCollapsed) ...[
            ...() {
              int offset = 0;
              for (int k = 0; k < si; k++) {
                offset += sections[k].items.length;
              }
              return List.generate(sections[si].items.length, (ii) =>
                _PlanRow(
                  index: offset + ii,
                  item: sections[si].items[ii],
                  isActive: (offset + ii) == activeIndex,
                  isDone: activeIndex >= 0 && (offset + ii) < activeIndex,
                  onTap: () => onSelectItem(offset + ii),
                  onRemove: () => onRemoveItem(offset + ii),
                ));
            }(),
            if (sections[si].items.isEmpty)
              Container(
                key: ValueKey('empty-$si'),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: si == activeSectionIdx
                        ? t.accentBlue.withValues(alpha: 0.4)
                        : t.border.withValues(alpha: 0.4),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(child: Text(
                  'No items — use quick-add or tap + on a verse/song',
                  style: TextStyle(fontSize: 10, color: t.textMuted),
                  textAlign: TextAlign.center,
                )),
              ),
          ],
        ],
        // Add section button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: GestureDetector(
            onTap: onSectionAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: t.border),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_rounded, size: 13, color: t.textMuted),
                const SizedBox(width: 4),
                Text('Add Section', style: TextStyle(fontSize: 11, color: t.textMuted)),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.si,
    required this.section,
    required this.isTarget,
    required this.canMergeUp,
    required this.t,
    required this.onCollapse,
    required this.onRename,
    required this.onMergeUp,
    required this.onDelete,
    required this.onSetTarget,
  });
  final int si;
  final PlanSection section;
  final bool isTarget;
  final bool canMergeUp;
  final AppTheme t;
  final VoidCallback onCollapse;
  final VoidCallback onRename;
  final VoidCallback onMergeUp;
  final VoidCallback onDelete;
  final VoidCallback onSetTarget;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCollapse,
      onDoubleTap: onRename,
      child: Container(
        key: ValueKey('sec-$si'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isTarget ? t.accentBlue.withValues(alpha: 0.07) : t.surfaceHigh,
          border: Border(
            top: BorderSide(color: t.border),
            bottom: BorderSide(color: t.border),
            left: BorderSide(color: isTarget ? t.accentBlue : Colors.transparent, width: 3),
          ),
        ),
        child: Row(
          children: [
            AnimatedRotation(
              turns: section.isCollapsed ? -0.25 : 0,
              duration: const Duration(milliseconds: 150),
              child: Icon(Icons.expand_more_rounded, size: 16, color: t.textSecondary),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(section.title,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: isTarget ? t.accentBlue : t.textSecondary,
                      letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis),
            ),
            if (section.items.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: t.border, borderRadius: BorderRadius.circular(10)),
                child: Text('${section.items.length}',
                    style: TextStyle(fontSize: 9, color: t.textMuted, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 6),
            ],
            Tooltip(
              message: isTarget ? 'Adding items here' : 'Add items to this section',
              child: GestureDetector(
                onTap: onSetTarget,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isTarget ? t.accentBlue.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    isTarget ? Icons.playlist_add_check_rounded : Icons.playlist_add_rounded,
                    size: 14, color: isTarget ? t.accentBlue : t.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.more_vert_rounded, size: 14, color: t.textMuted),
              iconSize: 14,
              itemBuilder: (_) => [
                PopupMenuItem(value: 'rename',
                    child: Row(children: [
                      Icon(Icons.edit_rounded, size: 14, color: t.textSecondary),
                      const SizedBox(width: 8),
                      const Text('Rename', style: TextStyle(fontSize: 12)),
                    ])),
                if (canMergeUp)
                  PopupMenuItem(value: 'merge_up', enabled: si > 0,
                      child: Row(children: [
                        Icon(Icons.merge_rounded, size: 14, color: t.textSecondary),
                        const SizedBox(width: 8),
                        const Text('Merge into above', style: TextStyle(fontSize: 12)),
                      ])),
                const PopupMenuDivider(),
                PopupMenuItem(value: 'delete',
                    child: Row(children: [
                      const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      const Text('Delete section',
                          style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                    ])),
              ],
              onSelected: (val) {
                if (val == 'rename') onRename();
                if (val == 'merge_up') onMergeUp();
                if (val == 'delete') onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Plan row ───────────────────────────────────────────────────────────────

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.index,
    required this.item,
    required this.isActive,
    required this.isDone,
    required this.onTap,
    required this.onRemove,
  });
  final int index;
  final ServiceItem item;
  final bool isActive;
  final bool isDone;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final accent = item.accentColor(t);

    return InkWell(
      key: ValueKey(item.id),
      onTap: onTap,
      hoverColor: accent.withValues(alpha: 0.05),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isActive ? accent.withValues(alpha: 0.1) : Colors.transparent,
          border: Border(
            left: BorderSide(color: isActive ? accent : Colors.transparent, width: 3),
            bottom: BorderSide(color: t.border.withValues(alpha: 0.5)),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.drag_indicator_rounded, size: 13, color: t.textMuted),
            const SizedBox(width: 6),
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: isActive ? accent.withValues(alpha: 0.2) : t.surfaceHigh,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(item.icon, size: 13,
                  color: isDone ? t.textMuted : isActive ? accent : accent.withValues(alpha: 0.7)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.title,
                    style: TextStyle(fontSize: 12,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isDone ? t.textMuted : isActive ? accent : t.textPrimary,
                        decoration: isDone ? TextDecoration.lineThrough : null),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (item.subtitle.isNotEmpty)
                  Text(item.subtitle,
                      style: TextStyle(fontSize: 11,
                          color: isDone ? t.textMuted : t.textSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
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
                          isDone ? t.textMuted : accent),
                    ),
                  ),
                ],
              ]),
            ),
            if (isActive) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text('LIVE',
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800,
                        color: accent, letterSpacing: 0.8)),
              ),
              const SizedBox(width: 6),
            ],
            GestureDetector(
              onTap: onRemove,
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
}

// ── Reference shelf ────────────────────────────────────────────────────────

class _ReferenceShelf extends StatelessWidget {
  const _ReferenceShelf({
    required this.history,
    required this.shelfExpanded,
    required this.activeItem,
    required this.onToggle,
    required this.onClear,
    required this.onItemTap,
  });
  final List<ServiceItem> history;
  final bool shelfExpanded;
  final ServiceItem? activeItem;
  final VoidCallback onToggle;
  final VoidCallback onClear;
  final void Function(ServiceItem) onItemTap;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();
    final t = context.t;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        border: Border(top: BorderSide(color: t.border, width: 1.5)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(children: [
                Icon(Icons.history_rounded, size: 13, color: t.textMuted),
                const SizedBox(width: 6),
                Text('Reference Shelf',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: t.textMuted, letterSpacing: 0.3)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: t.border, borderRadius: BorderRadius.circular(8)),
                  child: Text('${history.length}',
                      style: TextStyle(fontSize: 9, color: t.textSecondary,
                          fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onClear,
                  child: Tooltip(message: 'Clear shelf',
                      child: Icon(Icons.clear_all_rounded, size: 14, color: t.textMuted)),
                ),
                const SizedBox(width: 6),
                Icon(shelfExpanded ? Icons.expand_more_rounded : Icons.chevron_right_rounded,
                    size: 14, color: t.textMuted),
              ]),
            ),
          ),
          if (shelfExpanded)
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                itemCount: history.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, i) => _ShelfChip(
                  item: history[i],
                  isActive: activeItem?.id == history[i].id,
                  onTap: () => onItemTap(history[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShelfChip extends StatelessWidget {
  const _ShelfChip({required this.item, required this.isActive, required this.onTap});
  final ServiceItem item;
  final bool isActive;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final accent = item.accentColor(t);
    return Tooltip(
      message: '${item.title}${item.subtitle.isNotEmpty ? "\n${item.subtitle}" : ""}',
      child: GestureDetector(
        onTap: onTap,
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
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(item.icon, size: 11, color: isActive ? accent : t.textMuted),
            const SizedBox(width: 5),
            Flexible(child: Text(item.title,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                    color: isActive ? accent : t.textSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ),
      ),
    );
  }
}
