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
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      coverUrl: json['coverUrl'] as String?,
      songIds:
          (json['songIds'] as List<dynamic>).map((e) => e as String).toList(),
      songs: [], // Songs will be populated separately
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coverUrl': coverUrl,
      'songIds': songIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
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
