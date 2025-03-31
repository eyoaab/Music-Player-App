import 'package:flutter/material.dart';
import '../../models/song.dart';

class DownloadedSongsTab extends StatelessWidget {
  final Function(Song, BuildContext) onSongTapped;

  const DownloadedSongsTab({
    super.key,
    required this.onSongTapped,
  });

  @override
  Widget build(BuildContext context) {
    // The implementation should be added elsewhere
    // This is just a placeholder to fix the error
    return const Center(
      child: Text('Downloads Tab'),
    );
  }
}
