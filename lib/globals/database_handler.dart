import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';

import 'functions.dart';
import 'log_handler.dart';
import 'variables.dart';

class DatabaseHandler {
  static final String _path = Globals.dbPath;
  static late final Database _db;

  static Database get db => _db;

  static Future<void> init() async {
    final dbFile = File(_path);
    if (!dbFile.existsSync()) dbFile.createSync(recursive: true);

    _db = await openDatabase(
      _path,
      // prev = none
      version: 1,
      readOnly: false,
      onCreate: (db, __) async {
        await _createTables(db);
        await _migrateOldData(db);
        LogHandler.log('Song count: ${(await db.rawQuery('select count(*) count from music_track')).first['count']}');
      },
      onUpgrade: (db, oldVersion, newVersion) async {},
      onOpen: (db) async {
        LogHandler.log('Database opened');
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    await db.execute(
      'create table if not exists ${Globals.songTable} ('
      'id integer primary key,'
      'path text not null,' // the path is relative to /storage/emulated/0/Download, basically the file name only
      'name text not null,'
      'artist text not null,'
      'timeListened integer default 0,'
      'timeAdded datetime not null'
      ');',
    );
    await db.execute(
      'create table if not exists ${Globals.albumTable} ('
      'id integer primary key,'
      'name text not null,'
      'timeAdded datetime not null'
      ');',
    );
    await db.execute(
      'create table if not exists ${Globals.albumSongsTable} ('
      'track_order integer not null,'
      'track_id integer not null,'
      'album_id integer not null,'
      'primary key (track_order, track_id, album_id),'
      'foreign key (track_id) references music_track (id),'
      'foreign key (album_id) references album (id)'
      ');',
    );
  }

  static Future<void> _migrateOldData(Database db) async {
    final jsonFile = File(Globals.jsonPath);
    if (!jsonFile.existsSync()) return;

    LogHandler.log('Migrating old json data');

    final List json = jsonDecode(jsonFile.readAsStringSync());

    final albumCount = <String, int>{};

    for (final t in json) {
      albumCount[t['album']] ??= 0;
      albumCount[t['album']] = albumCount[t['album']]! + 1;
    }

    for (final albumName in albumCount.keys) {
      final songList = json.where((e) => (e['album'] ?? 'Unknown') == albumName).toList();

      for (final i in range(0, songList.length - 1)) {
        final relPath = (songList[i]['absolutePath'] as String).split(Globals.downloadPath).last;

        final trackID = await db.insert(Globals.songTable, <String, dynamic>{
          'path': relPath,
          'name': songList[i]['trackName'] ?? relPath.split('.mp3').first,
          'artist': songList[i]['artist'] ?? 'Unknown',
          'timeListened': songList[i]['timeListened'],
          'timeAdded':
              songList[i]['timeAdded'] ?? File(songList[i]['absolutePath']).statSync().modified.toIso8601String(),
        });

        final res = await db.query(
          Globals.albumTable,
          where: 'name = ?',
          whereArgs: [songList[i]['album'] ?? 'Unknown'],
        );

        final hasAlbum = res.isNotEmpty;
        int albumID;

        if (hasAlbum) {
          albumID = res.first['id'] as int;
        } else {
          albumID = await db.insert(Globals.albumTable, <String, dynamic>{
            'name': songList[i]['album'] ?? 'Unknown',
            'timeAdded': DateTime.now().toIso8601String(),
          });
        }

        await db.insert(Globals.albumSongsTable, <String, dynamic>{
          'track_order': i,
          'track_id': trackID,
          'album_id': albumID,
        });
      }
    }
    LogHandler.log('Finished migrating old json data');
    // jsonFile.deleteSync(); // not deleting this yet
  }
}
