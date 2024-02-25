import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../globals/config.dart';
import '../globals/music_track.dart';
import '../globals/variables.dart';

/// Returns the current song duration in milliseconds
int getCurrentDuration() => currentSongPath.isNotEmpty ? audioPlayer.position.inMilliseconds : 0;

/// Returns the current song duration in milliseconds
int getTotalDuration() => currentSongPath.isNotEmpty ? audioPlayer.duration?.inMilliseconds ?? 1 : 1;

/// Returns the song duration in millisecond, or 0 if `null`.
///
/// Shouldn't expect it to return 0.
Future<int> setPlayerSong(String songPath) async {
  Duration? duration = audioPlayer.duration;

  if (songPath != currentSongPath || currentSongPath.isEmpty) {
    duration = await audioPlayer.setAudioSource(
      AudioSource.uri(Uri.parse(Uri.encodeComponent(songPath))),
    );

    MusicTrack item = allMusicTracks.firstWhere((e) => e.absolutePath == songPath);

    audioHandler.addMediaItem(MediaItem(
      id: songPath,
      title: item.trackName,
      artist: item.artist,
      duration: duration,
    ));

    await _incrementTimePlayed();
    if (autoPlayNewSong) {
      audioHandler.play();
    }
  }
  return duration?.inMilliseconds ?? 0;
}

Future<void> _incrementTimePlayed() async {
  allMusicTracks[allMusicTracks.indexWhere((e) => e.absolutePath == currentSongPath)].timeListened++;
  await saveSongsToStorage();
}

Future<AudioHandler> initAudioHandler() async {
  final handler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.billgd.music_hub.channel.audio',
      androidNotificationChannelName: 'Music Playback',
    ),
  );
  return handler;
}

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  MyAudioHandler() {
    audioPlayer.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (audioPlayer.playing) MediaControl.pause else MediaControl.play,
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
      }[audioPlayer.processingState]!,
      playing: audioPlayer.playing,
      updatePosition: audioPlayer.position,
      speed: audioPlayer.speed,
      queueIndex: event.currentIndex,
    );
  }

  Future<void> addMediaItem(MediaItem item) async {
    mediaItem.add(item);
  }

  // The most common callbacks:
  @override
  Future<void> play() async {
    // All 'play' requests from all origins route to here. Implement this
    // callback to start playing audio appropriate to your app. e.g. music.
    if (currentSongPath.isEmpty) return;

    if (audioPlayer.processingState == ProcessingState.completed) {
      await _incrementTimePlayed();
      audioHandler.seek(Duration.zero);
    }
    audioPlayer.play();
  }

  @override
  Future<void> pause() async {
    audioPlayer.pause();
  }

  @override
  Future<void> stop() async {
    audioPlayer.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    audioPlayer.seek(position);
  }

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
    audioPlayer.stop();
  }
}
