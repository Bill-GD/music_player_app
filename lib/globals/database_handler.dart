import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';

import 'log_handler.dart';
import 'variables.dart';

class DatabaseHandler {
  static final String _path = Globals.dbPath;
  static late final Database _db;

  static Database get db => _db;

  static Future<void> init() async {
    // if (await databaseExists(_path)) {
    _db = await openDatabase(
      _path,
      version: 1, // prev = none
      onCreate: (db, __) async {
        await _createTables(db);
        await _migrateOldData(db);
        LogHandler.log('Song count: ${await db.rawQuery('select count(*) from music_track')}');
      },
      onUpgrade: (db, oldVersion, newVersion) async {},
      onOpen: (db) async {
        LogHandler.log('Database opened');
      },
    );
    // } else {
    //   LogHandler.log('Database doesnt exist', LogLevel.error);
    // }
  }

  static Future<void> _createTables(Database db) async {
    await db.execute(
      'create table if not exists music_track ('
      'id integer primary key,'
      'path text not null,' // the path is relative to /storage/emulated/0/Download, basically the file name only
      'name text not null,'
      'artist text not null,'
      'timeListened integer default 0,'
      'timeAdded datetime'
      ');',
    );
    await db.execute(
      'create table if not exists album ('
      'id integer primary key,'
      'name text not null,'
      'timeAdded datetime'
      ');',
    );
    await db.execute(
      'create table if not exists album_tracks ('
      'track_id integer not null,'
      'album_id integer not null,'
      'primary key (track_id, album_id),'
      'foreign key (track_id) references music_track (id) on delete cascade,'
      'foreign key (album_id) references album (id) on delete cascade'
      ');',
    );
  }

  // static Future<void> _dropTables(Database db) async {
  //   await db.execute('drop table music_track; drop table album; drop table album_tracks;');
  // }

  static Future<void> _migrateOldData(Database db) async {
    LogHandler.log('Migrating old json data');

    final jsonFile = File(Globals.jsonPath);
    if (!jsonFile.existsSync()) return;

    final List json = jsonDecode(jsonFile.readAsStringSync());

    for (final t in json) {
      final relPath = (t['absolutePath'] as String).split(Globals.downloadPath).last;
      final trackID = await db.insert('music_track', <String, dynamic>{
        'path': relPath,
        'name': t['trackName'] ?? relPath.split('.mp3').first,
        'artist': t['artist'] ?? 'Unknown',
        'timeListened': t['timeListened'],
        'timeAdded': t['timeAdded'] ?? File(t['absolutePath']).statSync().modified.toIso8601String(),
      });
      final albumID = await db.insert('album', <String, dynamic>{
        'name': t['album'] ?? 'Unknown',
        'timeAdded': DateTime.now().toIso8601String(),
      });
      await db.insert('album_tracks', <String, dynamic>{
        'track_id': trackID,
        'album_id': albumID,
      });
    }
    LogHandler.log('Finished migrating old json data');
    jsonFile.deleteSync();
  }
}
