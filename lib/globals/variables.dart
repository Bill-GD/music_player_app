import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../player/player_utils.dart';
import 'music_track.dart';

/// List of all songs, persistent
List<MusicTrack> allMusicTracks = [];

/// List of name and song count of artists
Map<String, int> artists = {};
late final AudioPlayer audioPlayer;

late final PackageInfo packageInfo;

bool showMinimizedPlayer = false;

String currentSongPath = '';

late final MyAudioHandler audioHandler;
