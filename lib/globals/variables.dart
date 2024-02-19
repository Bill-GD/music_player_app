import 'package:just_audio/just_audio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../artists/music_track.dart';

List<MusicTrack> allMusicTracks = [];
Map<String, List<MusicTrack>> artists = {};
late final AudioPlayer audioPlayer;

late final PackageInfo packageInfo;
