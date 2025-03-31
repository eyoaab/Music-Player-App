import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song.dart';

class DownloadService {
  final Dio _dio = Dio();

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
        return song.copyWith(
            isDownloaded: true, localPath: '/web_storage/${song.id}.mp3');
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
        return song.copyWith(isDownloaded: true, localPath: filePath);
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
        return song.copyWith(isDownloaded: true, localPath: filePath);
      } else {
        throw Exception('Failed to download file');
      }
    } catch (e) {
      print('Error downloading song: $e');
      throw Exception('Failed to download song: $e');
    }
  }

  Future<bool> deleteSongFile(Song song) async {
    try {
      if (kIsWeb) {
        // For web, we just mark it as not downloaded
        return true;
      }

      if (song.localPath == null) {
        return false;
      }

      final file = File(song.localPath!);
      if (await file.exists()) {
        await file.delete();
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
      // For web, we'll return some mock songs for demo purposes
      return _getMockDownloadedSongs();
    }

    final savePath = await _localPath;
    final dir = Directory(savePath);

    if (!await dir.exists()) {
      return [];
    }

    final files = await dir.list().toList();
    final List<Song> downloadedSongs = [];

    for (var file in files.whereType<File>()) {
      if (file.path.endsWith('.mp3')) {
        final fileName = file.path.split('/').last;
        final songId = fileName.replaceAll('.mp3', '');

        // Create a basic song object with the ID and local path
        // The app should obtain full song details from another source
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

    return downloadedSongs;
  }

  // For backward compatibility
  Future<List<Song>> getDownloadedSongs_old(List<Song> allSongs) async {
    if (kIsWeb) {
      // For web, we'll return some mock songs for demo purposes
      return _getMockDownloadedSongs();
    }

    final savePath = await _localPath;
    final dir = Directory(savePath);

    if (!await dir.exists()) {
      return [];
    }

    final files = await dir.list().toList();
    final downloadedSongIds = files
        .whereType<File>()
        .where((file) => file.path.endsWith('.mp3'))
        .map((file) {
      final fileName = file.path.split('/').last;
      return fileName.replaceAll('.mp3', '');
    }).toSet();

    return allSongs
        .where((song) => downloadedSongIds.contains(song.id))
        .map((song) {
      final localPath = '$savePath/${song.id}.mp3';
      return song.copyWith(isDownloaded: true, localPath: localPath);
    }).toList();
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
