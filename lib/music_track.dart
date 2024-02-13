import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

class MusicTrack {
  String absolutePath;
  String trackName, artist;
  bool isFavorite;
  int timeListened;

  /// [absolutePath] is required.<br>
  /// [trackName], [artist], [isFavorite] and [timeListened] are optional.<br>
  ///
  /// `trackName`: Defaults to the name of the file, excluding extension.<br>
  /// `artist`: Defaults to `Unknown`.<br>
  /// `isFavorite`: Defaults to `false`.<br>
  /// `timeListened`: Defaults to `0`.<br>
  MusicTrack(
    this.absolutePath, {
    this.trackName = 'filename',
    this.artist = 'Unknown',
    this.isFavorite = false,
    this.timeListened = 0,
  }) {
    trackName = absolutePath.split(RegExp('/')).last.split('.').first;
  }

  MusicTrack.fromJson(Map json)
      : absolutePath = json['absolutePath'],
        trackName = json['trackName'] ?? json['absolutePath'].split(RegExp('/')).last.split('.').first,
        artist = json['artist'] ?? 'Unknown',
        isFavorite = json['isFavorite'],
        timeListened = json['timeListened'];

  MusicTrack.fromJsonString(String jsonString) : this.fromJson(json.decode(jsonString));

  Map<String, dynamic> toJson() => {
        'absolutePath': absolutePath,
        'trackName': trackName,
        'artist': artist,
        'isFavorite': isFavorite,
        'timeListened': timeListened
      };

  bool compareTrackPath(MusicTrack other) => absolutePath == other.absolutePath;
  bool comparePath(String otherPath) => absolutePath == otherPath;
}

Future<List<MusicTrack>> getTrackFromStorage() async {
  final downloadPath = Directory('/storage/emulated/0/Download');
  debugPrint('Getting music files from: ${downloadPath.path}');
  return downloadPath
      .listSync()
      .where((file) => file.path.endsWith('.mp3'))
      .map((file) => MusicTrack(file.path))
      .toList();
}
