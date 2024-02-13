import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

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
