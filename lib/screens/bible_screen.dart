import 'package:flutter/material.dart';

/// BibleScreen - Scripture/Bible search and display section
/// Users can search for scriptures and view them with formatting
class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  // Controller to manage the search bar input
  late TextEditingController _searchController;

  // For now, hardcoded sample scriptures - will connect to SQLite database later
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

  // Currently selected scripture to display
  late Map<String, String> _selectedScripture;

  // List of filtered scriptures based on search
  late List<Map<String, String>> _filteredScriptures;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredScriptures = _sampleScriptures;
    // Select the first scripture by default
    _selectedScripture = _sampleScriptures[0];
  }

  @override
  void dispose() {
    // Clean up the search controller
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // LEFT SIDE: Search bar and Scripture list
        Container(
          width: 350, // Fixed width for left panel
          color: Colors.grey[900], // Darker background for list panel
          child: Column(
            children: [
              // SEARCH BAR
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  // Update filtered list as user types
                  onChanged: _filterScriptures,
                  decoration: InputDecoration(
                    hintText: 'Search scriptures...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[800],
                  ),
                ),
              ),

              // SCRIPTURE LIST
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredScriptures.length,
                  itemBuilder: (context, index) {
                    final scripture = _filteredScriptures[index];
                    final isSelected = scripture == _selectedScripture;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        // Select scripture when tapped
                        onTap: () => _selectScripture(scripture),
                        hoverColor: Colors.cyan.withValues(alpha: 0.2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            // Highlight selected scripture
                            color: isSelected
                                ? Colors.cyan.withValues(alpha: 0.3)
                                : Colors.transparent,
                            border: isSelected
                                ? Border(
                                    left: BorderSide(
                                      color: Colors.cyan,
                                      width: 4,
                                    ),
                                  )
                                : null,
                          ),
                          child: Text(
                            scripture['reference'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? Colors.cyan : Colors.white,
                            ),
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

        // RIGHT SIDE: Scripture display
        Expanded(
          child: Container(
            color: Colors.black,
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Scripture reference as title
                Text(
                  _selectedScripture['reference'] ?? 'No scripture selected',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan,
                  ),
                ),
                const SizedBox(height: 24),

                // Scripture text display
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      _selectedScripture['text'] ??
                          'No scripture text available',
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.8, // Line height for readability
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Update the filtered scriptures list based on search input
  void _filterScriptures(String query) {
    setState(() {
      if (query.isEmpty) {
        // Show all scriptures if search is empty
        _filteredScriptures = _sampleScriptures;
      } else {
        // Filter scriptures by reference or text content
        _filteredScriptures = _sampleScriptures
            .where(
              (scripture) =>
                  scripture['reference']!.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  scripture['text']!.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
      }
    });
  }

  /// Select a scripture and display it
  void _selectScripture(Map<String, String> scripture) {
    setState(() {
      _selectedScripture = scripture;
    });
  }
}
