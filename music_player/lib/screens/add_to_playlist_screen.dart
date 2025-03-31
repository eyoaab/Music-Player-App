import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../models/playlist.dart';

class AddToPlaylistScreen extends StatefulWidget {
  final Song song;

  const AddToPlaylistScreen({
    super.key,
    required this.song,
  });

  @override
  State<AddToPlaylistScreen> createState() => _AddToPlaylistScreenState();
}

class _AddToPlaylistScreenState extends State<AddToPlaylistScreen> {
  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final playlists = libraryProvider.playlists;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add to Playlist'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Song info card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.song.coverUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.music_note, color: Colors.grey),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.song.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.song.artist,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Create new playlist button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: primaryColor,
                child: const Icon(Icons.add, color: Colors.white),
              ),
              title: const Text('Create New Playlist'),
              onTap: () {
                _showCreatePlaylistDialog(
                    context, widget.song, libraryProvider);
              },
            ),
          ),

          const Divider(),

          // Existing playlists
          Expanded(
            child: playlists.isEmpty
                ? Center(
                    child: Text(
                      'No playlists yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      final isInPlaylist =
                          playlist.songIds.contains(widget.song.id);

                      return ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: playlist.coverUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    playlist.coverUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.queue_music,
                                        size: 30,
                                        color: primaryColor,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.queue_music,
                                  size: 30,
                                  color: primaryColor,
                                ),
                        ),
                        title: Text(playlist.name),
                        subtitle: Text('${playlist.songs.length} songs'),
                        trailing: isInPlaylist
                            ? Icon(Icons.check_circle, color: primaryColor)
                            : const Icon(Icons.add_circle_outline),
                        onTap: () {
                          if (isInPlaylist) {
                            // Remove from playlist
                            libraryProvider.removeSongFromPlaylist(
                                playlist.id, widget.song.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Removed from "${playlist.name}"'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } else {
                            // Add to playlist
                            libraryProvider.addSongToPlaylist(
                                playlist.id, widget.song);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added to "${playlist.name}"'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(
    BuildContext context,
    Song song,
    LibraryProvider libraryProvider,
  ) {
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
                autofocus: true,
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

                // Create the playlist
                final newPlaylist = await libraryProvider.createPlaylist(
                  name,
                  description.isEmpty ? null : description,
                );

                // Add the song to the playlist
                await libraryProvider.addSongToPlaylist(newPlaylist.id, song);

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
