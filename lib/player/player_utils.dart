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
  late final AudioPlayer player;
  late List<String> playlist; // Only keep track of paths

  bool get playing => player.playing;
  String playlistName = '';

  Duration _prevPos = 0.ms, _totalDuration = 0.ms;
  int _listenedDuration = 0;
  bool _listened = false;

  final _onSongChangeController = StreamController<bool>.broadcast();
  late Stream<bool> onSongChange;

  AudioPlayerHandler() {
    onSongChange = _onSongChangeController.stream;

    playlist = [];

    player = AudioPlayer();
    player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    setVolume(Config.volume);

    player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
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

  Future<void> registerPlaylist(String name, List<String> list) async {
    playlist = list;
    int songCount = playlist.length;
    playlistName = 'Playlist: $name - $songCount song${songCount > 1 ? 's' : ''}';
    debugPrint('Got playlist: $songCount songs');
  }

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'shuffle':
        changeShuffleMode();
        break;
      case 'repeat':
        changeRepeatMode();
        break;
    }
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

  Future<void> changeShuffleMode() async {
    debugPrint('Change shuffle');
  }

  Future<void> changeRepeatMode() async {
    debugPrint('Change repeat');
  }

  @override
  Future<void> pause() async => player.pause();

  @override
  Future<void> stop() async => player.stop();

  @override
  Future<void> seek(Duration position) async => player.seek(position);

  @override
  Future<void> skipToNext() async {
    debugPrint('Skipping to next song');

    if (playlist.isEmpty) {
      pause();
      debugPrint('Playlist is empty, this should not be the case');
      return;
    }

    if (playlist.length == 1) {
      debugPrint('Playlist only contains one song, skipping action');
      return;
    }

    int currentIndex = playlist.indexWhere((e) => e == Globals.currentSongPath);

    if (currentIndex < 0) {
      pause();
      debugPrint('Can\'t find song in playlist, this should not be the case');
      return;
    }

    currentIndex = (currentIndex + 1) % playlist.length;
    await setPlayerSong(playlist[currentIndex]);
  }

  @override
  Future<void> skipToPrevious() async {
    debugPrint('Skipping to previous song');

    if (playlist.isEmpty) {
      pause();
      debugPrint('Playlist is empty, this should not be the case');
      return;
    }

    if (playlist.length == 1) {
      debugPrint('Playlist only contains one song, skipping action');
      return;
    }

    int currentIndex = playlist.indexWhere((e) => e == Globals.currentSongPath);

    if (currentIndex < 0) {
      pause();
      debugPrint('Can\'t find song in playlist, this should not be the case');
      return;
    }

    currentIndex = currentIndex == 0 ? playlist.length : currentIndex;
    await setPlayerSong(playlist[currentIndex - 1]);
  }

  @override
  Future<void> onTaskRemoved() async {
    if (!playbackState.value.playing) stop();
  }
}
