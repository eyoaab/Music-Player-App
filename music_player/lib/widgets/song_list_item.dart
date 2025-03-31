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
    final libraryProvider =
        Provider.of<LibraryProvider>(context, listen: false);
    final playlists = libraryProvider.playlists;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Add "${song.title}" to Playlist',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount:
                        playlists.length + 1, // +1 for "Create New" option
                    itemBuilder: (context, index) {
                      if (index == playlists.length) {
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.add),
                          ),
                          title: const Text('Create New Playlist'),
                          onTap: () {
                            Navigator.pop(context);
                            _showCreatePlaylistDialog(context, song);
                          },
                        );
                      } else {
                        final playlist = playlists[index];
                        final isInPlaylist = playlist.songIds.contains(song.id);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: playlist.coverUrl != null
                                ? NetworkImage(playlist.coverUrl!)
                                : null,
                            child: playlist.coverUrl == null
                                ? const Icon(Icons.playlist_play)
                                : null,
                          ),
                          title: Text(playlist.name),
                          subtitle: Text('${playlist.songIds.length} songs'),
                          trailing: isInPlaylist
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () {
                            if (!isInPlaylist) {
                              libraryProvider.addSongToPlaylist(
                                  playlist.id, song);
                            } else {
                              libraryProvider.removeSongFromPlaylist(
                                  playlist.id, song.id);
                            }
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isInPlaylist
                                      ? 'Removed from ${playlist.name}'
                                      : 'Added to ${playlist.name}',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, Song song) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Playlist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'My Playlist',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'A description for my playlist',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final description = descriptionController.text.trim();

                if (name.isEmpty) return;

                final libraryProvider =
                    Provider.of<LibraryProvider>(context, listen: false);

                // Create the playlist
                final result = await libraryProvider.createPlaylist(
                  name,
                  description.isEmpty ? null : description,
                );

                // Get the playlist we just created
                if (libraryProvider.playlists.isNotEmpty) {
                  final playlist = libraryProvider.playlists.last;
                  // Add the song to the playlist
                  await libraryProvider.addSongToPlaylist(playlist.id, song);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added to new playlist "$name"'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
