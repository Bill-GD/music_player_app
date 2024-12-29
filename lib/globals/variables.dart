import 'package:shared_preferences/shared_preferences.dart';

import '../player/player_utils.dart';
import 'log_handler.dart';
import 'music_track.dart';

class Globals {
  /// List of all songs, persistent.
  static List<MusicTrack> allSongs = [];

  /// List of name and song count of artists.
  static Map<String, int> artists = {};

  /// List of name and song count of albums.
  static List<Album> albums = [];

  static late final AudioPlayerHandler audioHandler;

  static late final String appName;
  static late final String appVersion;

  /// Does the minimized player shows up?
  static bool showMinimizedPlayer = false;

  /// ID of the currently selected/playing song.
  static int currentSongID = -1;

  static String? savedPlaylistName;

  static const String songTable = 'music_track';
  static const String albumTable = 'album';
  static const String albumSongsTable = 'album_tracks';
  static const String playlistTable = 'playlist';

  /// The path to the app's storage directory.
  static late final String storagePath;
  static late final String jsonPath;
  static late final String dbPath;
  static late final String logPath;
  static late final String backupPath;

  /// The path to the app's storage directory.
  static const String downloadPath = '/storage/emulated/0/Download/';
}

// Configs
// Save these in config.json or something
/// All user configurations, expose to user in setting page.
class Config {
  /// Current sorting order of the song list, default [SortOptions.name].
  static SortOptions currentSortOption = SortOptions.name;

  /// Should filtering out all short files.
  static bool enableSongFiltering = true;

  /// Filters out all files shorter than this, default `30` seconds.
  static int lengthLimitMilliseconds = 30000;

  /// Should the player start when choosing a new song, default `true`.
  static bool autoPlayNewSong = true;

  /// The base volume of the player, default `1`. Range `[0, 1]`.
  static double volume = 1;

  /// The delay between song changes, default `0` milliseconds. Range `[0, 500]`.
  static int delayMilliseconds = 0;

  /// Whether the app should backup data on launch.
  static bool backupOnLaunch = false;

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

  static Future<void> saveConfig() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('currentSortOption', currentSortOption.name);
    await prefs.setBool('enableSongFiltering', enableSongFiltering);
    await prefs.setInt('lengthLimitSecond', (lengthLimitMilliseconds / 1000).round());
    await prefs.setBool('autoPlayNewSong', autoPlayNewSong);
    await prefs.setDouble('volume', volume);
    await prefs.setInt('delayMilliseconds', delayMilliseconds);
    await prefs.setBool('backupOnLaunch', backupOnLaunch);
    await prefs.setBool('isShuffled', Globals.audioHandler.isShuffled);
    await prefs.setString('repeatMode', Globals.audioHandler.repeatMode.name);
    LogHandler.log('Config saved');
  }

  static Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();

    currentSortOption = SortOptions.values.firstWhere(
      (option) => option.name == prefs.getString('currentSortOption'),
      orElse: () => SortOptions.name,
    );

    enableSongFiltering = prefs.getBool('enableSongFiltering') ?? true;
    lengthLimitMilliseconds = (prefs.getInt('lengthLimitSecond') ?? 30) * 1000;
    autoPlayNewSong = prefs.getBool('autoPlayNewSong') ?? true;
    volume = (prefs.getDouble('volume') ?? 1).clamp(0, 1);
    delayMilliseconds = prefs.getInt('delayMilliseconds') ?? 0;
    backupOnLaunch = prefs.getBool('backupOnLaunch') ?? false;

    Globals.audioHandler.loadConfig(
      prefs.getBool('isShuffled'),
      prefs.getString('repeatMode'),
    );
    LogHandler.log('Config loaded');
  }
}

enum SortOptions {
  name,
  mostPlayed,
  recentlyAdded,
}
