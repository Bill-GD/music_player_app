import 'dart:async';

import '../player/player_utils.dart';
import 'music_track.dart';

final isDev = Globals.appVersion.contains('_dev_');
final devBuild = Globals.appVersion.split('_').last;

class Globals {
  /// List of all songs, persistent.
  static List<MusicTrack> allSongs = [];

  /// List of name and song count of artists.
  static Map<String, int> artists = {};

  /// List of name and song count of albums.
  static List<Album> albums = [];

  static late final AudioPlayerHandler audioHandler;

  static const String appName = 'Music Hub';
  static const String appVersion = String.fromEnvironment('VERSION', defaultValue: '0.0.0');

  /// Does the minimized player shows up?
  static bool showMinimizedPlayer = false;
  static bool setDuplicate = false;

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
  static const downloadPath = '/storage/emulated/0/Download/';
  static const lyricPath = '/storage/emulated/0/Lyrics/';

  static const githubToken = String.fromEnvironment('GITHUB_TOKEN');

  static final lyricChangedController = StreamController<void>.broadcast();
}
