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
    await _incrementTimePlayed();
    if (autoPlayNewSong) {
      playPlayer();
    }
  }
  return duration?.inMilliseconds ?? 0;
}

Future<void> _incrementTimePlayed() async {
  allMusicTracks[allMusicTracks.indexWhere((e) => e.absolutePath == currentSongPath)].timeListened++;
  await saveSongsToStorage();
}

void playPlayer() async {
  if (currentSongPath.isEmpty) return;

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
