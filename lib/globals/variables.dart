import 'package:package_info_plus/package_info_plus.dart';

import '../player/player_utils.dart';
import 'music_track.dart';

class Globals {
  /// List of all songs, persistent.
  static List<MusicTrack> allSongs = [];

  /// List of name and song count of artists.
  static Map<String, int> artists = {};

  static late final AudioPlayerHandler audioHandler;

  static late final PackageInfo packageInfo;

  /// Does the minimized player shows up?
  static bool showMinimizedPlayer = false;

  /// Path of the currently selected/playing song.
  static String currentSongPath = '';
}

// Configs
// Save these in config.json or something
/// All user configurations, expose to user in setting page.
class Config {
  /// Current sorting order of the song list, default [SortOptions.name].
  static SortOptions currentSortOption = SortOptions.name;

  /// Filters out all files shorter than this, default `30` seconds.
  static int lengthLimitMilliseconds = 30000;

  /// Should the player start when choosing a new song, default `true`.
  static bool autoPlayNewSong = true;

  /// The base volume of the player, default `1`. Range `[0.5, 5]`
  static double volume = 1;

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
