import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:music_player_app/globals/database_handler.dart';

import 'functions.dart';
import 'log_handler.dart';
import 'variables.dart';

class MusicTrack {
  int id;
  String path;
  String name, artist;
  int timeListened;
  DateTime timeAdded = DateTime.now();

  String get fullPath => Globals.downloadPath + path;

  MusicTrack(
    this.path, {
    this.id = -1,
    this.name = '',
    this.artist = 'Unknown',
    // this.album = 'Unknown',
    this.timeListened = 0,
    required this.timeAdded,
  }) {
    name = name.isEmpty ? path.split('/').last.split('.mp3').first : name;
  }

  MusicTrack.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        path = json['path'],
        name = json['name'] ?? json['path'].split('/').last.split('.mp3').first,
        artist = json['artist'] ?? 'Unknown',
        // album = json['album'] ?? 'Unknown',
        timeListened = json['timeListened'],
        timeAdded = json['timeAdded'] == null
            ? DateTime.parse(json['timeAdded'])
            : File('${Globals.downloadPath}${json['path']}').statSync().modified {
    // LogHandler.log('Time (fromJson): ${json['timeAdded']}');
  }

  MusicTrack.fromJsonString(String jsonString) : this.fromJson(jsonDecode(jsonString));

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'name': name,
        'artist': artist,
        // 'album': album,
        'timeListened': timeListened,
        'timeAdded': timeAdded.toIso8601String(),
      };

  Future<void> incrementTimePlayed() async {
    timeListened++;
    await update();
    LogHandler.log('Incremented play count');
  }

  Future<void> insert() async {
    if (id >= 0) {
      LogHandler.log('Trying to insert duplicate song id ($id)', LogLevel.error);
      return;
    }
    id = await DatabaseHandler.db.insert(
      'music_track',
      {
        'path': path,
        'name': name,
        'artist': artist,
        'timeListened': timeListened,
        'timeAdded': timeAdded.toIso8601String(),
      },
    );
  }

  Future<void> update() async {
    if (id < 0) {
      LogHandler.log('Trying to update song id (-1)', LogLevel.error);
      return;
    }
    await DatabaseHandler.db.update(
      'music_track',
      toJson(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete() async {
    if (id < 0) {
      LogHandler.log('Trying to delete song id (-1)', LogLevel.error);
      return;
    }
    await DatabaseHandler.db.delete(
      'music_track',
      where: 'id = ?',
      whereArgs: [id],
    );
    await DatabaseHandler.db.delete(
      'album_tracks',
      where: 'track_id = ?',
      whereArgs: [id],
    );
  }

  Future<void> removeFromPlaylist(int albumID) async {
    final res = await DatabaseHandler.db.query(
      'album_tracks',
      where: 'track_id = ?',
      whereArgs: [id],
    );
    if (res.length <= 1) {
      await DatabaseHandler.db.update(
        'album_tracks',
        {'album_id': 1},
        where: 'track_id = ?',
        whereArgs: [id],
      );
      return;
    }
    await DatabaseHandler.db.delete(
      'album_tracks',
      where: 'track_id = ? and album_id = ?',
      whereArgs: [id, albumID],
    );
  }
}

class Album {
  final int id;
  final String name;
  DateTime timeAdded;
  List<int> songs = [];

  Album({required this.name, this.id = -1, required this.timeAdded});

  Album.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        timeAdded = DateTime.parse(json['timeAdded']);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'timeAdded': timeAdded.toIso8601String(),
      };

  Future<void> insert() async {
    if (id >= 0) {
      LogHandler.log('Trying to insert duplicate album id ($id)', LogLevel.error);
      return;
    }
    await DatabaseHandler.db.insert(
      'album',
      {
        'name': name,
        'timeAdded': timeAdded.toIso8601String(),
      },
    );
    for (final si in songs) {
      await DatabaseHandler.db.insert(
        'album_tracks',
        {
          'track_id': id,
          'album_id': si,
        },
      );
    }
  }

  Future<void> update() async {
    if (id < 0) {
      LogHandler.log('Trying to update album id (-1)', LogLevel.error);
      return;
    }
    await DatabaseHandler.db.update(
      'album',
      toJson(),
      where: 'id = ?',
      whereArgs: [id],
    );

    for (final s in songs) {
      await DatabaseHandler.db.update(
        'album_tracks',
        {'album_id': id},
        where: 'track_id = ?',
        whereArgs: [s],
      );
    }
  }

  Future<void> delete() async {
    if (id < 0) {
      LogHandler.log('Trying to delete album id (-1)', LogLevel.error);
      return;
    }
    await DatabaseHandler.db.delete(
      'album',
      where: 'id = ?',
      whereArgs: [id],
    );
    await DatabaseHandler.db.update(
      'album_tracks',
      {'album_id': 1},
      where: 'album_id = ?',
      whereArgs: [id],
    );
  }
}

/// Get all songs (from storage & saved)
Future<void> updateMusicData() async {
  await updateListOfSongs();
  updateArtistsList();
  await updateAlbumList();
}

/// Updates all songs with saved data
Future<void> updateListOfSongs() async {
  List<MusicTrack> storageSongs = await _getSongsFromStorage();
  List<MusicTrack> savedSongs = await _getSavedMusicData();

  LogHandler.log('Updating music data from saved');
  for (int i = 0; i < storageSongs.length; i++) {
    final matchingSong = savedSongs.firstWhereOrNull(
      (e) => e.path == storageSongs[i].path,
    );

    if (matchingSong == null) continue;

    storageSongs[i]
      ..id = matchingSong.id
      ..name = matchingSong.name
      ..artist = matchingSong.artist
      ..timeListened = matchingSong.timeListened;
  }

  for (final s in storageSongs) {
    if (s.id >= 0) {
      await s.update();
    } else {
      LogHandler.log('Song ID: ${s.id} will be inserted');
      await s.insert();
    }
  }
  Globals.allSongs = storageSongs;
}

Future<List<MusicTrack>> _getSongsFromStorage() async {
  final downloadDir = Directory(Globals.downloadPath);
  LogHandler.log('Getting music files from: ${downloadDir.path}');
  final mp3Files = downloadDir.listSync().where((e) => e.path.endsWith('.mp3')).toList();
  final filteredFiles = <MusicTrack>[];

  if (!Config.enableSongFiltering) {
    return mp3Files.map((e) {
      return MusicTrack(
        e.path.split(Globals.downloadPath).last,
        timeAdded: e.statSync().modified,
      );
    }).toList();
  }

  LogHandler.log('Filtering out song with length < ${Config.lengthLimitMilliseconds ~/ 1000}s');
  for (final file in mp3Files) {
    final info = await MetadataRetriever.fromFile(File(file.path));
    if (info.trackDuration! >= Config.lengthLimitMilliseconds) {
      filteredFiles.add(MusicTrack(
        file.path.split(Globals.downloadPath).last,
        timeAdded: file.statSync().modified,
      ));
    }
  }
  return filteredFiles;
}

Future<List<MusicTrack>> _getSavedMusicData() async {
  LogHandler.log('Getting saved music data from database');
  final json = await DatabaseHandler.db.rawQuery(
    'select t.*, a.name album from music_track t '
    'inner join album_tracks at on t.id = at.track_id '
    'inner join album a on a.id = at.album_id;',
  );
  return json.map(MusicTrack.fromJson).toList();
}

void sortAllSongs([SortOptions? sortType]) {
  final tracks = List<MusicTrack>.from(Globals.allSongs);
  Config.currentSortOption = sortType ?? Config.currentSortOption;
  LogHandler.log('Sorting all tracks: ${Config.currentSortOption.name}');
  switch (Config.currentSortOption) {
    case SortOptions.name:
      tracks.sort((track1, track2) => track1.name.toLowerCase().compareTo(track2.name.toLowerCase()));
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
  LogHandler.log('Getting list of artists');
  final artists = <String, int>{}..addAll({
      for (final song in Globals.allSongs) //
        song.artist: Globals.allSongs.where((s) => s.artist == song.artist).length,
    });
  Globals.artists = SplayTreeMap.from(
    artists,
    (key1, key2) => key1.toLowerCase().compareTo(key2.toLowerCase()),
  );
}

Future<void> updateAlbumList() async {
  LogHandler.log('Getting list of albums');
  final albums = (await DatabaseHandler.db.query('album')).map(Album.fromJson).toList();

  for (final e in albums) {
    e.songs.addAll((await DatabaseHandler.db
            .query('album_tracks', where: 'album_id = ?', whereArgs: [e.id], columns: ['track_id']))
        .map((e) => e['track_id'] as int));
  }
  albums.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  // LogHandler.log('${albums.map((e) => e.toJson())}');
  Globals.albums = albums;
}
