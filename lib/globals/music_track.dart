import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:path_provider/path_provider.dart';

import 'config.dart';
import 'variables.dart';

class MusicTrack {
  String absolutePath;
  String trackName, artist;
  int timeListened;
  late DateTime timeAdded;

  MusicTrack(
    this.absolutePath, {
    this.trackName = '',
    this.artist = 'Unknown',
    this.timeListened = 0,
  }) {
    trackName = trackName.isEmpty ? absolutePath.split('/').last.split('.mp3').first : trackName;
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
}

/// Get all songs (from storage & saved)
Future<void> updateMusicData() async {
  await updateListOfSongs();
  updateListOfArtists();
  await saveSongsToStorage();
}

/// Updates all songs with saved data
Future<void> updateListOfSongs() async {
  List<MusicTrack> tracksFromStorage = await _getSongsFromStorage();

  List<MusicTrack>? savedTracks = await _getSavedMusicData();

  if (savedTracks != null) {
    debugPrint('Updating music data from saved');
    for (int i = 0; i < tracksFromStorage.length; i++) {
      if (i >= savedTracks.length) break;

      final matchingTrack = savedTracks.firstWhereOrNull(
        (element) => element.absolutePath == tracksFromStorage[i].absolutePath,
      );

      if (matchingTrack == null) continue;

      tracksFromStorage[i]
        ..trackName = matchingTrack.trackName
        ..artist = matchingTrack.artist
        ..timeListened = matchingTrack.timeListened;
    }
  }

  allMusicTracks = tracksFromStorage;
}

Future<List<MusicTrack>> _getSongsFromStorage() async {
  final downloadPath = Directory('/storage/emulated/0/Download');
  debugPrint('Getting music files from: ${downloadPath.path}');

  final allMp3 = downloadPath.listSync().where((file) => file.absolute.path.endsWith('.mp3'));
  List<FileSystemEntity> filteredList = [];

  debugPrint('Filtering out song with length < ${lengthLimitMilliseconds / 1000}s');
  for (var element in allMp3) {
    Metadata info = await MetadataRetriever.fromFile(File(element.absolute.path));
    if (info.trackDuration! > lengthLimitMilliseconds) {
      filteredList.add(element);
    }
  }

  return filteredList.map((file) => MusicTrack(file.path)).toList();
}

Future<List<MusicTrack>?> _getSavedMusicData() async {
  File saveFile = File('${(await getExternalStorageDirectory())?.path}/tracks.json');

  if (!saveFile.existsSync()) return null;

  debugPrint('Getting saved music data from: ${saveFile.path}');
  return (json.decode(saveFile.readAsStringSync()) as List).map((e) => MusicTrack.fromJson(e)).toList();
}

Future<void> saveSongsToStorage() async {
  File saveFile = File('${(await getExternalStorageDirectory())?.path}/tracks.json');

  debugPrint('Saving updated music data to: ${saveFile.path}');
  saveFile.writeAsStringSync(jsonEncode(allMusicTracks));
}

void sortAllSongs([SortOptions? sortType]) {
  debugPrint('Sorting all tracks: ${currentSortOption.name}');
  currentSortOption = sortType ?? currentSortOption;
  switch (currentSortOption) {
    case SortOptions.name:
      allMusicTracks.sort((track1, track2) {
        return track1.trackName.toLowerCase().compareTo(track2.trackName.toLowerCase());
      });
      break;
    case SortOptions.mostPlayed:
      allMusicTracks.sort((track1, track2) {
        return track2.timeListened.compareTo(track1.timeListened);
      });
      break;
    case SortOptions.recentlyAdded:
      allMusicTracks.sort((track1, track2) {
        return track2.timeAdded.compareTo(track1.timeAdded);
      });
      break;
  }
}

void updateListOfArtists() {
  debugPrint('Getting list of artists');
  Set<String> uniqueArtists = <String>{};

  for (var element in allMusicTracks) {
    uniqueArtists.add(element.artist);
  }

  uniqueArtists = SplayTreeSet.from(
    uniqueArtists,
    (key1, key2) => key1.toLowerCase().compareTo(key2.toLowerCase()),
  );

  artists = {
    for (var element in uniqueArtists) element: allMusicTracks.where((song) => song.artist == element).length
  };
}
