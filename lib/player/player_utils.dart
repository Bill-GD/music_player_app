import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:just_audio/just_audio.dart';

import '../globals/music_track.dart';
import '../globals/variables.dart';

/// Returns the current song duration in milliseconds
int getCurrentDuration() =>
    Globals.currentSongPath.isNotEmpty ? Globals.audioHandler.player.position.inMilliseconds : 0;

/// Returns the current song duration in milliseconds
int getTotalDuration() =>
    Globals.currentSongPath.isNotEmpty ? Globals.audioHandler.player.duration?.inMilliseconds ?? 1 : 1;

Future<void> _incrementTimePlayed() async {
  Globals
      .allSongs[Globals.allSongs.indexWhere((e) => e.absolutePath == Globals.currentSongPath)].timeListened++;
  debugPrint('Incremented play count');
  await saveSongsToStorage();
}

Future<AudioHandler> initAudioHandler() async {
  final handler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.billgd.music_hub.channel.audio',
      androidNotificationChannelName: 'Music Hub',
    ),
  );
  return handler;
}

class AudioPlayerHandler extends BaseAudioHandler {
  // Streams
  final _onSongChangeController = StreamController<bool>.broadcast();
  late Stream<bool> onSongChange;

  // Player
  late final AudioPlayer player;
  bool get playing => player.playing;

  // Playlist
  late List<String> _playlist; // Only keep track of paths
  String get playlistName => _playlistName;
  String _playlistName = '';

  // Play mode
  var _shuffle = AudioServiceShuffleMode.none;
  bool get isShuffled => _shuffle == AudioServiceShuffleMode.all;
  var _repeat = AudioServiceRepeatMode.none;
  AudioServiceRepeatMode get repeatMode => _repeat;

  // Listen count
  Duration _prevPos = 0.ms, _totalDuration = 0.ms;
  int _listenedDuration = 0;
  bool _listened = false;

  // Skip cooldown
  bool _skipping = false;

