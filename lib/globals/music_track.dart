import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:path_provider/path_provider.dart';

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
  List<MusicTrack> storageSongs = await _getSongsFromStorage();

  List<MusicTrack>? savedSongs = await _getSavedMusicData();

  if (savedSongs != null) {
    debugPrint('Updating music data from saved');
    for (int i = 0; i < storageSongs.length; i++) {
      if (i >= savedSongs.length) break;

      final matchingSong = savedSongs.firstWhereOrNull(
        (element) => element.absolutePath == storageSongs[i].absolutePath,
      );

      if (matchingSong == null) continue;

      storageSongs[i]
        ..trackName = matchingSong.trackName
        ..artist = matchingSong.artist
        ..timeListened = matchingSong.timeListened;
    }
  }

  Globals.allSongs = storageSongs;
}

Future<List<MusicTrack>> _getSongsFromStorage() async {
  final downloadPath = Directory('/storage/emulated/0/Download');
  debugPrint('Getting music files from: ${downloadPath.path}');

  final allMp3 = downloadPath.listSync().where((file) => file.absolute.path.endsWith('.mp3'));
  List<FileSystemEntity> filteredList = [];

  if (Config.enableSongFiltering) {
    debugPrint('Filtering out song with length < ${Config.lengthLimitMilliseconds / 1000}s');
    for (var element in allMp3) {
      Metadata info = await MetadataRetriever.fromFile(File(element.absolute.path));
      if (info.trackDuration! >= Config.lengthLimitMilliseconds) {
        filteredList.add(element);
      }
    }
  }

  return filteredList.map((file) => MusicTrack(file.path)).toList();
}

Future<List<MusicTrack>?> _getSavedMusicData() async {
  File saveFile = File('${(await getExternalStorageDirectory())?.path}/tracks.json');

  if (!saveFile.existsSync()) return null;

  debugPrint('Getting saved music data from: ${saveFile.path}');
  return (jsonDecode(saveFile.readAsStringSync()) as List).map((e) => MusicTrack.fromJson(e)).toList();
}

Future<void> saveSongsToStorage() async {
  File saveFile = File('${(await getExternalStorageDirectory())?.path}/tracks.json');

  debugPrint('Saving updated music data to: ${saveFile.path}');
  saveFile.writeAsStringSync(jsonEncode(Globals.allSongs));
}

void sortAllSongs([SortOptions? sortType]) {
  debugPrint('Sorting all tracks: ${Config.currentSortOption.name}');
  Config.currentSortOption = sortType ?? Config.currentSortOption;
  switch (Config.currentSortOption) {
    case SortOptions.name:
      Globals.allSongs.sort((track1, track2) {
        return track1.trackName.toLowerCase().compareTo(track2.trackName.toLowerCase());
      });
      break;
    case SortOptions.mostPlayed:
      Globals.allSongs.sort((track1, track2) {
        return track2.timeListened.compareTo(track1.timeListened);
      });
      break;
    case SortOptions.recentlyAdded:
      Globals.allSongs.sort((track1, track2) {
        return track2.timeAdded.compareTo(track1.timeAdded);
      });
      break;
  }
}

void updateListOfArtists() {
  debugPrint('Getting list of artists');
  Set<String> uniqueArtists = <String>{};

  for (var element in Globals.allSongs) {
    uniqueArtists.add(element.artist);
  }

  uniqueArtists = SplayTreeSet.from(
    uniqueArtists,
    (key1, key2) => key1.toLowerCase().compareTo(key2.toLowerCase()),
  );

  Globals.artists = {
    for (var element in uniqueArtists)
      element: Globals.allSongs.where((song) => song.artist == element).length
  };
}
