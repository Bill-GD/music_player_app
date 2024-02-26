import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
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

  bool get playing => player.playing;

  AudioPlayerHandler() {
    player = AudioPlayer();
    player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    setVolume(Config.volume);
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

  /// Returns the song duration in millisecond, or 0 if `null`.
  ///
  /// Shouldn't expect it to return 0.
  Future<int> setPlayerSong(String songPath) async {
    Duration? duration = player.duration;

    if (songPath != Globals.currentSongPath || Globals.currentSongPath.isEmpty) {
      duration = await player.setAudioSource(
        AudioSource.uri(Uri.parse(Uri.encodeComponent(songPath))),
      );

      MusicTrack item = Globals.allSongs.firstWhere((e) => e.absolutePath == songPath);

      addMediaItem(MediaItem(
        id: songPath,
        title: item.trackName,
        artist: item.artist,
        duration: duration,
      ));

      await _incrementTimePlayed();
      if (Config.autoPlayNewSong) {
        play();
      }
    }
    return duration?.inMilliseconds ?? 0;
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
      await _incrementTimePlayed();
      seek(Duration.zero);
    }
    player.play();
  }

  Future<void> changeShuffleMode() async {
    debugPrint('Shuffle');
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
    debugPrint('Next song');
  }

  @override
  Future<void> skipToPrevious() async {
    debugPrint('Previous song');
  }

  @override
  Future<void> onTaskRemoved() async {
    if (!playbackState.value.playing) stop();
  }
}
