import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../providers/library_provider.dart';

enum ShuffleMode { off, on }

enum RepeatMode { off, all, one }

class PlayerProvider with ChangeNotifier {
  // UI State
  bool _isPlayerVisible = false;
  bool _isPlaying = false;
  bool _isBuffering = false;

  // Player State
  Song? _currentSong;
  List<Song> _queue = [];
  int _currentIndex = -1;
  bool _isShuffleEnabled = false;
  RepeatMode _repeatMode = RepeatMode.off;

  // Dependencies
  LibraryProvider? _libraryProvider;

  // Audio Player
  late final AudioPlayer _audioPlayer;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;

  // Getters
  bool get isPlayerVisible => _isPlayerVisible;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  Song? get currentSong => _currentSong;
  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get isShuffleEnabled => _isShuffleEnabled;
  RepeatMode get repeatMode => _repeatMode;

  PlayerProvider() {
    _initAudioPlayer();
  }

  // Set the library provider reference
  void setLibraryProvider(LibraryProvider libraryProvider) {
    _libraryProvider = libraryProvider;
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer();

    // Listen to player state changes
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isBuffering = state.processingState == ProcessingState.buffering;
      notifyListeners();

      if (state.processingState == ProcessingState.completed) {
        _onSongComplete();
      }
    });

    // Listen to position changes
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      // We don't need to call notifyListeners() here as this would cause too many rebuilds
      // The UI can listen to positionStream directly
    });

    // Listen to duration changes
    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      // Update duration when it changes
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Show the full player
  void showPlayer() {
    _isPlayerVisible = true;
    notifyListeners();
  }

  // Hide the full player
  void hidePlayer() {
    _isPlayerVisible = false;
    notifyListeners();
  }

  // Play a single song
  Future<void> playSong(Song song) async {
    try {
      _queue = [song];
      _currentIndex = 0;
      _currentSong = song;

      await _loadAndPlaySong(song);

      // Add to recently played if library provider is available
      if (_libraryProvider != null) {
        await _libraryProvider!.addToRecentlyPlayed(song);
      }

      notifyListeners();
    } catch (e) {
      print('Error playing song: $e');
      rethrow;
    }
  }

  // Play a playlist
  Future<void> playPlaylist(Playlist playlist, {int initialIndex = 0}) async {
    try {
      if (playlist.songs.isEmpty) return;

      _queue = List.from(playlist.songs);
      _currentIndex = initialIndex.clamp(0, _queue.length - 1);
      _currentSong = _queue[_currentIndex];

      await _loadAndPlaySong(_currentSong!);

      // Add to recently played if library provider is available
      if (_libraryProvider != null && _currentSong != null) {
        await _libraryProvider!.addToRecentlyPlayed(_currentSong!);
      }

      notifyListeners();
    } catch (e) {
      print('Error playing playlist: $e');
      rethrow;
    }
  }

  // Load and play a specific song
  Future<void> _loadAndPlaySong(Song song) async {
    try {
      String sourceUrl = song.isDownloaded && song.localPath != null
          ? song.localPath!
          : song.audioUrl;

      // For web, we need to use the network URL even if it's "downloaded"
      if (kIsWeb && song.isDownloaded) {
        sourceUrl = song.audioUrl;
      }

      // Stop current playback
      await _audioPlayer.stop();

      // Set the audio source
      await _audioPlayer.setUrl(sourceUrl);
      await _audioPlayer.play();
    } catch (e) {
      print('Error loading song: $e');
      rethrow;
    }
  }

  // Play or pause the current song
  Future<void> playPause() async {
    try {
      if (_currentSong == null) return;

      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      print('Error toggling play/pause: $e');
    }
  }

  // Skip to next song
  Future<void> skipToNext() async {
    try {
      if (_queue.isEmpty || _currentIndex < 0) return;

      int nextIndex;

      if (_isShuffleEnabled) {
        // Improved randomization for shuffle mode
        if (_queue.length > 1) {
          // Use a more robust random number generation
          final random = Random();
          int randomIndex;
          do {
            randomIndex = random.nextInt(_queue.length);
          } while (randomIndex == _currentIndex);
          nextIndex = randomIndex;
        } else {
          nextIndex = 0;
        }
      } else {
        // Normal next song
        nextIndex = _currentIndex + 1;

        // Handle repeat modes
        if (nextIndex >= _queue.length) {
          if (_repeatMode == RepeatMode.all) {
            nextIndex = 0;
          } else {
            // End of queue and no repeat - stop playback
            await _audioPlayer.stop();
            _currentIndex = -1;
            _currentSong = null;
            notifyListeners();
            return;
          }
        }
      }

      _currentIndex = nextIndex;
      _currentSong = _queue[_currentIndex];

      await _loadAndPlaySong(_currentSong!);

      // Add to recently played if library provider is available
      if (_libraryProvider != null && _currentSong != null) {
        await _libraryProvider!.addToRecentlyPlayed(_currentSong!);
      }

      notifyListeners();
    } catch (e) {
      print('Error skipping to next: $e');
    }
  }

  // Skip to previous song
  Future<void> skipToPrevious() async {
    try {
      if (_queue.isEmpty || _currentIndex < 0) return;

      // If we're more than 3 seconds into the song, go back to the start
      if (_audioPlayer.position > const Duration(seconds: 3)) {
        await _audioPlayer.seek(Duration.zero);
        return;
      }

      int prevIndex;

      if (_isShuffleEnabled) {
        // Improved randomization for shuffle mode
        if (_queue.length > 1) {
          // Use a more robust random number generation
          final random = Random();
          int randomIndex;
          do {
            randomIndex = random.nextInt(_queue.length);
          } while (randomIndex == _currentIndex);
          prevIndex = randomIndex;
        } else {
          prevIndex = 0;
        }
      } else {
        // Normal previous song
        prevIndex = _currentIndex - 1;

        // Handle repeat modes
        if (prevIndex < 0) {
          if (_repeatMode == RepeatMode.all) {
            prevIndex = _queue.length - 1;
          } else {
            // Start of queue - restart current song
            await _audioPlayer.seek(Duration.zero);
            return;
          }
        }
      }

      _currentIndex = prevIndex;
      _currentSong = _queue[_currentIndex];

      await _loadAndPlaySong(_currentSong!);

      // Add to recently played if library provider is available
      if (_libraryProvider != null && _currentSong != null) {
        await _libraryProvider!.addToRecentlyPlayed(_currentSong!);
      }

      notifyListeners();
    } catch (e) {
      print('Error skipping to previous: $e');
    }
  }

  // Seek to position
  Future<void> seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  // Toggle shuffle mode
  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    notifyListeners();
  }

  // Change repeat mode
  void toggleRepeatMode() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }

    // Update player settings
    if (_repeatMode == RepeatMode.one) {
      _audioPlayer.setLoopMode(LoopMode.one);
    } else {
      _audioPlayer.setLoopMode(LoopMode.off);
    }

    notifyListeners();
  }

  // Handle song completion
  void _onSongComplete() {
    if (_repeatMode == RepeatMode.one) {
      // Song will automatically repeat
      return;
    }

    // Skip to next song
    skipToNext();
  }

  // Get duration stream
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  // Get position stream
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  // Get current duration
  Duration? get duration => _audioPlayer.duration;

  // Get current position
  Duration get position => _audioPlayer.position;
}
