import 'package:flutter/material.dart';
import 'models/song.dart';
import 'models/playlist.dart';
import 'screens/home/home_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/library/library_screen.dart';
import 'screens/playlist/detail_screen.dart';
import 'screens/playlist/add_to_playlist_screen.dart';
import 'screens/all_songs/all_songs_screen.dart';

class AppRoutes {
  // Route names
  static const String home = '/';
  static const String search = '/search';
  static const String library = '/library';
  static const String playlistDetail = '/playlist/detail';
  static const String addToPlaylist = '/playlist/add';
  static const String allSongs = '/songs/all';

  // Route generation
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());

      case library:
        return MaterialPageRoute(builder: (_) => const LibraryScreen());

      case playlistDetail:
        final playlist = settings.arguments as Playlist;
        return MaterialPageRoute(
          builder: (_) => PlaylistDetailScreen(playlist: playlist),
        );

      case addToPlaylist:
        final song = settings.arguments as Song;
        return MaterialPageRoute(
          builder: (_) => AddToPlaylistScreen(song: song),
        );

      case allSongs:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => AllSongsScreen(
            title: args['title'] as String,
            songs: args['songs'] as List<Song>,
            isTrending: args['isTrending'] as bool? ?? false,
            isRecentlyPlayed: args['isRecentlyPlayed'] as bool? ?? false,
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
