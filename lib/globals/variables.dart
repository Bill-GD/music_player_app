import 'package:package_info_plus/package_info_plus.dart';

import '../player/player_utils.dart';
import 'music_track.dart';

class Globals {
  /// List of all songs, persistent
  static List<MusicTrack> allSongs = [];

  /// List of name and song count of artists
  static Map<String, int> artists = {};

  static late final AudioPlayerHandler audioHandler;

  static late final PackageInfo packageInfo;

  /// Does the minimized player shows up?
  static bool showMinimizedPlayer = false;

  /// Path of the currently selected/playing song
  static String currentSongPath = '';
}

// Configs
// Save these in config.json or something
/// All user configurations, expose in setting page
class Config {
  /// Current sorting order of the song list, default [SortOptions.name]
  static SortOptions currentSortOption = SortOptions.name;

  /// Set this from user settings, default `30` seconds
  static int lengthLimitMilliseconds = 30000;

  /// Get this from user settings, default `true`
  static bool autoPlayNewSong = true;

  static String getSortOptionString() {
    switch (currentSortOption) {
      case SortOptions.name:
        return 'Name';
      case SortOptions.mostPlayed:
        return 'Most played';
      case SortOptions.recentlyAdded:
        return 'Recently added';
    }
  }
}

enum SortOptions {
  name,
  mostPlayed,
  recentlyAdded,
}