  AudioPlayerHandler() {
    onSongChange = _onSongChangeController.stream;

    _playlist = [];

    player = AudioPlayer();
    player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    setVolume(Config.volume);

    player.processingStateStream.listen((state) async {
      if (state == ProcessingState.completed) {
        if (_repeat == AudioServiceRepeatMode.one) {
          debugPrint('Repeat one, restarting song');
          await seek(0.ms);
        } else {
          skipToNext();
        }
      }
    });

    player.positionStream.listen((position) {
      int totalMilliseconds = _totalDuration.inMilliseconds;

      // Stops when play count is already incremented
      if (_listened) return;

      // Longer than length limit, to be safe
      if (totalMilliseconds >= Config.lengthLimitMilliseconds) {
        int interval = position.inMilliseconds - _prevPos.inMilliseconds;
        // If rewind, skip
        if (interval > 0) {
          if (interval < 1000) {
            _listenedDuration += interval;
          }
          if (!_listened && _listenedDuration >= (totalMilliseconds * 0.1).round()) {
            _incrementTimePlayed();
            _listened = true;
          }
        }
        _prevPos = position;
      }
    });
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState]!,
      playing: player.playing,
      updatePosition: player.position,
      queueIndex: event.currentIndex,
    );
  }

  Future<void> setPlayerSong(String songPath) async {
    Duration? duration = player.duration;

    if (songPath != Globals.currentSongPath || Globals.currentSongPath.isEmpty) {
      debugPrint('Switching to a different song: ${songPath.split('/').last}');

      duration = await player.setAudioSource(
        AudioSource.uri(Uri.parse(Uri.encodeComponent(songPath))),
      );
      Globals.currentSongPath = songPath;
      Globals.showMinimizedPlayer = true;

      MusicTrack item = Globals.allSongs.firstWhere((e) => e.absolutePath == songPath);

      addMediaItem(MediaItem(
        id: songPath,
        title: item.trackName,
        artist: item.artist,
        duration: duration,
      ));

      // Reset song listen duration trackers
      _prevPos = 0.ms;
      _totalDuration = duration ?? 0.ms;
      _listenedDuration = 0;
      _listened = false;

      // Broadcast change
      _onSongChangeController.add(true);

      if (_totalDuration.inMilliseconds <= 0) {
        debugPrint('Something is wrong when setting audio source');
      } else {
        debugPrint('Min listen time: ${(_totalDuration.inMilliseconds * 0.1).round()} ms');
      }

      if (Config.autoPlayNewSong) {
        play();
      }
    }
  }

  Future<void> registerPlaylist(String name, List<String> list, String begin) async {
    _playlist = list;

    _shufflePlaylist(begin: begin);

    int songCount = _playlist.length;
    _playlistName = 'Playlist: $name\n($songCount song${songCount > 1 ? 's' : ''})';
    debugPrint('Got playlist: $songCount songs');
  }

  void _shufflePlaylist({bool currentToStart = true, String begin = ''}) {
    if (_shuffle == AudioServiceShuffleMode.all) {
      debugPrint('Shuffling playlist');
      _playlist.shuffle();

      if (currentToStart) {
        if (begin.isEmpty) {
          debugPrint('Begin song should not be empty');
        } else {
          _playlist.removeWhere((e) => e == begin);
          _playlist.insert(0, begin);
        }
      }
    }
    debugPrint('Current song index: ${_playlist.indexWhere((e) => e == Globals.currentSongPath)}');
  }

  Future<void> addMediaItem(MediaItem item) async => mediaItem.add(item);

  Future<void> updateNotificationInfo({
    required String songPath,
    required String trackName,
    String? artist,
    Duration? duration,
  }) async {
    if (mediaItem.value == null) return;

    MediaItem item = MediaItem(
      id: songPath,
      title: trackName,
    );

    if (artist != null) item = item.copyWith(artist: artist);
    item = duration != null
        ? item.copyWith(duration: duration)
        : item.copyWith(duration: mediaItem.value!.duration);

    mediaItem.add(item);
  }

  Future<void> setVolume(double volume) async => player.setVolume(volume);

  @override
  Future<void> play() async {
    if (Globals.currentSongPath.isEmpty) return;

    if (player.processingState == ProcessingState.completed) {
      seek(0.ms);
    }
    player.play();
  }

  /// Only from player
  Future<void> changeShuffleMode() async {
    _shuffle = isShuffled
        ? AudioServiceShuffleMode.none //
        : AudioServiceShuffleMode.all;

    _shufflePlaylist(begin: Globals.currentSongPath);
    debugPrint('Change shuffle: $isShuffled');
    Config.saveConfig();
  }

  /// Only from player
  Future<void> changeRepeatMode() async {
    switch (_repeat) {
      case AudioServiceRepeatMode.all:
        _repeat = AudioServiceRepeatMode.one;
        break;
      case AudioServiceRepeatMode.one:
        _repeat = AudioServiceRepeatMode.none;
        break;
      case AudioServiceRepeatMode.none:
        _repeat = AudioServiceRepeatMode.all;
        break;
      default:
        break;
    }
    debugPrint('Change repeat: ${_repeat.name}');
    Config.saveConfig();
  }

  @override
  Future<void> pause() async => player.pause();

  @override
  Future<void> stop() async => player.stop();

  @override
  Future<void> seek(Duration position) async => player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_skipping) return;

    debugPrint('Skipping to next song');
    _skipping = true;

    if (_playlist.isEmpty) {
      pause();
      debugPrint('Playlist is empty, this should not be the case');
      return;
    }

    if (_playlist.length == 1) {
      debugPrint('Playlist only contains one song, skipping action');
      return;
    }

    int currentIndex = _playlist.indexWhere((e) => e == Globals.currentSongPath);

    if (currentIndex < 0) {
      pause();
      debugPrint('Can\'t find song in playlist, this should not be the case');
      return;
    }

    await Future.delayed(Config.delayMilliseconds.ms);

    if (currentIndex == _playlist.length - 1) {
      switch (_repeat) {
        case AudioServiceRepeatMode.all:
          debugPrint('Repeat all');
          if (isShuffled) _shufflePlaylist(currentToStart: false);
          await setPlayerSong(_playlist[0]);
          break;
        case AudioServiceRepeatMode.none:
          if (player.processingState == ProcessingState.completed) {
            debugPrint('Repeat none');
            pause();
          }
          break;
        default:
          await setPlayerSong(_playlist[0]);
          break;
      }
    } else {
      await setPlayerSong(_playlist[currentIndex + 1]);
    }
    _skipping = false;
  }

  @override
  Future<void> skipToPrevious() async {
    if (_skipping) return;

    debugPrint('Skipping to previous song');
    _skipping = true;

    if (_playlist.isEmpty) {
      pause();
      debugPrint('Playlist is empty, this should not be the case');
      return;
    }

    if (_playlist.length == 1) {
      debugPrint('Playlist only contains one song, skipping action');
      return;
    }

    int currentIndex = _playlist.indexWhere((e) => e == Globals.currentSongPath);

    if (currentIndex < 0) {
      pause();
      debugPrint('Can\'t find song in playlist, this should not be the case');
      return;
    }

    currentIndex = currentIndex == 0 ? _playlist.length : currentIndex;
    await setPlayerSong(_playlist[currentIndex - 1]);

    _skipping = false;
  }

  @override
  Future<void> onTaskRemoved() async {
    if (!playbackState.value.playing) stop();
  }

  void loadConfig(bool? shuffle, String? repeat) {
    _shuffle = shuffle == true ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none;
    _repeat = repeat == 'all'
        ? AudioServiceRepeatMode.all
        : repeat == 'one'
            ? AudioServiceRepeatMode.one
            : AudioServiceRepeatMode.none;
  }
}
