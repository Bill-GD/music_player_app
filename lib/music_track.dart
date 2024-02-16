import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'main_screen/main_screen.dart';

class MusicTrack {
  String absolutePath;
  String trackName, artist;
  int timeListened;

  MusicTrack(
    this.absolutePath, {
    this.trackName = 'filename',
    this.artist = 'Unknown',
    this.timeListened = 0,
  }) {
    trackName = absolutePath.split('/').last.split('.mp3').first;
  }

  MusicTrack.fromJson(Map json)
      : absolutePath = json['absolutePath'],
        trackName = json['trackName'] ?? json['absolutePath'].split('/').last.split('.mp3').first,
        artist = json['artist'] ?? 'Unknown',
        timeListened = json['timeListened'];

  MusicTrack.fromJsonString(String jsonString) : this.fromJson(json.decode(jsonString));

  Map<String, dynamic> toJson() => {
        'absolutePath': absolutePath,
        'trackName': trackName,
        'artist': artist,
        'timeListened': timeListened,
      };
}

Future<List<MusicTrack>> getTrackFromStorage() async {
  final downloadPath = Directory('/storage/emulated/0/Download');
  debugPrint('Getting music files from: ${downloadPath.path}');

  List<MusicTrack> tracksFromStorage = downloadPath
      .listSync()
      .where((file) => file.path.endsWith('.mp3'))
      .map((file) => MusicTrack(file.path))
      .toList()
    ..sort((track1, track2) => track1.trackName.compareTo(track2.trackName));

  // if has save file, update from save data
  File saveFile = File('${(await getExternalStorageDirectory())?.path}/tracks.json');
  if (saveFile.existsSync()) {
    debugPrint('Getting saved music data from: ${saveFile.path}');
    List<MusicTrack> tracksFromSaved =
        (json.decode(saveFile.readAsStringSync()) as List).map((e) => MusicTrack.fromJson(e)).toList();

    debugPrint('Updating music data from saved');
    for (int i = 0; i < tracksFromStorage.length; i++) {
      if (i >= tracksFromStorage.length || i >= tracksFromSaved.length) {
        break;
      }
      tracksFromStorage[i] = tracksFromSaved
          .where(
            (element) => element.absolutePath == tracksFromStorage[i].absolutePath,
          )
          .first;
    }
  } else {
    // save to local if has no save file
    debugPrint('No save file detected');
    saveTracksToStorage(tracksFromStorage);
  }
  return tracksFromStorage;
}

void saveTracksToStorage(List<MusicTrack> allTracks) async {
  Directory? storagePath = await getExternalStorageDirectory();

  File saveFile = File('${storagePath?.path}/tracks.json');

  debugPrint('Saving music data to: ${saveFile.path}');
  saveFile.writeAsStringSync(jsonEncode(allMusicTracks));
}
