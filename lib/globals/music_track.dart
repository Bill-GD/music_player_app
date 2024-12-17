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
      Globals.songTable,
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
      Globals.songTable,
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
      Globals.songTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    await DatabaseHandler.db.delete(
      Globals.albumSongsTable,
      where: 'track_id = ?',
      whereArgs: [id],
    );
  }

  Future<void> removeFromPlaylist(int albumID) async {
    final res = await DatabaseHandler.db.query(
      Globals.albumSongsTable,
      where: 'track_id = ? and album_id = ?',
      whereArgs: [id, albumID],
    );
    await DatabaseHandler.db.delete(
      Globals.albumSongsTable,
      where: 'track_id = ? and album_id = ?',
      whereArgs: [id, albumID],
    );
    await DatabaseHandler.db.rawUpdate(
      'update ${Globals.albumSongsTable} '
      'set track_order = track_order - 1 '
      'where album_id = ? and track_order > ?',
      [albumID, res.first['track_order']],
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
      Globals.albumTable,
      {
        'name': name,
        'timeAdded': timeAdded.toIso8601String(),
      },
    );
    for (final si in songs) {
      await DatabaseHandler.db.insert(
        Globals.albumSongsTable,
        {
          'track_id': id,
          'album_id': si,
          'timeAdded': DateTime.now().toIso8601String(),
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
      Globals.albumTable,
      toJson(),
      where: 'id = ?',
      whereArgs: [id],
    );

    for (final i in range(0, songs.length - 1)) {
      // check if song is already in album
      final exists = (await DatabaseHandler.db.query(
        Globals.albumSongsTable,
        where: 'track_id = ? and album_id = ?',
        whereArgs: [songs[i], id],
      ))
          .isNotEmpty;
      if (exists) {
        await DatabaseHandler.db.update(
          Globals.albumSongsTable,
          {'track_order': i},
          where: 'track_id = ? and album_id = ?',
          whereArgs: [songs[i], id],
        );
        continue;
      }
      await DatabaseHandler.db.insert(Globals.albumSongsTable, {
        'track_order': i,
        'album_id': id,
        'track_id': songs[i],
      });
    }
  }

  Future<void> delete() async {
    if (id < 0) {
      LogHandler.log('Trying to delete album id (-1)', LogLevel.error);
      return;
    }
    await DatabaseHandler.db.delete(
      Globals.albumTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    final otherAlbums = Globals.albums.where((a) => a.id != 1 || a.id != id);
    final unknown = Globals.albums.firstWhere((e) => e.id == 1);

    for (final s in songs) {
      if (otherAlbums.any((a) => a.songs.contains(s)) || unknown.songs.contains(s)) continue;
      unknown.songs.add(s);
    }
    await unknown.update();
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
  final albums = (await DatabaseHandler.db.query(Globals.albumTable)).map(Album.fromJson).toList();

  for (final a in albums) {
    var s = await DatabaseHandler.db.query(
      Globals.albumSongsTable,
      where: 'album_id = ?',
      whereArgs: [a.id],
      columns: ['track_order', 'track_id'],
      orderBy: 'track_order',
    );
    LogHandler.log('$s');
    a.songs.addAll(s.map((a) => a['track_id'] as int));
  }
  albums.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  // LogHandler.log('${albums.map((e) => e.toJson())}');
  Globals.albums = albums;
}
