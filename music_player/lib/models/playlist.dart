import '../models/song.dart';

class Playlist {
  final String id;
  final String name;
  final String? description;
  final String? coverUrl;
  final List<String> songIds;
  final List<Song> songs;
  final DateTime createdAt;
  final DateTime updatedAt;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    required this.songIds,
    this.songs = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Playlist.create({
    required String id,
    required String name,
    String? description,
    String? coverUrl,
  }) {
    final now = DateTime.now();
    return Playlist(
      id: id,
      name: name,
      description: description,
      coverUrl: coverUrl,
      songIds: [],
      songs: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    // Extract basic playlist data
    final id = json['id'] as String;
    final name = json['name'] as String;
    final description = json['description'] as String?;
    final coverUrl = json['coverUrl'] as String?;
    final songIds =
        (json['songIds'] as List<dynamic>).map((e) => e as String).toList();
    final createdAt = DateTime.parse(json['createdAt'] as String);
    final updatedAt = DateTime.parse(json['updatedAt'] as String);

    // For songs array, try to parse if it exists (but most likely will be loaded separately)
    List<Song> songs = [];
    if (json.containsKey('songs') && json['songs'] is List) {
      try {
        songs = (json['songs'] as List)
            .map((songJson) {
              if (songJson is Map<String, dynamic>) {
                // Convert duration from int (seconds) back to Duration object
                final durationSeconds = songJson['duration'] as int? ?? 0;
                return Song(
                  id: songJson['id'] ?? '',
                  title: songJson['title'] ?? '',
                  artist: songJson['artist'] ?? '',
                  artistId: songJson['artistId'] ?? '',
                  album: songJson['album'] ?? '',
                  albumId: songJson['albumId'] ?? '',
                  coverUrl: songJson['coverUrl'] ?? '',
                  audioUrl: songJson['audioUrl'] ?? '',
                  duration: Duration(seconds: durationSeconds),
                  isDownloaded: songJson['isDownloaded'] ?? false,
                  localPath: songJson['localPath'],
                  genre: songJson['genre'],
                  popularity: songJson['popularity'],
                  isPlayable: songJson['isPlayable'] ?? true,
                  uri: songJson['uri'] ?? '',
                );
              }
              return Song.empty();
            })
            .where((song) => song.id.isNotEmpty)
            .toList();
      } catch (e) {
        print('Error parsing songs in playlist JSON: $e');
      }
    }

    return Playlist(
      id: id,
      name: name,
      description: description,
      coverUrl: coverUrl,
      songIds: songIds,
      songs: songs,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    // Include songs in the JSON to improve restoration from storage
    final Map<String, dynamic> json = {
      'id': id,
      'name': name,
      'description': description,
      'coverUrl': coverUrl,
      'songIds': songIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };

    // Only include songs if there are any to avoid empty array
    if (songs.isNotEmpty) {
      json['songs'] = songs.map((song) => song.toJson()).toList();
    }

    return json;
  }

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    String? coverUrl,
    List<String>? songIds,
    List<Song>? songs,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      songIds: songIds ?? this.songIds,
      songs: songs ?? this.songs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Playlist addSong(String songId, [Song? song]) {
    if (songIds.contains(songId)) {
      return this;
    }

    final updatedSongIds = List<String>.from(songIds)..add(songId);
    final updatedSongs =
        song != null ? (List<Song>.from(songs)..add(song)) : songs;

    return copyWith(
      songIds: updatedSongIds,
      songs: updatedSongs,
      updatedAt: DateTime.now(),
    );
  }

  Playlist removeSong(String songId) {
    if (!songIds.contains(songId)) {
      return this;
    }

    final updatedSongIds = List<String>.from(songIds)..remove(songId);
    final updatedSongs = List<Song>.from(songs)
      ..removeWhere((song) => song.id == songId);

    return copyWith(
      songIds: updatedSongIds,
      songs: updatedSongs,
      updatedAt: DateTime.now(),
    );
  }
}
