import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_media_metadata/flutter_media_metadata.dart';

import '../handlers/database_handler.dart';
import '../handlers/log_handler.dart';
import 'extensions.dart';
import 'utils.dart';
import 'variables.dart';

class MusicTrack {
  int id, timeListened;
  String path, name, artist, lyricPath;
  DateTime timeAdded = DateTime.now();
  bool hasAlbum = false;

  String get fullPath => Globals.downloadPath + path;

  MusicTrack(
    this.path, {
    this.id = -1,
    this.name = '',
    this.artist = 'Unknown',
    this.timeListened = 0,
    this.lyricPath = '',
    required this.timeAdded,
  }) {
    name = name.isEmpty ? path.split('/').last.split('.mp3').first : name;
  }

  MusicTrack.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        path = json['path'],
        name = json['name'] ?? json['path'].split('/').last.split('.mp3').first,
        artist = json['artist'] ?? 'Unknown',
        timeListened = json['timeListened'] ?? json['time_listened'] ?? 0,
        lyricPath = json['lyric_path'] ?? '',
        timeAdded = json['time_added'] != null
            ? DateTime.parse(json['time_added'])
            : File('${Globals.downloadPath}${json['path']}').statSync().modified;

  MusicTrack.fromJsonString(String jsonString) : this.fromJson(jsonDecode(jsonString));

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'name': name,
        'artist': artist,
        'time_listened': timeListened,
        'lyric_path': lyricPath,
        'time_added': timeAdded.toIso8601String(),
      };

  Future<void> incrementTimePlayed() async {
    timeListened++;
    LogHandler.log('Play count +1 for ($id)');
    await update(false);
  }

  Future<void> insert() async {
    if (id >= 0) {
      return LogHandler.log('Trying to insert duplicate song id ($id)', LogLevel.error);
    }
    id = await DatabaseHandler.db.insert(
      Globals.songTable,
      toJson()..remove('id'),
      // {
      //   'path': path,
      //   'name': name,
      //   'artist': artist,
      //   'time_listened': timeListened,
      //   'lyric_path': lyricPath,
      //   'time_added': timeAdded.toIso8601String(),
      // },
    );
    LogHandler.log('Inserted song -> new id: $id');
  }

  Future<void> update([bool log = true]) async {
    if (id < 0) {
      return LogHandler.log('Trying to update song id -1', LogLevel.error);
    }
    if (log) LogHandler.log('Updating song: $id');
    await DatabaseHandler.db.update(
      Globals.songTable,
      toJson(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete() async {
    if (id < 0) {
      return LogHandler.log('Trying to delete song id -1', LogLevel.error);
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
    LogHandler.log('Deleting song: $id');
  }

  Future<void> removeFromPlaylist(int albumID) async {
    LogHandler.log('Removing song ($id) from album ($albumID)');

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

    final otherAlbums = Globals.albums.where((a) => a.id != 1 && a.id != albumID);
    final unknown = Globals.albums.firstWhere((e) => e.id == 1);

    if (otherAlbums.any((a) => a.songs.contains(id)) || unknown.songs.contains(id)) return;
    unknown.songs.add(id);
    await unknown.update();
  }
}

class Album {
  int id;
  String name;
  DateTime timeAdded;
  List<int> songs = [];

  Album({required this.name, this.id = -1, required this.timeAdded});

  Album.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? -1,
        name = json['name'],
        timeAdded = DateTime.parse(json['time_added']);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'time_added': timeAdded.toIso8601String(),
      };

  Future<void> insert() async {
    if (id >= 0) {
      return LogHandler.log('Trying to insert duplicate album id ($id)', LogLevel.error);
    }
    id = await DatabaseHandler.db.insert(
      Globals.albumTable,
      {
        'name': name,
        'time_added': timeAdded.toIso8601String(),
      },
    );
    LogHandler.log('Inserted album -> new id: $id');
    for (final i in range(0, songs.length - 1)) {
      await DatabaseHandler.db.insert(
        Globals.albumSongsTable,
        {
          'track_order': i,
          'track_id': songs[i],
          'album_id': id,
        },
      );
    }
  }

  Future<void> update() async {
    if (id < 0) {
      return LogHandler.log('Trying to update album id -1', LogLevel.error);
    }
    LogHandler.log('Update album ($id)');

    await DatabaseHandler.db.update(
      Globals.albumTable,
      toJson(),
      where: 'id = ?',
      whereArgs: [id],
    );

    await DatabaseHandler.db.delete(
      Globals.albumSongsTable,
      where: 'album_id = ?',
      whereArgs: [id],
    );

    for (final i in range(0, songs.length - 1)) {
      await DatabaseHandler.db.insert(Globals.albumSongsTable, {
        'track_order': i,
        'album_id': id,
        'track_id': songs[i],
      });
    }
  }

  Future<void> delete() async {
    if (id < 0) {
      return LogHandler.log('Trying to delete album id -1', LogLevel.error);
    }
    LogHandler.log('Deleting album ($id)');
    await DatabaseHandler.db.delete(
      Globals.albumTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    await DatabaseHandler.db.delete(
      Globals.albumSongsTable,
      where: 'album_id = ?',
      whereArgs: [id],
    );

    final otherAlbums = Globals.albums.where((a) => a.id != 1 && a.id != id);
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
      ..timeListened = matchingSong.timeListened
      ..lyricPath = matchingSong.lyricPath;
  }

  final updateCount = storageSongs.where((e) => e.id >= 0).length;
  final insertCount = storageSongs.length - updateCount;

  LogHandler.log('Finishing getting songs: $updateCount updates, $insertCount inserts');
  for (final s in storageSongs) {
    if (s.id >= 0) {
      await s.update(false);
    } else {
      await s.insert();
    }
  }
  Globals.allSongs = storageSongs;
}

Future<List<MusicTrack>> _getSongsFromStorage() async {
  final downloadDir = Directory(Globals.downloadPath);
  LogHandler.log('Getting mp3 files from: ${downloadDir.path}');
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

  LogHandler.log('Filtering songs shorter than ${Config.lengthLimitMilliseconds ~/ 1000}s');
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
  LogHandler.log('Getting data from database');
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
  LogHandler.log('Sorting all songs: ${Config.currentSortOption.name}');
  switch (Config.currentSortOption) {
    case SortOptions.id:
      tracks.sort((track1, track2) => track1.id.compareTo(track2.id));
      break;
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
  LogHandler.log('Updating artist list');
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
  LogHandler.log('Updating album list');
  final albums = (await DatabaseHandler.db.query(Globals.albumTable)).map(Album.fromJson).toList();

  if (albums.isEmpty) {
    LogHandler.log("No album exists, creating default album 'Unknown'");
    final unknown = Album(name: 'Unknown', id: -1, timeAdded: DateTime.now())
      ..songs = Globals.allSongs.map((e) => e.id).toList()
      ..insert();
    Globals.albums = [unknown];
    return;
  }

  for (final a in albums) {
    var s = await DatabaseHandler.db.query(
      Globals.albumSongsTable,
      where: 'album_id = ?',
      whereArgs: [a.id],
      columns: ['track_order', 'track_id'],
      orderBy: 'track_order',
    );
    // LogHandler.log('$s');
    final idList = s.map((e) => e['track_id'] as int).where((e) => hasSong(e));
    for (final id in idList) {
      final addingSongIdx = Globals.allSongs.indexWhere((e) => e.id == id);
      if (addingSongIdx < 0 || Globals.allSongs[addingSongIdx].hasAlbum) continue;
      Globals.allSongs[addingSongIdx].hasAlbum = true;
    }
    a.songs.addAll(idList);
    LogHandler.log('Got album: id=${a.id}, n=${a.name}, l=${a.songs.length}, s=${a.songs}');
  }

  albums.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  final noAlbumSongs = Globals.allSongs.where((e) => !e.hasAlbum);
  final unknown = albums.firstWhereOrNull((a) => a.id == 1);
  if (unknown != null) {
    for (final e in noAlbumSongs) {
      // LogHandler.log('Adding song (${e.id}) to Unknown album');
      e.hasAlbum = true;
      unknown.songs.add(e.id);
    }
    unknown.update();
  }

  Globals.albums = albums;
}
