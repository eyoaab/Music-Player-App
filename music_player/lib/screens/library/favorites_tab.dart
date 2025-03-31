import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/song_list_item.dart';
import '../../models/song.dart';

class FavoritesTab extends StatelessWidget {
  final Function(Song, BuildContext) onSongTapped;

  const FavoritesTab({
    super.key,
    required this.onSongTapped,
  });

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    return RefreshIndicator(
      onRefresh: () => libraryProvider.loadFavorites(),
      child: libraryProvider.isLoadingFavorites
          ? const Center(child: CircularProgressIndicator())
          : libraryProvider.favoriteSongs.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  itemCount: libraryProvider.favoriteSongs.length,
                  itemBuilder: (context, index) {
                    final song = libraryProvider.favoriteSongs[index];
                    return SongListItem(
                      song: song,
                      onTap: () => onSongTapped(song, context),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite,
            size: 80,
            color: Colors.red.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No favorite songs',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add songs to your favorites',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
