import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/player_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/library_provider.dart';

class FullPlayer extends StatefulWidget {
  final VoidCallback onClose;

  const FullPlayer({
    super.key,
    required this.onClose,
  });

  @override
  State<FullPlayer> createState() => _FullPlayerState();
}

class _FullPlayerState extends State<FullPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  List<double> _waveformHeights = [];
  String? _currentSongId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Generate random waveform heights
    _generateWaveform();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _generateWaveform() {
    final random = Random();
    _waveformHeights = List.generate(
      50,
      (_) => 0.3 + (random.nextDouble() * 0.7),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;
    final song = playerProvider.currentSong;
    final isDarkMode = themeProvider.isDarkMode;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final isFavorite =
        song != null ? libraryProvider.isFavorite(song.id) : false;

    if (song == null) {
      return const SizedBox.shrink();
    }

    // Check if song has changed and regenerate waveform if needed
    if (_currentSongId != song.id) {
      _currentSongId = song.id;
      _generateWaveform();
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 30),
          color: isDarkMode ? Colors.white : Colors.black87,
          onPressed: widget.onClose,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            color: isDarkMode ? Colors.white : Colors.black87,
            onPressed: () {
              // Show options menu (add to playlist, etc.)
              if (song == null) return;

              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading:
                              Icon(Icons.playlist_add, color: primaryColor),
                          title: const Text('Add to playlist'),
                          onTap: () {
                            Navigator.pop(context);
                            // Navigate to add to playlist screen
                            Navigator.pushNamed(
                              context,
                              '/playlist/add',
                              arguments: song,
                            );
                          },
                        ),
                        ListTile(
                          leading: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : primaryColor),
                          title: Text(isFavorite
                              ? 'Remove from favorites'
                              : 'Add to favorites'),
                          onTap: () {
                            Navigator.pop(context);
                            // Toggle favorite status
                            libraryProvider.toggleFavorite(song);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isFavorite
                                      ? 'Removed from favorites'
                                      : 'Added to favorites',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: isFavorite
                                    ? Colors.grey[800]
                                    : primaryColor,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: Icon(
                            song.isDownloaded ? Icons.delete : Icons.download,
                            color: primaryColor,
                          ),
                          title: Text(
                            song.isDownloaded ? 'Delete download' : 'Download',
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            if (song.isDownloaded) {
                              // Delete download
                              libraryProvider.deleteSongDownload(song.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Removed "${song.title}" from downloads'),
                                  backgroundColor: Colors.grey[800],
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } else {
                              // Download song
                              libraryProvider.downloadSong(song);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Downloading "${song.title}"'),
                                  backgroundColor: primaryColor,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [
                    const Color(0xFF2C2C2C),
                    const Color(0xFF1A1A1A),
                    const Color(0xFF121212),
                  ]
                : [
                    primaryColor.withOpacity(0.8),
                    primaryColor.withOpacity(0.3),
                    Colors.white,
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenSize.width * 0.06,
                vertical: isSmallScreen ? 8.0 : 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Now Playing text
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      'NOW PLAYING',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),

                  // Album Art
                  Hero(
                    tag: 'albumArt${song.id}',
                    child: Container(
                      width: screenSize.width * (isSmallScreen ? 0.65 : 0.75),
                      height: screenSize.width * (isSmallScreen ? 0.65 : 0.75),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.black.withOpacity(0.4)
                                : primaryColor.withOpacity(0.3),
                            spreadRadius: 5,
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.white,
                          width: 4,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: song.coverUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[300],
                            child: Center(
                              child: CircularProgressIndicator(
                                color: primaryColor,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[300],
                            child: Icon(
                              Icons.music_note,
                              size: 50,
                              color: primaryColor.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 25 : 40),

                  // Song info
                  Text(
                    song.title,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${song.artist} • ${song.album}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: isSmallScreen ? 20 : 32),

                  // Progress bar
                  StreamBuilder<Duration>(
                    stream: playerProvider.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final duration = playerProvider.duration ?? Duration.zero;

                      // Format time as mm:ss
                      String formatDuration(Duration duration) {
                        String twoDigits(int n) => n.toString().padLeft(2, '0');
                        String twoDigitMinutes =
                            twoDigits(duration.inMinutes.remainder(60));
                        String twoDigitSeconds =
                            twoDigits(duration.inSeconds.remainder(60));
                        return "$twoDigitMinutes:$twoDigitSeconds";
                      }

                      return Column(
                        children: [
                          ProgressBar(
                            progress: position,
                            total: duration,
                            buffered: duration,
                            progressBarColor: primaryColor,
                            baseBarColor: isDarkMode
                                ? Colors.white.withOpacity(0.15)
                                : Colors.black.withOpacity(0.1),
                            bufferedBarColor: isDarkMode
                                ? Colors.white.withOpacity(0.3)
                                : primaryColor.withOpacity(0.3),
                            thumbColor: primaryColor,
                            barHeight: 4,
                            thumbRadius: 8,
                            timeLabelLocation: TimeLabelLocation.none,
                            onSeek: (duration) {
                              playerProvider.seekTo(duration);
                            },
                          ),

                          // Time indicators below progress bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatDuration(position),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                                Text(
                                  formatDuration(duration),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: isSmallScreen ? 24 : 36),

                  // Waveform Visualization - hide on very small screens
                  if (!isSmallScreen || screenSize.height > 550)
                    StreamBuilder<Duration>(
                      stream: playerProvider.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        final duration =
                            playerProvider.duration ?? Duration.zero;
                        final progress = duration.inMilliseconds > 0
                            ? position.inMilliseconds / duration.inMilliseconds
                            : 0.0;

                        return SizedBox(
                          height: 60,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(
                              isSmallScreen ? 30 : 50,
                              (index) {
                                final totalBars = isSmallScreen ? 30 : 50;
                                final barPos = index / totalBars;
                                final isActive = barPos < progress;

                                return AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    double height = _waveformHeights[
                                        index % _waveformHeights.length];

                                    // Apply animation to active bars
                                    if (isActive) {
                                      // Apply stronger animation to bars near the playhead
                                      final distance =
                                          (barPos - progress).abs();
                                      if (distance < 0.05) {
                                        // Bars near playhead pulse more dramatically
                                        height *= 1 +
                                            (_animationController.value * 0.7);
                                      } else {
                                        // Other active bars have subtle animation
                                        height *= 1 +
                                            (_animationController.value * 0.2);
                                      }
                                    }

                                    return AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      width: 3,
                                      height: 40 * height,
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? primaryColor
                                            : (isDarkMode
                                                ? Colors.white.withOpacity(0.2)
                                                : Colors.black
                                                    .withOpacity(0.1)),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),

                  SizedBox(height: isSmallScreen ? 24 : 36),

                  // Controls
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Shuffle button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              playerProvider.toggleShuffle();
                            },
                            borderRadius: BorderRadius.circular(30),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: playerProvider.isShuffleEnabled
                                      ? primaryColor.withOpacity(0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.shuffle,
                                  size: isSmallScreen ? 22 : 24,
                                  color: playerProvider.isShuffleEnabled
                                      ? primaryColor
                                      : (isDarkMode
                                          ? Colors.white60
                                          : Colors.black54),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Previous button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              playerProvider.skipToPrevious();
                            },
                            borderRadius: BorderRadius.circular(30),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Icon(
                                Icons.skip_previous,
                                size: isSmallScreen ? 32 : 36,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),

                        // Play/Pause button
                        Container(
                          width: isSmallScreen ? 64 : 72,
                          height: isSmallScreen ? 64 : 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.4),
                                spreadRadius: 1,
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                playerProvider.playPause();
                              },
                              borderRadius: BorderRadius.circular(40),
                              child: Icon(
                                playerProvider.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                size: isSmallScreen ? 32 : 36,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),

                        // Next button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              playerProvider.skipToNext();
                            },
                            borderRadius: BorderRadius.circular(30),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Icon(
                                Icons.skip_next,
                                size: isSmallScreen ? 32 : 36,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),

                        // Repeat button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              playerProvider.toggleRepeatMode();
                            },
                            borderRadius: BorderRadius.circular(30),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: playerProvider.repeatMode !=
                                          RepeatMode.off
                                      ? primaryColor.withOpacity(0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  playerProvider.repeatMode == RepeatMode.one
                                      ? Icons.repeat_one
                                      : Icons.repeat,
                                  size: isSmallScreen ? 22 : 24,
                                  color: playerProvider.repeatMode !=
                                          RepeatMode.off
                                      ? primaryColor
                                      : (isDarkMode
                                          ? Colors.white60
                                          : Colors.black54),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
