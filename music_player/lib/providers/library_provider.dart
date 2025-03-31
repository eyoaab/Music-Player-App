import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/song.dart';
import '../models/playlist.dart';
import '../services/deezer_api_service.dart';
import '../services/download_service.dart';

class LibraryProvider with ChangeNotifier {
  final DeezerApiService _deezerApiService;
  final DownloadService _downloadService;

  // Library data
  List<Song> _favoriteSongs = [];
  List<Song> _downloadedSongs = [];
  List<Playlist> _playlists = [];
  List<Song> _searchResults = [];
  List<Song> _trendingSongs = [];
  List<Song> _recentlyPlayedSongs = [];

  // Loading states
  bool _isLoadingFavorites = false;
  bool _isLoadingDownloaded = false;
  bool _isLoadingPlaylists = false;
  bool _isLoadingSearch = false;
  bool _isLoadingTrending = false;
  bool _isLoadingRecentlyPlayed = false;

  // Search state
  String _currentSearchQuery = '';

  // Getters
  List<Song> get favoriteSongs => _favoriteSongs;
  List<Song> get downloadedSongs => _downloadedSongs;
  List<Playlist> get playlists => _playlists;
  List<Song> get searchResults => _searchResults;
  List<Song> get trendingSongs => _trendingSongs;
  List<Song> get recentlyPlayedSongs => _recentlyPlayedSongs;

  bool get isLoadingFavorites => _isLoadingFavorites;
  bool get isLoadingDownloaded => _isLoadingDownloaded;
  bool get isLoadingPlaylists => _isLoadingPlaylists;
  bool get isLoadingSearch => _isLoadingSearch;
  bool get isLoadingTrending => _isLoadingTrending;
  bool get isLoadingRecentlyPlayed => _isLoadingRecentlyPlayed;

  String get currentSearchQuery => _currentSearchQuery;

  // Maximum number of recently played songs to store
  static const int _maxRecentlyPlayedSongs = 20;

  LibraryProvider({
    required DeezerApiService deezerApiService,
    required DownloadService downloadService,
  })  : _deezerApiService = deezerApiService,
        _downloadService = downloadService {
    _initialize();
  }

  Future<void> _initialize() async {
    // Load data in parallel
    await Future.wait([
      loadFavorites(),
      loadDownloadedSongs(),
      loadPlaylists(),
      loadTrendingSongs(),
      loadRecentlyPlayed(),
    ]);
  }

  // FAVORITES

  Future<void> loadFavorites() async {
    if (_isLoadingFavorites) return;

    _isLoadingFavorites = true;
    notifyListeners();

    try {
      if (kIsWeb) {
        // For web demo, load mock favorites from local storage
        await _loadFavoritesFromStorage();
      } else {
        // For real devices, get user's favorite tracks from Deezer
        final songs = await _deezerApiService.getUserFavoriteTracks();
        _favoriteSongs = songs;

        // Save to local storage
        await _saveFavoritesToStorage();
      }
    } catch (e) {
      debugPrint('Error loading favorite songs: $e');
    } finally {
      _isLoadingFavorites = false;
      notifyListeners();
    }
  }

  Future<void> _loadFavoritesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favsJson = prefs.getString('favorite_songs') ?? '[]';
      final List<dynamic> jsonList = json.decode(favsJson);

