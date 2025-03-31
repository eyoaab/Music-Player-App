import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../models/song.dart';
import '../../widgets/song_list_item.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Song> _searchResults = [];
  bool _isSearching = false;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRecommendedSongs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendedSongs() async {
    setState(() {
      _isSearching = true;
    });

    try {
      final libraryProvider =
          Provider.of<LibraryProvider>(context, listen: false);
      // Load trending songs instead of genres
      await libraryProvider.loadTrendingSongs();

      // Set search results to trending songs
      setState(() {
        _searchResults = libraryProvider.trendingSongs;
        _isSearching = false;
        _currentQuery = 'Trending Songs';
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      return _loadRecommendedSongs();
    }

    setState(() {
      _isSearching = true;
      _currentQuery = query;
    });

    try {
      final libraryProvider =
          Provider.of<LibraryProvider>(context, listen: false);
      // Use the LibraryProvider's searchSongs method
      await libraryProvider.searchSongs(query);

      setState(() {
        _searchResults = libraryProvider.searchResults;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search songs, artists...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadRecommendedSongs();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onSubmitted: _performSearch,
              textInputAction: TextInputAction.search,
            ),
          ),

          // Search results or loading indicator
          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _currentQuery.isEmpty
                              ? 'Search for songs or artists'
                              : 'No results found for "$_currentQuery"',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Results header
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Text(
                              _currentQuery.isEmpty
                                  ? 'Recommended for you'
                                  : 'Results for "$_currentQuery"',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),

                          // Results list
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 72),
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final song = _searchResults[index];
                                return SongListItem(
                                  song: song,
                                  onTap: () {
                                    final playerProvider =
                                        Provider.of<PlayerProvider>(context,
                                            listen: false);
                                    playerProvider.playSong(song);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
