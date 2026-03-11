import 'package:flutter/material.dart';

/// SongScreen - Songs and lyrics section
/// Users can search for and view songs with lyrics
class SongScreen extends StatefulWidget {
  const SongScreen({super.key});

  @override
  State<SongScreen> createState() => _SongScreenState();
}

class _SongScreenState extends State<SongScreen> {
  // Controller to manage the search bar input
  late TextEditingController _searchController;

  // Sample songs data - will be replaced with database later
  final List<Map<String, String>> _sampleSongs = [
    {
      'title': 'Amazing Grace',
      'artist': 'John Newton',
      'lyrics':
          'Amazing grace, how sweet the sound\nThat saved a wretch like me...',
    },
    {
      'title': 'How Great Thou Art',
      'artist': 'Carl Boberg',
      'lyrics':
          'O Lord my God, when I in awesome wonder\nConsider all the worlds thy hands have made...',
    },
    {
      'title': 'Jesus Loves Me',
      'artist': 'Traditional',
      'lyrics': 'Jesus loves me, this I know\nFor the Bible tells me so...',
    },
  ];

  // Currently selected song
  late Map<String, String> _selectedSong;

  // Filtered songs based on search
  late List<Map<String, String>> _filteredSongs;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredSongs = _sampleSongs;
    _selectedSong = _sampleSongs[0];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // LEFT SIDE: Search bar and Song list
        Container(
          width: 350,
          color: Colors.grey[900],
          child: Column(
            children: [
              // SEARCH BAR
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterSongs,
                  decoration: InputDecoration(
                    hintText: 'Search songs...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[800],
                  ),
                ),
              ),

              // SONG LIST
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredSongs.length,
                  itemBuilder: (context, index) {
                    final song = _filteredSongs[index];
                    final isSelected = song == _selectedSong;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _selectSong(song),
                        hoverColor: Colors.purple.withValues(alpha: 0.2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.purple.withValues(alpha: 0.3)
                                : Colors.transparent,
                            border: isSelected
                                ? Border(
                                    left: BorderSide(
                                      color: Colors.purple,
                                      width: 4,
                                    ),
                                  )
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song['title'] ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.purple
                                      : Colors.white,
                                ),
                              ),
                              Text(
                                song['artist'] ?? 'Unknown Artist',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
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

        // RIGHT SIDE: Song display
        Expanded(
          child: Container(
            color: Colors.black,
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Song title
                Text(
                  _selectedSong['title'] ?? 'No song selected',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 8),

                // Song artist
                Text(
                  'by ${_selectedSong['artist'] ?? 'Unknown'}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                ),
                const SizedBox(height: 24),

                // Song lyrics display
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      _selectedSong['lyrics'] ?? 'No lyrics available',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 2.0,
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

  /// Filter songs based on search input
  void _filterSongs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSongs = _sampleSongs;
      } else {
        _filteredSongs = _sampleSongs
            .where(
              (song) =>
                  song['title']!.toLowerCase().contains(query.toLowerCase()) ||
                  song['artist']!.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  /// Select a song to display
  void _selectSong(Map<String, String> song) {
    setState(() {
      _selectedSong = song;
    });
  }
}
