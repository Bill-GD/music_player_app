import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../globals/config.dart';
import '../globals/music_track.dart';
import '../globals/variables.dart';

/// Returns the current song duration in milliseconds
int getCurrentDuration() => currentSong != null ? audioPlayer.position.inMilliseconds : 0;

/// Returns the current song duration in milliseconds
int getTotalDuration() => currentSong != null ? audioPlayer.duration?.inMilliseconds ?? 1 : 1;

/// Returns the song duration in millisecond, or 0 if `null`.
///
/// Shouldn't expect it to return 0.
Future<int> setPlayerSong(MusicTrack song) async {
  Duration? duration = audioPlayer.duration;

  if (song != currentSong || currentSong == null) {
    duration = await audioPlayer.setAudioSource(
      AudioSource.uri(Uri.parse(Uri.encodeComponent(song.absolutePath))),
    );
    await _incrementTimePlayed();
    if (autoPlayNewSong) {
      playPlayer();
    }
  }
  return duration?.inMilliseconds ?? 0;
}

Future<void> _incrementTimePlayed() async {
  allMusicTracks[allMusicTracks.indexWhere((e) => e.absolutePath == currentSong!.absolutePath)]
      .timeListened++;
  await saveSongsToStorage();
}

void playPlayer() async {
  if (currentSong == null) return;

  if (audioPlayer.processingState == ProcessingState.completed) {
    await _incrementTimePlayed();
    audioPlayer.seek(Duration.zero);
  }
  audioPlayer.play();
}

void pausePlayer() => audioPlayer.pause();

void toPreviousSong() {
  debugPrint('Previous song');
}

void toNextSong() {
  debugPrint('Next song');
}
