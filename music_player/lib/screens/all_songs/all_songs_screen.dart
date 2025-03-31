import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../models/song.dart';
import '../../widgets/song_list_item.dart';

class AllSongsScreen extends StatelessWidget {
  final String title;
  final List<Song> songs;
  final bool isTrending;
  final bool isRecentlyPlayed;

  const AllSongsScreen({
    super.key,
    required this.title,
    required this.songs,
    this.isTrending = false,
    this.isRecentlyPlayed = false,
  });

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (isTrending) {
            await libraryProvider.loadTrendingSongs();
          } else if (isRecentlyPlayed) {
            await libraryProvider.loadRecentlyPlayed();
          }
          // For other song types, we might add different refresh actions
        },
        color: primaryColor,
        child: songs.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 80,
                      color: Colors.grey.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No songs available',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return SongListItem(
                    song: song,
                    onTap: () {
                      final playerProvider =
                          Provider.of<PlayerProvider>(context, listen: false);
                      // Play the selected song
                      playerProvider.playSong(song);
                    },
                  );
                },
              ),
      ),
    );
  }
}
