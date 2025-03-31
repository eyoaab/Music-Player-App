import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../widgets/song_list_item.dart';
import '../screens/playlist_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load data when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final libraryProvider =
          Provider.of<LibraryProvider>(context, listen: false);
      libraryProvider.loadDownloadedSongs();
      libraryProvider.loadFavorites();
      libraryProvider.loadPlaylists();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black87,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.black54,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.download_done),
              text: 'Downloads',
            ),
            Tab(
              icon: Icon(Icons.favorite),
              text: 'Favorites',
            ),
            Tab(
              icon: Icon(Icons.playlist_play),
              text: 'Playlists',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DownloadsTab(),
          _FavoritesTab(),
          _PlaylistsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton(
              onPressed: () => _showCreatePlaylistDialog(context),
              backgroundColor: primaryColor,
              foregroundColor: Colors.black87,
              tooltip: 'Create new playlist',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              autofocus: true,
            ),
            TextField(
              controller: descriptionController,
              decoration:
                  const InputDecoration(labelText: 'Description (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final name = nameController.text.trim();
      final description = descriptionController.text.trim();

      if (name.isNotEmpty) {
        final libraryProvider =
            Provider.of<LibraryProvider>(context, listen: false);

        await libraryProvider.createPlaylist(
            name, description.isEmpty ? null : description);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Playlist "$name" created'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }
}

class _DownloadsTab extends StatelessWidget {
  const _DownloadsTab();

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    return RefreshIndicator(
      onRefresh: () => libraryProvider.loadDownloadedSongs(),
      child: libraryProvider.isLoadingDownloaded
          ? const Center(child: CircularProgressIndicator())
          : libraryProvider.downloadedSongs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.download,
                        size: 80,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No downloaded songs',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your downloaded songs will appear here',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Storage usage info
                    FutureBuilder<int>(
                      future: libraryProvider.calculateStorageUsage(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox.shrink();
                        }
                        final storageBytes = snapshot.data!;
                        final storageMB =
                            (storageBytes / (1024 * 1024)).toStringAsFixed(1);

                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Icon(Icons.storage, size: 20),
                              const SizedBox(width: 8),
                              Text('Storage usage: $storageMB MB'),
                            ],
                          ),
                        );
                      },
                    ),

                    Expanded(
                      child: ListView.builder(
                        itemCount: libraryProvider.downloadedSongs.length,
                        itemBuilder: (context, index) {
                          final song = libraryProvider.downloadedSongs[index];
                          return SongListItem(
                            song: song,
                            onTap: () {
                              playerProvider.playSong(song);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    return RefreshIndicator(
      onRefresh: () => libraryProvider.loadFavorites(),
      child: libraryProvider.isLoadingFavorites
          ? const Center(child: CircularProgressIndicator())
          : libraryProvider.favoriteSongs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 80,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No favorite songs',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your favorite songs will appear here',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: libraryProvider.favoriteSongs.length,
                  itemBuilder: (context, index) {
                    final song = libraryProvider.favoriteSongs[index];
                    return SongListItem(
                      song: song,
                      onTap: () {
                        playerProvider.playSong(song);
                      },
                    );
                  },
                ),
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);

    return RefreshIndicator(
      onRefresh: () => _refreshPlaylists(context),
      child: libraryProvider.isLoadingPlaylists
          ? const Center(child: CircularProgressIndicator())
          : libraryProvider.playlists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.queue_music,
                        size: 80,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No playlists',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a playlist using the + button',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showCreatePlaylistDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Playlist'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: libraryProvider.playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = libraryProvider.playlists[index];
                    return _buildPlaylistTile(
                        context, playlist, libraryProvider);
                  },
                ),
    );
  }

  Widget _buildPlaylistTile(
    BuildContext context,
    Playlist playlist,
    LibraryProvider libraryProvider,
  ) {
    final songs = _getSongsForPlaylist(playlist, libraryProvider);
    log('Playlist "${playlist.name}" has ${songs.length} songs');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
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
                        color: Theme.of(context).primaryColor,
                      );
                    },
                  ),
                )
              : Icon(
                  Icons.queue_music,
                  size: 30,
                  color: Theme.of(context).primaryColor,
                ),
        ),
        title: Text(
          playlist.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text('${songs.length} songs'),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () =>
              _showPlaylistOptions(context, playlist, libraryProvider),
        ),
        onTap: () {
          _navigateToPlaylistDetail(context, playlist, songs);
        },
      ),
    );
  }

  List<Song> _getSongsForPlaylist(Playlist playlist, LibraryProvider provider) {
    if (playlist.songs.isNotEmpty) {
      // If songs are already loaded with the playlist, return them
      return playlist.songs;
    } else if (playlist.songIds.isNotEmpty) {
      // If we have songIds but no songs, try to get them from various sources
      final songs = <Song>[];
      for (final songId in playlist.songIds) {
        // Try to find in favorites first
        Song? song = provider.favoriteSongs.firstWhere(
          (s) => s.id == songId,
          orElse: () => Song.empty(),
        );

        // If not in favorites, try downloaded songs
        if (song.id.isEmpty) {
          song = provider.downloadedSongs.firstWhere(
            (s) => s.id == songId,
            orElse: () => Song.empty(),
          );
        }

        // If we found the song, add it
        if (song.id.isNotEmpty) {
          songs.add(song);
        }
      }

      // If we collected any songs, return them
      if (songs.isNotEmpty) {
        return songs;
      }
    }

    // If no songs were found, return an empty list
    return [];
  }

  void _navigateToPlaylistDetail(
    BuildContext context,
    Playlist playlist,
    List<Song> songs,
  ) {
    // Navigate to playlist detail page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistDetailScreen(
          playlist: playlist,
        ),
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
    final TextEditingController nameController =
        TextEditingController(text: playlist.name);
    final TextEditingController descriptionController =
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
                decoration: const InputDecoration(
                  labelText: 'Playlist Name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
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
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Playlist updated'),
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
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                libraryProvider.deletePlaylist(playlist.id);
                Navigator.pop(context);
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

  Future<void> _refreshPlaylists(BuildContext context) async {
    final libraryProvider =
        Provider.of<LibraryProvider>(context, listen: false);

    // Show a snackbar to indicate refresh is happening
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing playlists...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Reload playlists
    await libraryProvider.loadPlaylists();

    // Show success message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found ${libraryProvider.playlists.length} playlists'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              autofocus: true,
            ),
            TextField(
              controller: descriptionController,
              decoration:
                  const InputDecoration(labelText: 'Description (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final name = nameController.text.trim();
      final description = descriptionController.text.trim();

      if (name.isNotEmpty) {
        final libraryProvider =
            Provider.of<LibraryProvider>(context, listen: false);

        await libraryProvider.createPlaylist(
            name, description.isEmpty ? null : description);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Playlist "$name" created'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }
}
