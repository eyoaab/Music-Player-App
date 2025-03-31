class Song {
  final String id;
  final String title;
  final String artist;
  final String artistId;
  final String album;
  final String albumId;
  final String coverUrl;
  final String audioUrl;
  final Duration duration;
  final bool isDownloaded;
  final String? localPath;
  final String? genre;
  final int? popularity; // Corresponds to Deezer's rank
  final bool isPlayable;
  final String uri; // Deezer URI for playback

  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.artistId = '',
    required this.album,
    this.albumId = '',
    required this.coverUrl,
    required this.audioUrl,
    required this.duration,
    this.isDownloaded = false,
    this.localPath,
    this.genre,
    this.popularity,
    this.isPlayable = true,
    required this.uri,
  });

  factory Song.empty() {
    return Song(
      id: '',
      title: '',
      artist: '',
      artistId: '',
      album: '',
      albumId: '',
      coverUrl: '',
      audioUrl: '',
      duration: Duration.zero,
      uri: '',
    );
  }

  factory Song.fromDeezerJson(Map<String, dynamic> json) {
    // Extract album details
    final album = json['album'] ?? {};
    final coverUrl = json['album']?['cover_big'] ??
        json['album']?['cover_medium'] ??
        json['album']?['cover_small'] ??
        'https://via.placeholder.com/300';

    // Extract artist details
    final artistName = json['artist']?['name'] ?? 'Unknown Artist';
    final artistId = json['artist']?['id']?.toString() ?? '';

    // Deezer always provides a preview URL (30 seconds)
    final previewUrl = json['preview'] as String? ?? '';

    return Song(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Unknown Title',
      artist: artistName,
      artistId: artistId,
      album: album['title'] as String? ?? 'Unknown Album',
      albumId: album['id']?.toString() ?? '',
      coverUrl: coverUrl,
      audioUrl: previewUrl,
      duration: Duration(seconds: json['duration'] as int? ?? 0),
      popularity: json['rank'] as int?,
      isPlayable: json['readable'] as bool? ?? true,
      uri: 'deezer:track:${json['id']}', // Deezer URI format
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'artistId': artistId,
      'album': album,
      'albumId': albumId,
      'coverUrl': coverUrl,
      'audioUrl': audioUrl,
      'duration':
          duration.inSeconds, // Deezer uses seconds instead of milliseconds
      'isDownloaded': isDownloaded,
      'localPath': localPath,
      'genre': genre,
      'popularity': popularity,
      'isPlayable': isPlayable,
      'uri': uri,
    };
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? artistId,
    String? album,
    String? albumId,
    String? coverUrl,
    String? audioUrl,
    Duration? duration,
    bool? isDownloaded,
    String? localPath,
    String? genre,
    int? popularity,
    bool? isPlayable,
    String? uri,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      artistId: artistId ?? this.artistId,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      coverUrl: coverUrl ?? this.coverUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      localPath: localPath ?? this.localPath,
      genre: genre ?? this.genre,
      popularity: popularity ?? this.popularity,
      isPlayable: isPlayable ?? this.isPlayable,
      uri: uri ?? this.uri,
    );
  }
}
