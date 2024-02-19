import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'globals/config.dart';
import 'globals/variables.dart';

class MusicTrack {
  String absolutePath;
  String trackName, artist;
  int timeListened;
  late DateTime timeAdded;

  MusicTrack(
    this.absolutePath, {
    this.trackName = 'filename',
    this.artist = 'Unknown',
    this.timeListened = 0,
  }) {
    trackName = absolutePath.split('/').last.split('.mp3').first;
    timeAdded = File(absolutePath).statSync().modified;
  }

  MusicTrack.fromJson(Map json)
      : absolutePath = json['absolutePath'],
        trackName = json['trackName'] ?? json['absolutePath'].split('/').last.split('.mp3').first,
        artist = json['artist'] ?? 'Unknown',
        timeListened = json['timeListened'],
        timeAdded = DateTime.parse(
            json['timeAdded'] ?? File(json['absolutePath']).statSync().modified.toIso8601String());

  MusicTrack.fromJsonString(String jsonString) : this.fromJson(json.decode(jsonString));

  Map<String, dynamic> toJson() => {
        'absolutePath': absolutePath,
        'trackName': trackName,
        'artist': artist,
        'timeListened': timeListened,
        'timeAdded': timeAdded.toIso8601String(),
      };

  MusicTrack copyWith({String? trackName, String? artist, int? timeListened}) {
    var newTrack = MusicTrack(
      absolutePath,
      trackName: trackName ?? this.trackName,
      artist: artist ?? this.artist,
      timeListened: timeListened ?? this.timeListened,
    )..timeAdded = timeAdded;
    return newTrack;
  }
}

/// Get all songs (from storage & saved)
Future<void> getMusicData() async => await _getTrackFromStorage();

Future<void> _getTrackFromStorage() async {
  final downloadPath = Directory('/storage/emulated/0/Download');
  debugPrint('Getting music files from: ${downloadPath.path}');

  // get all mp3 files from storage & sort by name
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
    List<MusicTrack> savedTracks =
        (json.decode(saveFile.readAsStringSync()) as List).map((e) => MusicTrack.fromJson(e)).toList();

    debugPrint('Updating music data from saved');
    for (int i = 0; i < tracksFromStorage.length; i++) {
      if (i >= tracksFromStorage.length || i >= savedTracks.length) {
        break;
      }

      final matchingTracks = savedTracks.where(
        (element) => element.absolutePath == tracksFromStorage[i].absolutePath,
      );

      if (matchingTracks.isEmpty) {
        continue;
      }

      tracksFromStorage[i] = tracksFromStorage[i].copyWith(
        trackName: matchingTracks.first.trackName,
        artist: matchingTracks.first.artist,
        timeListened: matchingTracks.first.timeListened,
      );
    }
  }

  allMusicTracks = tracksFromStorage;
  saveTracksToStorage();
  _groupMusicByArtist(); // get artists
  sortAllTracks();
}

void saveTracksToStorage() async {
  File saveFile = File('${(await getExternalStorageDirectory())?.path}/tracks.json');

  debugPrint('Saving updated music data to: ${saveFile.path}');
  saveFile.writeAsStringSync(jsonEncode(allMusicTracks));
}

void sortAllTracks([SortOptions? sortType]) {
  currentSortOption = sortType ?? currentSortOption;
  switch (currentSortOption) {
    case SortOptions.name:
      _sortMusicByName();
      break;
    case SortOptions.mostPlayed:
      _sortMusicByTimesListened();
      break;
    case SortOptions.recentlyAdded:
      _sortMusicByTimeAdded();
      break;
  }
}

void _sortMusicByName({bool ascending = true}) {
  allMusicTracks
      .sort((track1, track2) => track1.trackName.compareTo(track2.trackName) * (ascending ? 1 : -1));
}

void _sortMusicByTimesListened({bool ascending = false}) {
  allMusicTracks
      .sort((track1, track2) => track1.timeListened.compareTo(track2.timeListened) * (ascending ? 1 : -1));
}

void _sortMusicByTimeAdded({bool ascending = false}) {
  allMusicTracks
      .sort((track1, track2) => track1.timeAdded.compareTo(track2.timeAdded) * (ascending ? 1 : -1));
}

void _groupMusicByArtist() {
  artists = Map.fromEntries(
    groupBy(
      allMusicTracks,
      (element) => element.artist,
    ).entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key)),
  );
}
