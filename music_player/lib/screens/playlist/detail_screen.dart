import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../providers/player_provider.dart';
import '../../providers/library_provider.dart';
import '../../widgets/song_list_item.dart';
import 'detail_components.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  late Playlist _currentPlaylist;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentPlaylist = widget.playlist;
    _loadPlaylistData();
  }

  Future<void> _loadPlaylistData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get fresh playlist data from library provider
      final libraryProvider =
          Provider.of<LibraryProvider>(context, listen: false);
      final updatedPlaylist = libraryProvider.playlists.firstWhere(
        (p) => p.id == widget.playlist.id,
        orElse: () => widget.playlist,
      );

      // If playlist songs are empty but songIds exist, try to refresh the playlist
      if (updatedPlaylist.songs.isEmpty && updatedPlaylist.songIds.isNotEmpty) {
        log('Playlist songs are empty, trying to refresh');
        await libraryProvider.loadPlaylists();

        // Check for updated playlist again
        final refreshedPlaylist = libraryProvider.playlists.firstWhere(
          (p) => p.id == widget.playlist.id,
          orElse: () => updatedPlaylist,
        );

        setState(() {
          _currentPlaylist = refreshedPlaylist;
          _isLoading = false;
        });
      } else {
        setState(() {
          _currentPlaylist = updatedPlaylist;
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Error loading playlist data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final playerProvider = Provider.of<PlayerProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPlaylist.name),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh playlist',
            onPressed: _loadPlaylistData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header with playlist info
                PlaylistHeader(playlist: _currentPlaylist),

                // Play button
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _currentPlaylist.songs.isEmpty
                            ? null
                            : () {
                                log('Playing playlist: ${_currentPlaylist.name} with ${_currentPlaylist.songs.length} songs');
                                playerProvider.playPlaylist(_currentPlaylist);
                              },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play All'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () {
                          _showPlaylistOptions(
                              context, _currentPlaylist, libraryProvider);
                        },
                        icon: const Icon(Icons.more_vert),
                        tooltip: 'More options',
                      ),
                    ],
                  ),
                ),

                // Song list
                Expanded(
                  child: _currentPlaylist.songs.isEmpty
                      ? const EmptyPlaylistView()
                      : RefreshIndicator(
                          onRefresh: _loadPlaylistData,
                          child: ListView.builder(
                            itemCount: _currentPlaylist.songs.length,
                            itemBuilder: (context, index) {
                              final song = _currentPlaylist.songs[index];
                              final isPlaying =
                                  playerProvider.currentSong?.id == song.id &&
                                      playerProvider.isPlaying;

                              return ListTile(
                                leading: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(
                                        song.coverUrl,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            width: 50,
                                            height: 50,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.music_note,
                                                color: Colors.grey),
                                          );
                                        },
                                      ),
                                    ),
                                    if (isPlaying)
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Icon(
                                          Icons.play_arrow,
                                          color: primaryColor,
                                        ),
                                      ),
                                  ],
                                ),
                                title: Text(
                                  song.title,
                                  style: TextStyle(
                                    fontWeight: isPlaying
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isPlaying ? primaryColor : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  song.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    // Remove song from playlist
                                    _showRemoveSongDialog(
                                        context,
                                        _currentPlaylist,
                                        song,
                                        libraryProvider);
                                  },
                                ),
                                onTap: () {
                                  // Start playing from this song in the playlist
                                  log('Playing song from playlist: ${song.title}');
                                  playerProvider.playPlaylist(_currentPlaylist,
                                      initialIndex: index);
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  void _showRemoveSongDialog(BuildContext context, Playlist playlist, Song song,
      LibraryProvider libraryProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Song'),
        content: Text('Remove "${song.title}" from this playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              libraryProvider.removeSongFromPlaylist(playlist.id, song.id);
              Navigator.pop(context);

              // Update local state after removing song
              setState(() {
                _currentPlaylist = libraryProvider.playlists.firstWhere(
                  (p) => p.id == playlist.id,
                  orElse: () => _currentPlaylist.removeSong(song.id),
                );
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed "${song.title}" from playlist'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showPlaylistOptions(
    BuildContext context,
    Playlist playlist,
    LibraryProvider libraryProvider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Playlist'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditPlaylistDialog(context, playlist, libraryProvider);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Playlist'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeletePlaylistDialog(context, playlist, libraryProvider);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditPlaylistDialog(
    BuildContext context,
    Playlist playlist,
    LibraryProvider libraryProvider,
  ) {
    final nameController = TextEditingController(text: playlist.name);
    final descriptionController =
        TextEditingController(text: playlist.description ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Playlist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Playlist Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration:
                    const InputDecoration(labelText: 'Description (Optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  final updatedPlaylist = playlist.copyWith(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    updatedAt: DateTime.now(),
                  );

                  libraryProvider.updatePlaylist(updatedPlaylist);

                  // Update local state
                  setState(() {
                    _currentPlaylist = updatedPlaylist;
                  });

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Playlist updated'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeletePlaylistDialog(
    BuildContext context,
    Playlist playlist,
    LibraryProvider libraryProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Playlist'),
          content: Text(
              'Are you sure you want to delete the playlist "${playlist.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                libraryProvider.deletePlaylist(playlist.id);
                Navigator.pop(context);
                Navigator.pop(context); // Go back to library

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Playlist "${playlist.name}" deleted'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
