import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class DownloadService {
  final Dio _dio = Dio();

  // Key for song metadata in SharedPreferences
  static const String _downloadedSongsMetadataKey = 'downloaded_songs_metadata';

  Future<bool> checkStoragePermission() async {
    // Skip permission check on web
    if (kIsWeb) return true;

    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        final result = await Permission.storage.request();
        return result == PermissionStatus.granted;
      }
      return true;
    }
    // For other platforms, assume permission is granted
    return true;
  }

  Future<String> get _localPath async {
    if (kIsWeb) {
      // Return a placeholder path for web
      return '/web_storage';
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/songs';
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }

  Future<Song> downloadSong(Song song) async {
    try {
      // For web, we can't download files to local storage in the same way
      if (kIsWeb) {
        // For web, we'll just mark the song as "downloaded" without actual file storage
        final downloadedSong = song.copyWith(
            isDownloaded: true, localPath: '/web_storage/${song.id}.mp3');

        // Save metadata even for web to demonstrate functionality
        await _saveSongMetadata(downloadedSong);
        return downloadedSong;
      }

      final hasPermission = await checkStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      final savePath = await _localPath;
      final fileName = '${song.id}.mp3';
      final filePath = '$savePath/$fileName';

      final file = File(filePath);
      if (await file.exists()) {
        // Song already downloaded
        final downloadedSong =
            song.copyWith(isDownloaded: true, localPath: filePath);
        await _saveSongMetadata(downloadedSong);
        return downloadedSong;
      }

      await _dio.download(
        song.audioUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // Calculate and report download progress if needed
            final progress = (received / total * 100).toStringAsFixed(0);
            print('Download progress: $progress%');
          }
        },
      );

      // Verify the file was downloaded successfully
      if (await file.exists()) {
        final downloadedSong =
            song.copyWith(isDownloaded: true, localPath: filePath);
        // Save metadata to SharedPreferences
        await _saveSongMetadata(downloadedSong);
        return downloadedSong;
      } else {
        throw Exception('Failed to download file');
      }
    } catch (e) {
      print('Error downloading song: $e');
      throw Exception('Failed to download song: $e');
    }
  }

  // Save song metadata to SharedPreferences
  Future<void> _saveSongMetadata(Song song) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current metadata
      final jsonString = prefs.getString(_downloadedSongsMetadataKey) ?? '{}';
      final Map<String, dynamic> metadata = json.decode(jsonString);

      // Add or update this song's metadata
      metadata[song.id] = song.toJson();

      // Save back to SharedPreferences
      await prefs.setString(_downloadedSongsMetadataKey, json.encode(metadata));

      print('Saved metadata for song: ${song.title}');
    } catch (e) {
      print('Error saving song metadata: $e');
    }
  }

  // Remove song metadata from SharedPreferences
  Future<void> _removeSongMetadata(String songId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current metadata
      final jsonString = prefs.getString(_downloadedSongsMetadataKey) ?? '{}';
      final Map<String, dynamic> metadata = json.decode(jsonString);

      // Remove this song's metadata
      metadata.remove(songId);

      // Save back to SharedPreferences
      await prefs.setString(_downloadedSongsMetadataKey, json.encode(metadata));

      print('Removed metadata for song ID: $songId');
    } catch (e) {
      print('Error removing song metadata: $e');
    }
  }

  Future<bool> deleteSongFile(Song song) async {
    try {
      if (kIsWeb) {
        // For web, we just mark it as not downloaded
        await _removeSongMetadata(song.id);
        return true;
      }

      if (song.localPath == null) {
        return false;
      }

      final file = File(song.localPath!);
      if (await file.exists()) {
        await file.delete();
        // Remove metadata from SharedPreferences
        await _removeSongMetadata(song.id);
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting song: $e');
      return false;
    }
  }

  // Alias for backward compatibility
  Future<bool> deleteSong(Song song) => deleteSongFile(song);

  Future<List<Song>> getDownloadedSongs() async {
    if (kIsWeb) {
      // For web, we'll still use metadata if available
      final metadata = await _getSongMetadataMap();
      if (metadata.isNotEmpty) {
        return metadata.values.toList();
      }
      // Fall back to mock data if no metadata
      return _getMockDownloadedSongs();
    }

    final savePath = await _localPath;
    final dir = Directory(savePath);

    if (!await dir.exists()) {
      return [];
    }

    // Get all MP3 files in the directory
    final files = await dir.list().toList();
    final mp3Files = files
        .whereType<File>()
        .where((file) => file.path.endsWith('.mp3'))
        .toList();

    // Get metadata map
    final metadataMap = await _getSongMetadataMap();

    final List<Song> downloadedSongs = [];

    for (var file in mp3Files) {
      final fileName = file.path.split('/').last;
      final songId = fileName.replaceAll('.mp3', '');

      if (metadataMap.containsKey(songId)) {
        // We have metadata for this song
        final song = metadataMap[songId]!.copyWith(
          isDownloaded: true,
          localPath: file.path,
          uri: 'file://${file.path}',
        );
        downloadedSongs.add(song);
      } else {
        // No metadata, create basic song object
        downloadedSongs.add(Song(
          id: songId,
          title: 'Downloaded Song $songId',
          artist: 'Unknown Artist',
          album: 'Unknown Album',
          coverUrl: 'https://via.placeholder.com/300',
          audioUrl: '',
          duration: const Duration(minutes: 3),
          isDownloaded: true,
          localPath: file.path,
          uri: 'file://${file.path}',
        ));
      }
    }

    // Verify that all songs in metadata actually have files
    // If not, they may have been deleted outside the app
    if (downloadedSongs.length != metadataMap.length) {
      // Clean up metadata for songs that don't have files
      await _cleanupOrphanedMetadata(mp3Files
          .map((f) => f.path.split('/').last.replaceAll('.mp3', ''))
          .toSet());
    }

    return downloadedSongs;
  }

  // Get metadata for all downloaded songs
  Future<Map<String, Song>> _getSongMetadataMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_downloadedSongsMetadataKey) ?? '{}';
      final Map<String, dynamic> metadata = json.decode(jsonString);

      // Convert from raw JSON to Song objects
      final Map<String, Song> songMap = {};

      metadata.forEach((id, songJson) {
        final Map<String, dynamic> songData = songJson;
        final durationSeconds = songData['duration'] as int? ?? 0;

        final song = Song(
          id: songData['id'] ?? '',
          title: songData['title'] ?? '',
          artist: songData['artist'] ?? '',
          artistId: songData['artistId'] ?? '',
          album: songData['album'] ?? '',
          albumId: songData['albumId'] ?? '',
          coverUrl: songData['coverUrl'] ?? '',
          audioUrl: songData['audioUrl'] ?? '',
          duration: Duration(seconds: durationSeconds),
          isDownloaded: songData['isDownloaded'] ?? false,
          localPath: songData['localPath'],
          genre: songData['genre'],
          popularity: songData['popularity'],
          isPlayable: songData['isPlayable'] ?? true,
          uri: songData['uri'] ?? '',
        );

        songMap[id] = song;
      });

      return songMap;
    } catch (e) {
      print('Error getting song metadata: $e');
      return {};
    }
  }

  // Remove metadata for songs that don't have files anymore
  Future<void> _cleanupOrphanedMetadata(Set<String> existingSongIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_downloadedSongsMetadataKey) ?? '{}';
      final Map<String, dynamic> metadata = json.decode(jsonString);

      // Get the list of IDs to remove
      final idsToRemove =
          metadata.keys.where((id) => !existingSongIds.contains(id)).toList();

      // If there are orphaned metadata entries, remove them
      if (idsToRemove.isNotEmpty) {
        for (final id in idsToRemove) {
          metadata.remove(id);
        }

        // Save the updated metadata
        await prefs.setString(
            _downloadedSongsMetadataKey, json.encode(metadata));
        print('Removed ${idsToRemove.length} orphaned metadata entries');
      }
    } catch (e) {
      print('Error cleaning up orphaned metadata: $e');
    }
  }

  List<Song> _getMockDownloadedSongs() {
    // Create some mock downloaded songs for web demo
    return List.generate(5, (index) {
      final id = '${1000 + index}';
      return Song(
        id: id,
        title: 'Downloaded Song $index',
        artist: 'Demo Artist',
        album: 'Demo Album',
        coverUrl: 'https://via.placeholder.com/300',
        audioUrl: 'https://example.com/sample$index.mp3',
        duration: Duration(minutes: 3, seconds: index * 10),
        isDownloaded: true,
        localPath: '/web_storage/$id.mp3',
        uri: 'file:///web_storage/$id.mp3',
      );
    });
  }

  Future<int> getTotalStorageUsage() async {
    try {
      if (kIsWeb) {
        // For web, return a mock size (5MB per downloaded song)
        return _getMockDownloadedSongs().length * 5 * 1024 * 1024;
      }

      final savePath = await _localPath;
      final dir = Directory(savePath);

      if (!await dir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final FileSystemEntity entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      print('Error calculating storage usage: $e');
      return 0;
    }
  }
}
