import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../widgets/song_list_item.dart';

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

        final result = await libraryProvider.createPlaylist(
            name, description.isEmpty ? null : description);

        if (context.mounted) {
          Navigator.pop(context);
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

class _DownloadsTab extends StatefulWidget {
  const _DownloadsTab();

  @override
  State<_DownloadsTab> createState() => _DownloadsTabState();
}

class _DownloadsTabState extends State<_DownloadsTab> {
  String _storageInfo = "0 MB";

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    final libraryProvider =
        Provider.of<LibraryProvider>(context, listen: false);
    final storageBytes = await libraryProvider.calculateStorageUsage();

    if (context.mounted) {
      setState(() {
        _storageInfo = _formatStorageSize(storageBytes);
      });
    }
  }

  String _formatStorageSize(int bytes) {
    String storageText;
    if (bytes < 1024) {
      storageText = "$bytes B";
    } else if (bytes < 1024 * 1024) {
      storageText = "${(bytes / 1024).toStringAsFixed(1)} KB";
    } else if (bytes < 1024 * 1024 * 1024) {
      storageText = "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
    } else {
      storageText = "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
    }
    return storageText;
  }

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        await libraryProvider.loadDownloadedSongs();
        await _loadStorageInfo();
      },
      child: Column(
        children: [
          // Storage info card
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.storage,
                      size: 32,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Storage Usage',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _storageInfo,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadStorageInfo,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ),

          // Downloaded songs list
          Expanded(
            child: libraryProvider.isLoadingDownloaded
                ? const Center(child: CircularProgressIndicator())
                : libraryProvider.downloadedSongs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.download_done,
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
                              'Download songs for offline playback',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: libraryProvider.downloadedSongs.length,
                        itemBuilder: (context, index) {
                          final song = libraryProvider.downloadedSongs[index];
                          return _buildSongTile(
                            context,
                            song,
                            libraryProvider,
                            playerProvider,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongTile(
    BuildContext context,
    Song song,
    LibraryProvider libraryProvider,
    PlayerProvider playerProvider,
  ) {
    return Dismissible(
      key: Key(song.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: Text(
                'Are you sure you want to delete "${song.title}" from your downloads?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _deleteDownloadedSong(song);
      },
      child: SongListItem(
        song: song,
        onTap: () => playerProvider.playSong(song),
        onOptionsPressed: () =>
            _showDownloadOptions(context, song, libraryProvider),
      ),
    );
  }

  void _deleteDownloadedSong(Song song) {
    final libraryProvider =
        Provider.of<LibraryProvider>(context, listen: false);
    libraryProvider.deleteSongDownload(song.id);
    _loadStorageInfo();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${song.title} removed from downloads'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showDownloadOptions(
    BuildContext context,
    Song song,
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
                leading: const Icon(Icons.delete),
                title: const Text('Delete Download'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteDownloadedSong(song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Add to Playlist'),
                onTap: () {
                  Navigator.pop(context);
                  // Show add to playlist dialog
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Song Information'),
                onTap: () {
                  Navigator.pop(context);
                  // Show song information
                },
              ),
            ],
          ),
        );
      },
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
                )
              : ListView.builder(
                  itemCount: libraryProvider.favoriteSongs.length,
                  itemBuilder: (context, index) {
                    final song = libraryProvider.favoriteSongs[index];
                    return SongListItem(
                      song: song,
                      onTap: () => playerProvider.playSong(song),
                    );
                  },
                ),
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab();

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

        final result = await libraryProvider.createPlaylist(
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

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);

    return RefreshIndicator(
      onRefresh: () => libraryProvider.loadPlaylists(),
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
    // Just return the songs directly from the playlist
    return playlist.songs;
  }

  void _navigateToPlaylistDetail(
    BuildContext context,
    Playlist playlist,
    List<Song> songs,
  ) {
    // Navigate to playlist detail page
    // This would be implemented in a real app
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening playlist "${playlist.name}"'),
        duration: const Duration(seconds: 1),
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

                  final index = libraryProvider.playlists
                      .indexWhere((p) => p.id == playlist.id);
                  if (index >= 0) {
                    libraryProvider.playlists[index] = updatedPlaylist;
                  }
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
}
