import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';

import 'log_handler.dart';
import '../globals/utils.dart';
import '../globals/variables.dart';

class DatabaseHandler {
  static final String _path = Globals.dbPath;
  static late final Database _db;

  static Database get db => _db;

  static Future<void> init() async {
    final dbFile = File(_path);
    if (!dbFile.existsSync()) dbFile.createSync(recursive: true);

    _db = await openDatabase(
      _path,
      // prev = 2
      version: 3,
      readOnly: false,
      onCreate: (db, version) async {
        LogHandler.log('Creating tables');
        await _createTables(db, version);
        await _migrateOldData(db);
        LogHandler.log('Song count: ${(await db.rawQuery('select count(*) count from music_track')).first['count']}');
      },
      onUpgrade: (db, _, newVersion) async {
        LogHandler.log('Upgrading database to version $newVersion');
        await _createTables(db, newVersion);
        await updateTables(db, newVersion);
      },
      onOpen: (db) async {
        LogHandler.log('Database opened');
      },
    );
  }

  static Future<void> _createTables(Database db, [int newVersion = 1]) async {
    await db.execute(
      'create table if not exists ${Globals.songTable} ('
      'id integer primary key,'
      'path text not null,' // the path is relative to /storage/emulated/0/Download, basically the file name only
      'name text not null,'
      'artist text not null,'
      'time_listened integer default 0,'
      '${newVersion >= 3 ? 'lyric_path text not null default "",' : ''}'
      'time_added datetime not null'
      ');',
    );
    await db.execute(
      'create table if not exists ${Globals.albumTable} ('
      'id integer primary key,'
      'name text not null,'
      'time_added datetime not null'
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
    if (newVersion <= 1) return;

    if (newVersion >= 2) {
      LogHandler.log("Creating '${Globals.playlistTable}' table");
      await db.execute(
        'create table if not exists ${Globals.playlistTable} ('
        'id integer primary key,'
        'list_name text not null,'
        'song_id integer not null,'
        'is_current integer not null default 0'
        ');',
      );
    }
  }

  static Future<void> updateTables(Database db, int newVersion) async {
    if (newVersion >= 3) {
      LogHandler.log('Adding lyric_path column to ${Globals.songTable}');
      await db.execute('alter table ${Globals.songTable} add column lyric_path text not null default "";');
      // rename these columns: timeAdded -> time_added, timeListened -> time_listened of Globals.songTable
      await db.execute('alter table ${Globals.songTable} rename column "timeAdded" to "time_added";');
      await db.execute('alter table ${Globals.songTable} rename column "timeListened" to "time_listened";');
      await db.execute('alter table ${Globals.albumTable} rename column "timeAdded" to "time_added";');
    }
  }

  static Future<void> clearAllData() async {
    LogHandler.log('IMPORTANT! Deleting all data! This is irreversible if used without backing up first!');
    await _db.delete(Globals.songTable);
    await _db.delete(Globals.albumTable);
    await _db.delete(Globals.albumSongsTable);
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
          'time_listened': songList[i]['time_listened'],
          'time_added':
              songList[i]['time_added'] ?? File(songList[i]['absolutePath']).statSync().modified.toIso8601String(),
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
            'time_added': DateTime.now().toIso8601String(),
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
