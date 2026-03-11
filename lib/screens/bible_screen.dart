import 'package:flutter/material.dart';
import '../app_theme.dart';

/// BibleScreen - Scripture/Bible search and display section
/// Uses AppTheme for full light/dark mode support.
class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  late TextEditingController _searchController;

  // Hardcoded sample scriptures — will connect to SQLite database later
  final List<Map<String, String>> _sampleScriptures = [
    {
      'reference': 'John 3:16',
      'text':
          'For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.',
    },
    {
      'reference': 'Psalm 23:1',
      'text': 'The LORD is my shepherd, I shall not want.',
    },
    {
      'reference': 'Proverbs 3:5-6',
      'text':
          'Trust in the LORD with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.',
    },
    {
      'reference': 'Romans 12:2',
      'text':
          'Do not conform to the pattern of this world, but be transformed by the renewing of your mind.',
    },
    {
      'reference': 'Philippians 4:6',
      'text':
          'Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God.',
    },
  ];

  late Map<String, String> _selectedScripture;
  late List<Map<String, String>> _filteredScriptures;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredScriptures = _sampleScriptures;
    _selectedScripture = _sampleScriptures[0];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Row(
      children: [
        // ── LEFT: search + scripture list ──────────────────────────────────────
        Container(
          width: 350,
          color: t.surface,
          child: Column(
            children: [
              // Search bar
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: t.border)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterScriptures,
                  style: TextStyle(fontSize: 13, color: t.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search scriptures…',
                    hintStyle: TextStyle(fontSize: 12, color: t.textMuted),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: t.textMuted,
                    ),
                    filled: true,
                    fillColor: t.appBg,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
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
                  ),
                ),
              ),

              // Scripture list
              Expanded(
                child: _filteredScriptures.isEmpty
                    ? Center(
                        child: Text(
                          'No results',
                          style: TextStyle(
                            fontSize: 13,
                            color: t.textMuted,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredScriptures.length,
                        separatorBuilder: (_, _) =>
                            Divider(color: t.border, height: 1),
                        itemBuilder: (context, index) {
                          final scripture = _filteredScriptures[index];
                          final isSelected = scripture == _selectedScripture;

                          return InkWell(
                            onTap: () => _selectScripture(scripture),
                            hoverColor: t.accentBlue.withValues(alpha: 0.06),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? t.accentBlue.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                border: Border(
                                  left: BorderSide(
                                    color: isSelected
                                        ? t.accentBlue
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Text(
                                scripture['reference'] ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? t.accentBlue
                                      : t.textPrimary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),

        // Divider between panels
        VerticalDivider(width: 1, color: t.border),

        // ── RIGHT: scripture display ───────────────────────────────────────────
        Expanded(
          child: Container(
            color: t.appBg,
            padding: const EdgeInsets.all(36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: t.border),
                  ),
                  child: Row(
                    children: [
                      // Accent bar
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: t.accentBlue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Reference
                      Expanded(
                        child: Text(
                          _selectedScripture['reference'] ??
                              'No scripture selected',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: t.accentBlue,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      // Bible badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: t.accentBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: t.accentBlue.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          'SAMPLE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: t.accentBlue,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Scripture text card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: t.border),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _selectedScripture['text'] ??
                            'No scripture text available',
                        style: TextStyle(
                          fontSize: 20,
                          height: 1.9,
                          color: t.textPrimary,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.15,
                        ),
                      ),
                    ),
                  ),
                ),

                // Footer
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 24, height: 1, color: t.border),
                      const SizedBox(width: 10),
                      Text(
                        'Church Presentation Software',
                        style: TextStyle(fontSize: 11, color: t.textMuted),
                      ),
                      const SizedBox(width: 10),
                      Container(width: 24, height: 1, color: t.border),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _filterScriptures(String query) {
    setState(() {
      _filteredScriptures = query.isEmpty
          ? _sampleScriptures
          : _sampleScriptures
                .where(
                  (s) =>
                      s['reference']!.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ||
                      s['text']!.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
    });
  }

  void _selectScripture(Map<String, String> scripture) {
    setState(() => _selectedScripture = scripture);
  }
}