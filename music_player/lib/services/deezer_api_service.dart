import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/deezer_config.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/playlist.dart';
import 'deezer_auth_service.dart';

class DeezerApiService {
  final Dio _dio;
  final DeezerAuthService? _authService;

  /// Create a DeezerApiService
  /// [authService] is OPTIONAL - if null, only public API endpoints will be accessible
  DeezerApiService([this._authService]) : _dio = Dio() {
    _dio.options.baseUrl = DeezerConfig.apiBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 20);
    _dio.options.receiveTimeout = const Duration(seconds: 20);
  }

  /// Check if user-specific features are available (requires auth)
  bool get canAccessUserFeatures =>
      _authService != null && _authService!.isAuthenticated;

  // SEARCH METHODS (public API - no auth required)

  // Search for tracks
  Future<List<Song>> searchTracks(String query,
      {int limit = 20, int offset = 0}) async {
    try {
      final response = await _dio.get(
        '/search/track',
        queryParameters: {
          'q': query,
          'limit': limit,
          'index': offset,
        },
      );

      if (response.data == null || response.data['data'] == null) {
        return [];
      }

      final List<dynamic> tracks = response.data['data'];
      log('tracks: $tracks');
      return tracks.map((track) => Song.fromDeezerJson(track)).toList();
    } catch (e) {
      debugPrint('Error searching tracks: $e');
      return [];
    }
  }

  // Get track details (public API - no auth required)
  Future<Song?> getTrack(String trackId) async {
    try {
      final response = await _dio.get('/track/$trackId');
      if (response.data == null) return null;
      return Song.fromDeezerJson(response.data);
    } catch (e) {
      debugPrint('Error getting track details: $e');
      return null;
    }
  }

  // Get artist details (public API - no auth required)
  Future<Artist?> getArtist(String artistId) async {
    try {
      final response = await _dio.get('/artist/$artistId');
      if (response.data == null) return null;

      return Artist.fromDeezerJson(response.data);
    } catch (e) {
      debugPrint('Error getting artist details: $e');
      return null;
    }
  }

  // Get artist's top tracks (public API - no auth required)
  Future<List<Song>> getArtistTopTracks(String artistId,
      {int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/artist/$artistId/top',
        queryParameters: {'limit': limit},
      );

      if (response.data == null || response.data['data'] == null) {
        return [];
      }

      final List<dynamic> tracks = response.data['data'];
      return tracks.map((track) => Song.fromDeezerJson(track)).toList();
    } catch (e) {
      debugPrint('Error getting artist\'s top tracks: $e');
      return [];
    }
  }

  // Get album details (public API - no auth required)
  Future<Album?> getAlbum(String albumId) async {
    try {
      final response = await _dio.get('/album/$albumId');
      if (response.data == null) return null;

      return Album.fromDeezerJson(response.data);
    } catch (e) {
      debugPrint('Error getting album details: $e');
      return null;
    }
  }

  // Get charts/trending tracks (public API - no auth required)
  Future<List<Song>> getChartTracks({int limit = 20}) async {
    try {
      final response = await _dio.get(
        '/chart/0/tracks',
        queryParameters: {'limit': limit},
      );

      if (response.data == null || response.data['data'] == null) {
        return [];
      }

      final List<dynamic> tracks = response.data['data'];
      return tracks.map((track) => Song.fromDeezerJson(track)).toList();
    } catch (e) {
      debugPrint('Error getting chart tracks: $e');
      return [];
    }
  }

  // PLAYLIST METHODS (public API - no auth required for public playlists)

  // Get playlist tracks
  Future<List<Song>> getPlaylistTracks(String playlistId,
      {int limit = 20, int offset = 0}) async {
    try {
      final response = await _dio.get(
        '/playlist/$playlistId/tracks',
        queryParameters: {
          'limit': limit,
          'index': offset,
        },
      );

      if (response.data == null || response.data['data'] == null) {
        return [];
      }

      final List<dynamic> tracks = response.data['data'];
      return tracks.map((track) => Song.fromDeezerJson(track)).toList();
    } catch (e) {
      debugPrint('Error getting playlist tracks: $e');
      return [];
    }
  }

  // USER-SPECIFIC METHODS (require authentication)

  // Get user's favorite tracks (requires auth)
  Future<List<Song>> getUserFavoriteTracks(
      {int limit = 20, int offset = 0}) async {
    if (!canAccessUserFeatures) {
      debugPrint('Authentication required for user favorite tracks');
      return [];
    }

    try {
      final response = await _dio.get(
        '/user/me/tracks',
        queryParameters: {
          'limit': limit,
          'index': offset,
        },
      );

      if (response.data == null || response.data['data'] == null) {
        return [];
      }

      final List<dynamic> tracks = response.data['data'];
      return tracks.map((track) => Song.fromDeezerJson(track)).toList();
    } catch (e) {
      debugPrint('Error getting user\'s favorite tracks: $e');
      return [];
    }
  }

  // Get user's playlists (requires auth)
  Future<List<Playlist>> getUserPlaylists(
      {int limit = 20, int offset = 0}) async {
    if (!canAccessUserFeatures) {
      debugPrint('Authentication required for user playlists');
      return [];
    }

    try {
      final response = await _dio.get(
        '/user/me/playlists',
        queryParameters: {
          'limit': limit,
          'index': offset,
        },
      );

      if (response.data == null || response.data['data'] == null) {
        return [];
      }

      final List<dynamic> playlists = response.data['data'];

      return playlists.map((playlist) {
        final id = playlist['id'].toString();
        final title = playlist['title'] ?? '';
        final description = playlist['description'] ?? '';
        final coverUrl = playlist['picture_medium'] ?? '';
        final DateTime now = DateTime.now();

        return Playlist(
          id: id,
          name: title,
          description: description,
          coverUrl: coverUrl,
          songIds: [],
          createdAt: now,
          updatedAt: now,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting user\'s playlists: $e');
      return [];
    }
  }

  // Add track to user's favorites (requires auth)
  Future<bool> addTrackToFavorites(String trackId) async {
    if (!canAccessUserFeatures) {
      debugPrint('Authentication required for adding favorites');
      return false;
    }

    try {
      final response = await _dio.post(
        '/user/me/tracks',
        queryParameters: {'track_id': trackId},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error adding track to favorites: $e');
      return false;
    }
  }

  // Remove track from user's favorites (requires auth)
  Future<bool> removeTrackFromFavorites(String trackId) async {
    if (!canAccessUserFeatures) {
      debugPrint('Authentication required for removing favorites');
      return false;
    }

    try {
      final response = await _dio.delete(
        '/user/me/tracks',
        queryParameters: {'track_id': trackId},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error removing track from favorites: $e');
      return false;
    }
  }
}
