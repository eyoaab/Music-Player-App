class Artist {
  final String id;
  final String name;
  final String imageUrl;
  final int followers;
  final String? url;

  Artist({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.followers = 0,
    this.url,
  });

  factory Artist.fromDeezerJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      imageUrl: json['picture_medium'] ?? json['picture'] ?? '',
      followers: json['nb_fan'] ?? 0,
      url: json['link'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'followers': followers,
      'url': url,
    };
  }
}
