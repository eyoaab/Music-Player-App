import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/player_provider.dart';
import '../../providers/theme_provider.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final song = playerProvider.currentSong;
    final isDarkMode = themeProvider.isDarkMode;
    final primaryColor = Theme.of(context).primaryColor;

    if (song == null) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF252525) : primaryColor.withOpacity(0.1),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(isDarkMode ? 0.2 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Album art
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Hero(
              tag: 'albumArt${song.id}',
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: song.coverUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Song info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    song.title,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.white70
                          : primaryColor.withOpacity(0.8),
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // Progress indicator
          Expanded(
            flex: 1,
            child: StreamBuilder<Duration>(
              stream: playerProvider.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = playerProvider.duration ?? Duration.zero;

                final progress = duration.inMilliseconds > 0
                    ? position.inMilliseconds / duration.inMilliseconds
                    : 0.0;

                return LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isDarkMode ? Colors.white12 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    primaryColor,
                  ),
                  minHeight: 2,
                );
              },
            ),
          ),

          // Play/pause button
          IconButton(
            icon: Icon(
              playerProvider.isPlaying ? Icons.pause : Icons.play_arrow,
              color: primaryColor,
            ),
            onPressed: () {
              playerProvider.playPause();
            },
          ),
        ],
      ),
    );
  }
}
