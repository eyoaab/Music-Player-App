import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../services/connectivity_service.dart';
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

    // Check connectivity
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final connectivityService =
          Provider.of<ConnectivityService>(context, listen: false);
      connectivityService.showConnectivitySnackBar(context);
    });
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

    // Check for connectivity before performing search
    final connectivityService =
        Provider.of<ConnectivityService>(context, listen: false);
    if (!connectivityService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Search requires internet connection. Please connect to the internet.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
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

  void _onSongTapped(Song song, BuildContext context) {
    final PlayerProvider playerProvider =
        Provider.of<PlayerProvider>(context, listen: false);
    final ConnectivityService connectivityService =
        Provider.of<ConnectivityService>(context, listen: false);

    // Check connectivity before playing non-downloaded songs
    if (!song.isDownloaded && !connectivityService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Cannot play song. You are offline and this song is not downloaded.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Play the song
    playerProvider.playSong(song);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final connectivityService = Provider.of<ConnectivityService>(context);

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
                prefixIcon: Icon(Icons.search, color: primaryColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: primaryColor),
                        onPressed: () {
                          _searchController.clear();
                          _loadRecommendedSongs();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: primaryColor, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                ),
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                filled: true,
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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                            ),
                          ),

                          // Results list
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 72),
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final song = _searchResults[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 4.0),
                                  child: Card(
                                    elevation: 2,
                                    shadowColor: primaryColor.withOpacity(0.2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: primaryColor.withOpacity(0.1),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: SongListItem(
                                      song: song,
                                      onTap: () {
                                        _onSongTapped(song, context);
                                      },
                                    ),
                                  ),
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
