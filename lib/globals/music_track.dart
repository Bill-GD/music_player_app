import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';

import 'variables.dart';

class MusicTrack {
  String absolutePath;
  String trackName, artist, album;
  int timeListened;
  late DateTime timeAdded;

  MusicTrack(
    this.absolutePath, {
    this.trackName = '',
    this.artist = 'Unknown',
    this.album = 'Unknown',
    this.timeListened = 0,
  }) {
    trackName = trackName.isEmpty ? absolutePath.split('/').last.split('.mp3').first : trackName;
    timeAdded = File(absolutePath).statSync().modified;
  }

  MusicTrack.fromJson(Map json)
      : absolutePath = json['absolutePath'],
        trackName = json['trackName'] ?? json['absolutePath'].split('/').last.split('.mp3').first,
        artist = json['artist'] ?? 'Unknown',
        album = json['album'] ?? 'Unknown',
        timeListened = json['timeListened'],
        timeAdded = DateTime.parse(
            json['timeAdded'] ?? File(json['absolutePath']).statSync().modified.toIso8601String());

  MusicTrack.fromJsonString(String jsonString) : this.fromJson(json.decode(jsonString));

  Map<String, dynamic> toJson() => {
        'absolutePath': absolutePath,
        'trackName': trackName,
        'artist': artist,
        'album': album,
        'timeListened': timeListened,
        'timeAdded': timeAdded.toIso8601String(),
      };
}

/// Get all songs (from storage & saved)
Future<void> updateMusicData() async {
  await updateListOfSongs();
  updateArtistsList();
  updateAlbumList();
  saveSongsToStorage();
}

/// Updates all songs with saved data
Future<void> updateListOfSongs() async {
  List<MusicTrack> storageSongs = await _getSongsFromStorage();
  List<MusicTrack>? savedSongs = _getSavedMusicData();

  if (savedSongs != null) {
    debugPrint('Updating music data from saved');
    for (int i = 0; i < storageSongs.length; i++) {
      final matchingSong = savedSongs.firstWhereOrNull(
        (e) => e.absolutePath == storageSongs[i].absolutePath,
      );

      if (matchingSong == null) continue;

      storageSongs[i]
        ..trackName = matchingSong.trackName
        ..artist = matchingSong.artist
        ..album = matchingSong.album
        ..timeListened = matchingSong.timeListened;
    }
  }

  Globals.allSongs = storageSongs;
}

Future<List<MusicTrack>> _getSongsFromStorage() async {
  final downloadDir = Directory('/storage/emulated/0/Download');
  debugPrint('Getting music files from: ${downloadDir.path}');
  final mp3Files = downloadDir.listSync().where((e) => e.path.endsWith('.mp3')).toList();
  final filteredFiles = <MusicTrack>[];

  if (!Config.enableSongFiltering) {
    return mp3Files.map((e) => MusicTrack(e.path)).toList();
  }

  debugPrint('Filtering out song with length < ${Config.lengthLimitMilliseconds ~/ 1000}s');
  for (final file in mp3Files) {
    final info = await MetadataRetriever.fromFile(File(file.path));
    if (info.trackDuration! >= Config.lengthLimitMilliseconds) {
      filteredFiles.add(MusicTrack(file.path));
    }
  }

  return filteredFiles;
}

List<MusicTrack>? _getSavedMusicData() {
  final file = File('${Globals.storagePath}/tracks.json');
  if (!file.existsSync()) return null;

  debugPrint('Getting saved music data from: ${file.path}');
  final List json = jsonDecode(file.readAsStringSync());
  return json.map((e) => MusicTrack.fromJson(e)).toList();
}

void saveSongsToStorage() {
  File saveFile = File('${Globals.storagePath}/tracks.json');

  debugPrint('Saving updated music data to: ${saveFile.path}');
  saveFile.writeAsStringSync(jsonEncode(Globals.allSongs));
}

void sortAllSongs([SortOptions? sortType]) {
  final tracks = List<MusicTrack>.from(Globals.allSongs);
  Config.currentSortOption = sortType ?? Config.currentSortOption;
  debugPrint('Sorting all tracks: ${Config.currentSortOption.name}');
  switch (Config.currentSortOption) {
    case SortOptions.name:
      tracks
          .sort((track1, track2) => track1.trackName.toLowerCase().compareTo(track2.trackName.toLowerCase()));
      break;
    case SortOptions.mostPlayed:
      tracks.sort((track1, track2) => track2.timeListened.compareTo(track1.timeListened));
      break;
    case SortOptions.recentlyAdded:
      tracks.sort((track1, track2) => track2.timeAdded.compareTo(track1.timeAdded));
      break;
  }
  Globals.allSongs = tracks;
}

void updateArtistsList() {
  debugPrint('Getting list of artists');
  final artists = <String, int>{}..addAll({
      for (final song in Globals.allSongs)
        song.artist: Globals.allSongs.where((s) => s.artist == song.artist).length,
    });
  Globals.artists = SplayTreeMap.from(
    artists,
    (key1, key2) => key1.toLowerCase().compareTo(key2.toLowerCase()),
  );
}

void updateAlbumList() {
  debugPrint('Getting list of albums');
  final albums = <String, int>{}..addAll({
      for (final song in Globals.allSongs)
        song.album: Globals.allSongs.where((s) => s.album == song.album).length,
    });
  Globals.albums = SplayTreeMap.from(
    albums,
    (key1, key2) => key1.toLowerCase().compareTo(key2.toLowerCase()),
  );
}
