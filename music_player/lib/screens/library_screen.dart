import 'dart:developer';

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
  Map<String, double> _downloadProgress = {};
  bool _refreshing = false;

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

  Future<void> _refreshDownloads() async {
    setState(() {
      _refreshing = true;
    });

    try {
      final libraryProvider =
          Provider.of<LibraryProvider>(context, listen: false);
      await libraryProvider.loadDownloadedSongs();
      await _loadStorageInfo();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing downloads: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _refreshDownloads,
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
                        '${libraryProvider.downloadedSongs.length} songs · $_storageInfo',
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
                    onPressed: _refreshing ? null : _refreshDownloads,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ),

          // Downloaded songs list
          Expanded(
            child: libraryProvider.isLoadingDownloaded || _refreshing
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
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/search'),
                              icon: const Icon(Icons.search),
                              label: const Text('Search for songs to download'),
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
    final isPlaying =
        playerProvider.currentSong?.id == song.id && playerProvider.isPlaying;
    final isInQueue = playerProvider.queue.any((s) => s.id == song.id);

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
      child: ListTile(
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
            if (isPlaying)
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: Theme.of(context).primaryColor,
                ),
              ),
          ],
        ),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight:
                isPlaying || isInQueue ? FontWeight.bold : FontWeight.normal,
            color: isPlaying ? Theme.of(context).primaryColor : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.album,
                  size: 12,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    song.album,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                libraryProvider.isFavorite(song.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: libraryProvider.isFavorite(song.id) ? Colors.red : null,
              ),
              onPressed: () {
                libraryProvider.toggleFavorite(song);
              },
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () =>
                  _showDownloadOptions(context, song, libraryProvider),
            ),
          ],
        ),
        onTap: () => playerProvider.playSong(song),
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
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            libraryProvider.downloadSong(song);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Re-downloading ${song.title}'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDownloadOptions(
    BuildContext context,
    Song song,
    LibraryProvider libraryProvider,
  ) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

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
                  playerProvider.playSong(song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Add to Queue'),
                onTap: () {
                  Navigator.pop(context);
                  playerProvider.addToQueue(song);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added "${song.title}" to queue'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
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
                leading: const Icon(Icons.delete),
                title: const Text('Delete Download'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteDownloadedSong(song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Song Information'),
                onTap: () {
                  Navigator.pop(context);
                  _showSongInfo(context, song);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSongInfo(BuildContext context, Song song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(song.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  song.coverUrl,
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 150,
                      height: 150,
                      color: Colors.grey[300],
                      child: const Icon(Icons.music_note,
                          size: 64, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            _infoRow('Artist', song.artist),
            _infoRow('Album', song.album),
            _infoRow('Duration', _formatDuration(song.duration)),
            if (song.genre != null) _infoRow('Genre', song.genre!),
            _infoRow('Downloaded', 'Yes'),
            if (song.localPath != null)
              _infoRow('File', song.localPath!.split('/').last),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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
