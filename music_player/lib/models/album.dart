import 'song.dart';

class Album {
  final String id;
  final String title;
  final String artistId;
  final String artistName;
  final String coverUrl;
  final String releaseDate;
  final List<Song> tracks;
  final int? trackCount;
  final String? url;

  Album({
    required this.id,
    required this.title,
    required this.artistId,
    required this.artistName,
    required this.coverUrl,
    required this.releaseDate,
    required this.tracks,
    this.trackCount,
    this.url,
  });

  factory Album.fromDeezerJson(Map<String, dynamic> json) {
    List<Song> tracks = [];

    // Process tracks if they exist in the response
    if (json['tracks'] != null && json['tracks']['data'] != null) {
      final tracksData = json['tracks']['data'] as List;
      tracks = tracksData
          .map((trackJson) => Song.fromDeezerJson(trackJson))
          .toList();
    }

    return Album(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      artistId: json['artist']?['id']?.toString() ?? '',
      artistName: json['artist']?['name'] ?? '',
      coverUrl: json['cover_medium'] ?? json['cover'] ?? '',
      releaseDate: json['release_date'] ?? '',
      tracks: tracks,
      trackCount: json['nb_tracks'],
      url: json['link'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artistId': artistId,
      'artistName': artistName,
      'coverUrl': coverUrl,
      'releaseDate': releaseDate,
      'trackCount': trackCount,
      'url': url,
      'tracks': tracks.map((track) => track.toJson()).toList(),
    };
  }
}