      _favoriteSongs = jsonList.map((json) {
        final songMap = Map<String, dynamic>.from(json);
        // Convert duration from int (seconds) back to Duration object
        final durationSeconds = songMap['duration'] as int? ?? 0;
        songMap['duration'] = Duration(seconds: durationSeconds);
        return Song(
          id: songMap['id'] ?? '',
          title: songMap['title'] ?? '',
          artist: songMap['artist'] ?? '',
          artistId: songMap['artistId'] ?? '',
          album: songMap['album'] ?? '',
          albumId: songMap['albumId'] ?? '',
          coverUrl: songMap['coverUrl'] ?? '',
          audioUrl: songMap['audioUrl'] ?? '',
          duration: Duration(seconds: durationSeconds),
          isDownloaded: songMap['isDownloaded'] ?? false,
          localPath: songMap['localPath'],
          genre: songMap['genre'],
          popularity: songMap['popularity'],
          isPlayable: songMap['isPlayable'] ?? true,
          uri: songMap['uri'] ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading favorites from storage: $e');
    }
  }

  Future<void> _saveFavoritesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final songsJson = _favoriteSongs.map((song) => song.toJson()).toList();
      await prefs.setString('favorite_songs', json.encode(songsJson));
    } catch (e) {
      debugPrint('Error saving favorites to storage: $e');
    }
  }

  Future<void> toggleFavorite(Song song) async {
    final isFavorite = _favoriteSongs.any((s) => s.id == song.id);

    if (isFavorite) {
      // Remove from favorites
      _favoriteSongs.removeWhere((s) => s.id == song.id);
      if (!kIsWeb) {
        await _deezerApiService.removeTrackFromFavorites(song.id);
      }
    } else {
      // Add to favorites
      _favoriteSongs.add(song);
      if (!kIsWeb) {
        await _deezerApiService.addTrackToFavorites(song.id);
      }
    }

    await _saveFavoritesToStorage();
    notifyListeners();
  }

  bool isFavorite(String songId) {
    return _favoriteSongs.any((song) => song.id == songId);
  }

  // DOWNLOADS

  Future<void> loadDownloadedSongs() async {
    if (_isLoadingDownloaded) return;

    _isLoadingDownloaded = true;
    notifyListeners();

    try {
      // Load songs from local storage with their full metadata
      final songs = await _downloadService.getDownloadedSongs();
      _downloadedSongs = songs;

      // Log information about loaded songs
      debugPrint('Loaded ${_downloadedSongs.length} downloaded songs');

      // Save history of downloaded song IDs
      await _saveDownloadedSongHistory();
    } catch (e) {
      debugPrint('Error loading downloaded songs: $e');
    } finally {
      _isLoadingDownloaded = false;
      notifyListeners();
    }
  }

  Future<void> downloadSong(Song song) async {
    if (_downloadedSongs.any((s) => s.id == song.id)) {
      debugPrint('Song already downloaded: ${song.title}');
      return;
    }

    try {
      final downloadedSong = await _downloadService.downloadSong(song);
      if (downloadedSong != null) {
        _downloadedSongs.add(downloadedSong);

        // Save history of downloaded song IDs
        await _saveDownloadedSongHistory();

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error downloading song: $e');
      rethrow;
    }
  }

  Future<void> deleteSongDownload(String songId) async {
    try {
      final song = _downloadedSongs.firstWhere((s) => s.id == songId);
      await _downloadService.deleteSongFile(song);
      _downloadedSongs.removeWhere((s) => s.id == songId);

      // Save history of downloaded song IDs
      await _saveDownloadedSongHistory();

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting song download: $e');
      rethrow;
    }
  }

  // Save history of downloaded song IDs
  Future<void> _saveDownloadedSongHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final songIds = _downloadedSongs.map((song) => song.id).toList();
      await prefs.setStringList('downloaded_song_ids', songIds);
      debugPrint('Saved history of ${songIds.length} downloaded songs');
    } catch (e) {
      debugPrint('Error saving downloaded song history: $e');
    }
  }

  bool isDownloaded(String songId) {
    return _downloadedSongs.any((song) => song.id == songId);
  }

  Future<int> calculateStorageUsage() async {
    try {
      int totalSize = 0;

      if (kIsWeb) {
        // For web, we can't actually calculate storage so return a dummy value
        return _downloadedSongs.length * 5 * 1024 * 1024; // Assume 5MB per song
      }

      for (final song in _downloadedSongs) {
        if (song.localPath != null) {
          final file = File(song.localPath!);
          if (await file.exists()) {
            totalSize += await file.length();
          }
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('Error calculating storage usage: $e');
      return 0;
    }
  }

  // PLAYLISTS

  Future<void> loadPlaylists() async {
    if (_isLoadingPlaylists) return;

    _isLoadingPlaylists = true;
    notifyListeners();

    try {
      await _loadPlaylistsFromStorage();
    } catch (e) {
      debugPrint('Error loading playlists: $e');
    } finally {
      _isLoadingPlaylists = false;
      notifyListeners();
    }
  }

  Future<void> _loadPlaylistsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistsJson = prefs.getString('playlists') ?? '[]';
      final List<dynamic> jsonList = json.decode(playlistsJson);

      _playlists = jsonList.map((json) => Playlist.fromJson(json)).toList();

      // Load songs for each playlist
      for (var i = 0; i < _playlists.length; i++) {
        final playlist = _playlists[i];
        final songIds = playlist.songIds;
        final songs = <Song>[];

        for (final songId in songIds) {
          // First check if the song is in favorites or downloaded songs
          Song? song = _favoriteSongs.firstWhere(
            (s) => s.id == songId,
            orElse: () => Song.empty(),
          );

          if (song.id.isEmpty) {
            song = _downloadedSongs.firstWhere(
              (s) => s.id == songId,
              orElse: () => Song.empty(),
            );
          }

          // If not found locally, try to fetch from API
          if (song.id.isEmpty) {
            try {
              final apiSong = await _deezerApiService.getTrack(songId);
              if (apiSong != null) {
                songs.add(apiSong);
                continue;
              }
            } catch (e) {
              debugPrint('Error fetching song from API: $e');
            }
          } else if (song.id.isNotEmpty) {
            songs.add(song);
          }
        }

        // Update playlist songs
        _playlists[i] = playlist.copyWith(songs: songs);
      }

      debugPrint('Loaded ${_playlists.length} playlists with their songs');
    } catch (e) {
      debugPrint('Error loading playlists from storage: $e');
    }
  }

  Future<void> _savePlaylistsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistsJson =
          _playlists.map((playlist) => playlist.toJson()).toList();
      await prefs.setString('playlists', json.encode(playlistsJson));
      debugPrint('Saved ${_playlists.length} playlists to storage');
    } catch (e) {
      debugPrint('Error saving playlists to storage: $e');
    }
  }

  Future<Playlist> createPlaylist(String name,
      [String? description, String? coverUrl]) async {
    final id = 'local_playlist_${DateTime.now().millisecondsSinceEpoch}';
    final playlist = Playlist.create(
      id: id,
      name: name,
      description: description,
      coverUrl: coverUrl,
    );

    _playlists.add(playlist);
    await _savePlaylistsToStorage();
    notifyListeners();

    debugPrint('Created new playlist: "${name}" with ID: $id');
    return playlist;
  }

  Future<void> updatePlaylist(Playlist updatedPlaylist) async {
    final index = _playlists.indexWhere((p) => p.id == updatedPlaylist.id);
    if (index != -1) {
      _playlists[index] = updatedPlaylist;
      await _savePlaylistsToStorage();
      notifyListeners();
      debugPrint('Updated playlist: "${updatedPlaylist.name}"');
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    final playlistName = _playlists
        .firstWhere((p) => p.id == playlistId,
            orElse: () => Playlist.create(id: '', name: 'Unknown'))
        .name;
    _playlists.removeWhere((p) => p.id == playlistId);
    await _savePlaylistsToStorage();
    notifyListeners();
    debugPrint('Deleted playlist: "$playlistName"');
  }

  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final updated = _playlists[index].addSong(song.id, song);
      _playlists[index] = updated;
      await _savePlaylistsToStorage();
      notifyListeners();
      debugPrint(
          'Added song "${song.title}" to playlist "${_playlists[index].name}"');
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final songName = _playlists[index]
          .songs
          .firstWhere((s) => s.id == songId, orElse: () => Song.empty())
          .title;
      final updated = _playlists[index].removeSong(songId);
      _playlists[index] = updated;
      await _savePlaylistsToStorage();
      notifyListeners();
      debugPrint(
          'Removed song "$songName" from playlist "${_playlists[index].name}"');
    }
  }

  // SEARCH

  Future<void> searchSongs(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _currentSearchQuery = '';
      notifyListeners();
      return;
    }

    if (query == _currentSearchQuery) return;

    _isLoadingSearch = true;
    _currentSearchQuery = query;
    notifyListeners();

    try {
      final results = await _deezerApiService.searchTracks(query);
      _searchResults = results;
    } catch (e) {
      debugPrint('Error searching songs: $e');
    } finally {
      _isLoadingSearch = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    _currentSearchQuery = '';
    notifyListeners();
  }

  // TRENDING SONGS

  Future<void> loadTrendingSongs() async {
    if (_isLoadingTrending) return;

    _isLoadingTrending = true;
    notifyListeners();

    try {
      final trending = await _deezerApiService.getChartTracks();
      _trendingSongs = trending;
    } catch (e) {
      debugPrint('Error loading trending songs: $e');
    } finally {
      _isLoadingTrending = false;
      notifyListeners();
    }
  }

  // RECENTLY PLAYED SONGS

  Future<void> loadRecentlyPlayed() async {
    if (_isLoadingRecentlyPlayed) return;

    _isLoadingRecentlyPlayed = true;
    notifyListeners();

    try {
      await _loadRecentlyPlayedFromStorage();
    } catch (e) {
      debugPrint('Error loading recently played songs: $e');
    } finally {
      _isLoadingRecentlyPlayed = false;
      notifyListeners();
    }
  }

  Future<void> _loadRecentlyPlayedFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentJson = prefs.getString('recently_played_songs') ?? '[]';
      final List<dynamic> jsonList = json.decode(recentJson);

      _recentlyPlayedSongs = jsonList.map((json) {
        final songMap = Map<String, dynamic>.from(json);
        // Convert duration from int (seconds) back to Duration object
        final durationSeconds = songMap['duration'] as int? ?? 0;
        return Song(
          id: songMap['id'] ?? '',
          title: songMap['title'] ?? '',
          artist: songMap['artist'] ?? '',
          artistId: songMap['artistId'] ?? '',
          album: songMap['album'] ?? '',
          albumId: songMap['albumId'] ?? '',
          coverUrl: songMap['coverUrl'] ?? '',
          audioUrl: songMap['audioUrl'] ?? '',
          duration: Duration(seconds: durationSeconds),
          isDownloaded: songMap['isDownloaded'] ?? false,
          localPath: songMap['localPath'],
          genre: songMap['genre'],
          popularity: songMap['popularity'],
          isPlayable: songMap['isPlayable'] ?? true,
          uri: songMap['uri'] ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading recently played from storage: $e');
    }
  }

  Future<void> _saveRecentlyPlayedToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final songsJson =
          _recentlyPlayedSongs.map((song) => song.toJson()).toList();
      await prefs.setString('recently_played_songs', json.encode(songsJson));
    } catch (e) {
      debugPrint('Error saving recently played to storage: $e');
    }
  }

  Future<void> addToRecentlyPlayed(Song song) async {
    // Remove the song if it already exists in the list
    _recentlyPlayedSongs.removeWhere((s) => s.id == song.id);

    // Add the song to the beginning of the list
    _recentlyPlayedSongs.insert(0, song);

    // Trim the list to the maximum number of recently played songs
    if (_recentlyPlayedSongs.length > _maxRecentlyPlayedSongs) {
      _recentlyPlayedSongs =
          _recentlyPlayedSongs.sublist(0, _maxRecentlyPlayedSongs);
    }

    await _saveRecentlyPlayedToStorage();
    notifyListeners();
  }
}
