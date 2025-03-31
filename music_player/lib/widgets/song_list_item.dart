import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';

class SongListItem extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final VoidCallback? onOptionsPressed;
  final bool showDownloadStatus;

  const SongListItem({
    super.key,
    required this.song,
    required this.onTap,
    this.onOptionsPressed,
    this.showDownloadStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final isFavorite =
        libraryProvider.favoriteSongs.any((s) => s.id == song.id);

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          song.coverUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 50,
              height: 50,
              color: Colors.grey[300],
              child: const Icon(Icons.music_note, color: Colors.grey),
            );
          },
        ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showDownloadStatus && song.isDownloaded)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(
                Icons.download_done,
                size: 16,
                color: Colors.green,
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
            ),
            onPressed: () {
              libraryProvider.toggleFavorite(song);
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: onOptionsPressed ?? () => _showSongOptions(context),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  void _showSongOptions(BuildContext context) {
    final libraryProvider =
        Provider.of<LibraryProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('Play Now'),
                onTap: () {
                  Navigator.pop(context);
                  onTap();
                },
              ),
              ListTile(
                leading: Icon(
                  song.isDownloaded ? Icons.delete : Icons.download,
                ),
                title: Text(
                  song.isDownloaded ? 'Remove Download' : 'Download',
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (song.isDownloaded) {
                    libraryProvider.deleteSongDownload(song.id);
                  } else {
                    libraryProvider.downloadSong(song);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading "${song.title}"'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Add to Playlist'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddToPlaylistDialog(context, song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite),
                title: Text(
                  libraryProvider.favoriteSongs.any((s) => s.id == song.id)
                      ? 'Remove from Favorites'
                      : 'Add to Favorites',
                ),
                onTap: () {
                  libraryProvider.toggleFavorite(song);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, Song song) {
    Navigator.pushNamed(
      context,
      '/playlist/add',
      arguments: song,
    );
  }
}
