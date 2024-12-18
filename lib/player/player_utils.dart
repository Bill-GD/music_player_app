import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../globals/functions.dart';
import '../globals/log_handler.dart';
import '../globals/music_track.dart';
import '../globals/variables.dart';

/// Returns the current song duration in milliseconds
int getCurrentDuration() => Globals.currentSongID >= 0
    ? Globals.audioHandler.player.position.inMilliseconds //
    : 0;

/// Returns the current song duration in milliseconds
int getTotalDuration() => Globals.currentSongID >= 0
    ? Globals.audioHandler.player.duration?.inMilliseconds ?? 1 //
    : 1;

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
  AudioPlayer get player => _player;
  late final AudioPlayer _player;

  bool get playing => _player.playing;

  // Playlist
  late List<int> _playlist; // Only keep track of IDs
  List<int> get playlist => _playlist;

  String get playlistName => _playlistName;
  String _playlistName = '';

  // Play mode
  var _shuffle = AudioServiceShuffleMode.none;

  bool get isShuffled => _shuffle == AudioServiceShuffleMode.all;
  var _repeat = AudioServiceRepeatMode.none;

  AudioServiceRepeatMode get repeatMode => _repeat;

  // Listen count
  Duration _prevPos = 0.ms, _totalDuration = 0.ms;
  int _listenedDuration = 0, _minTime = 0;
  bool _listened = false;

  double get minTimePercent => _minTime / _totalDuration.inMilliseconds;

  // Skip cooldown
  bool _skipping = false;

  AudioPlayerHandler() {
    onSongChange = _onSongChangeController.stream;

    _playlist = [];

    _player = AudioPlayer();
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    setVolume(Config.volume);

    _player.processingStateStream.listen((state) async {
      if (state == ProcessingState.completed) {
        if (_repeat == AudioServiceRepeatMode.one) {
          LogHandler.log('Repeat one, restarting song');
          await seek(0.ms);
        } else {
          skipToNext();
        }
      }
    });

    _player.positionStream.listen((position) {
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
          if (!_listened && _listenedDuration >= _minTime) {
            Globals.allSongs.firstWhere((e) => e.id == Globals.currentSongID).incrementTimePlayed();
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
        if (_player.playing) MediaControl.pause else MediaControl.play,
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
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      queueIndex: event.currentIndex,
    );
  }

  Future<void> setPlayerSong(int songID) async {
    Duration? duration = _player.duration;

    if (songID == Globals.currentSongID && Globals.currentSongID >= 0) return;

    MusicTrack item = Globals.allSongs.firstWhere((e) => e.id == songID);

    LogHandler.log('Switching to a different song: ${item.path}');
    duration = await _player.setAudioSource(
      AudioSource.uri(Uri.parse(Uri.encodeComponent(item.fullPath))),
    );

    Globals.currentSongID = songID;
    Globals.showMinimizedPlayer = true;

    addMediaItem(MediaItem(
      id: '$songID',
      title: item.name,
      artist: item.artist,
      duration: duration,
    ));

    // Reset song listen duration trackers
    _prevPos = 0.ms;
    _totalDuration = duration ?? 0.ms;
    _listenedDuration = 0;
    _listened = false;
    _minTime = min(
      max((_totalDuration.inMilliseconds * 0.1).round(), 10000),
      _totalDuration.inMilliseconds,
    );

    // Broadcast change
    _onSongChangeController.add(true);

    if (_totalDuration.inMilliseconds <= 0) {
      LogHandler.log('Something is wrong when setting audio source');
    } else {
      LogHandler.log('Min listen time: $_minTime / ${_totalDuration.inMilliseconds} ms');
    }

    if (Config.autoPlayNewSong) {
      play();
    } else {
      pause();
    }
  }

  void updatePlaylistName(String newName) {
    _playlistName = newName;
  }

  Future<void> registerPlaylist(String name, List<int> list, int beginIdx) async {
    _playlist = list;

    if (_shuffle == AudioServiceShuffleMode.all) {
      _shufflePlaylist(begin: beginIdx);
    }

    int songCount = _playlist.length;
    _playlistName = '$name ($songCount song${songCount > 1 ? 's' : ''})';
    LogHandler.log('Got playlist: $songCount songs');
  }

  void _shufflePlaylist({bool currentToStart = true, int begin = -1}) {
    LogHandler.log('Shuffling playlist');
    _playlist.shuffle();

    if (currentToStart) {
      if (begin < 0) {
        LogHandler.log('A begin song should be selected');
      } else {
        _playlist.removeWhere((e) => e == begin);
        _playlist.insert(0, begin);
      }
    }
    LogHandler.log('Current playlist song index: ${_playlist.indexWhere((e) => e == Globals.currentSongID)}');
  }

  void moveSong(int from, int to) {
    if (from < 0 || from >= _playlist.length || to < 0 || to >= _playlist.length) {
      LogHandler.log('Invalid move song index');
      return;
    }

    int songIdx = _playlist.removeAt(from);
    _playlist.insert(to, songIdx);
  }

  Future<void> addMediaItem(MediaItem item) async => mediaItem.add(item);

  Future<void> updateNotificationInfo({
    required int songID,
    required String trackName,
    String? artist,
    Duration? duration,
  }) async {
    if (mediaItem.value == null) return;

    MediaItem item = MediaItem(
      id: '$songID',
      title: trackName,
    );

    if (artist != null) item = item.copyWith(artist: artist);
    item = duration != null ? item.copyWith(duration: duration) : item.copyWith(duration: mediaItem.value!.duration);

    mediaItem.add(item);
  }

  Future<void> setVolume(double volume) async => _player.setVolume(volume);

  @override
  Future<void> play() async {
    if (Globals.currentSongID < 0) return;

    if (_player.processingState == ProcessingState.completed) {
      seek(0.ms);
    }
    _player.play();
  }

  /// Only from _player
  void changeShuffleMode() {
    _shuffle = isShuffled
        ? AudioServiceShuffleMode.none //
        : AudioServiceShuffleMode.all;

    _shufflePlaylist(begin: Globals.currentSongID);
    LogHandler.log('Change shuffle: $isShuffled');
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
    LogHandler.log('Change repeat: ${_repeat.name}');
    Config.saveConfig();
  }

  @override
  Future<void> pause() async => _player.pause();

  @override
  Future<void> stop() async => _player.stop();

  @override
  Future<void> seek(Duration position) async => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_skipping) return;

    LogHandler.log('Skipping to next song');
    _skipping = true;

    if (_playlist.isEmpty) {
      pause();
      LogHandler.log('Playlist is empty, this should not be the case');
      return;
    }

    if (_playlist.length == 1) {
      LogHandler.log('Playlist only contains one song, skipping action');
      return;
    }

    int currentIndex = _playlist.indexWhere((e) => e == Globals.currentSongID);

    if (currentIndex < 0) {
      pause();
      LogHandler.log('Can\'t find song in playlist, this should not be the case');
      return;
    }

    await Future.delayed(
      Config.delayMilliseconds.ms,
      () => LogHandler.log('Delayed for ${Config.delayMilliseconds}ms'),
    );

    if (currentIndex == _playlist.length - 1) {
      switch (_repeat) {
        case AudioServiceRepeatMode.all:
          LogHandler.log('Repeat all');
          if (isShuffled) _shufflePlaylist(currentToStart: false);
          await setPlayerSong(_playlist[0]);
          break;
        case AudioServiceRepeatMode.none:
          if (_player.processingState == ProcessingState.completed) {
            LogHandler.log('Repeat none');
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

    LogHandler.log('Skipping to previous song');
    _skipping = true;

    if (_playlist.isEmpty) {
      pause();
      LogHandler.log('Playlist is empty, this should not be the case');
      return;
    }

    if (_playlist.length == 1) {
      LogHandler.log('Playlist only contains one song, skipping action');
      return;
    }

    int currentIndex = _playlist.indexWhere((e) => e == Globals.currentSongID);

    if (currentIndex < 0) {
      pause();
      LogHandler.log('Can\'t find song in playlist, this should not be the case');
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
    setVolume(Config.volume);
    _shuffle = shuffle == true ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none;
    _repeat = repeat == 'all'
        ? AudioServiceRepeatMode.all
        : repeat == 'one'
            ? AudioServiceRepeatMode.one
            : AudioServiceRepeatMode.none;
  }
}
