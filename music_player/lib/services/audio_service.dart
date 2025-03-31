import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

class MusicPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Song? _currentSong;
  List<Song> _queue = [];
  int _currentIndex = -1;

  // Stream getters
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<int?> get currentIndexStream => _audioPlayer.currentIndexStream;

  // Value getters
  PlayerState get playerState => _audioPlayer.playerState;
  Duration get position => _audioPlayer.position;
  Duration? get duration => _audioPlayer.duration;
  Song? get currentSong => _currentSong;
  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get hasNext => _currentIndex < _queue.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  // Constructors
  MusicPlayerService() {
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer.playbackEventStream.listen((event) {
      // Handle playback events if needed
    }, onError: (Object e, StackTrace stackTrace) {
      print('A stream error occurred: $e');
    });
  }

  // Play a single song
  Future<void> play(Song song) async {
    _currentSong = song;
    _queue = [song];
    _currentIndex = 0;

    try {
      final source = song.isDownloaded && song.localPath != null
          ? AudioSource.file(song.localPath!)
          : AudioSource.uri(Uri.parse(song.audioUrl));

      await _audioPlayer.setAudioSource(source);
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing song: $e');
    }
  }

  // Play a queue of songs
  Future<void> playQueue(List<Song> songs, int initialIndex) async {
    if (songs.isEmpty) return;

    _queue = List.from(songs);
    _currentIndex = initialIndex.clamp(0, songs.length - 1);
    _currentSong = _queue[_currentIndex];

    try {
      final playlist = ConcatenatingAudioSource(
        children: _queue.map((song) {
          return song.isDownloaded && song.localPath != null
              ? AudioSource.file(song.localPath!)
              : AudioSource.uri(Uri.parse(song.audioUrl));
        }).toList(),
      );

      await _audioPlayer.setAudioSource(playlist, initialIndex: _currentIndex);
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing queue: $e');
    }
  }

  // Playback controls
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.play();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> skipToNext() async {
    if (hasNext) {
      await _audioPlayer.seekToNext();
      _currentIndex++;
      _currentSong = _queue[_currentIndex];
    }
  }

  Future<void> skipToPrevious() async {
    if (hasPrevious) {
      await _audioPlayer.seekToPrevious();
      _currentIndex--;
      _currentSong = _queue[_currentIndex];
    }
  }

  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> setSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed.clamp(0.5, 2.0));
  }

  Future<void> setLoopMode(LoopMode mode) async {
    await _audioPlayer.setLoopMode(mode);
  }

  Future<void> setShuffleModeEnabled(bool enabled) async {
    await _audioPlayer.setShuffleModeEnabled(enabled);
  }

  // Dispose resources
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}

enum PlaybackState {
  playing,
  paused,
  stopped,
  loading,
  error,
}
