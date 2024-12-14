import 'dart:io';

import 'package:sqflite/sqflite.dart';

import 'log_handler.dart';
import 'variables.dart';

class DatabaseHandler {
  static final String _path = Globals.dbPath;
  static late Database _db;

  static Database get db => _db;

  static Future<void> init() async {
    LogHandler.log('Database init');

    _db = await openDatabase(
      _path,
      version: 1,
      onCreate: (_, __) async {
        await db.execute(
          'create table if not exists music_track ('
          'id integer primary key,'
          'absolutePath text not null,'
          'trackName text not null,'
          'artist text not null,'
          'album text not null,'
          'timeListened integer default 0,'
          'timeAdded datetime'
          ');',
        );
        // await db.execute('create table if not exists album ('
        //     'id integer primary key,'
        //     'name text not null,'
        //     'timeAdded datetime'
        //     ');');
      },
      onOpen: (_) {
        if (_db.isOpen) LogHandler.log('Database is opened.');
      },
    );
  }

  static void migrateOldData() {
    final jsonFile = File(Globals.jsonPath), dbFile = File(Globals.dbPath);
    if (jsonFile.existsSync()) {
      if (jsonFile.statSync().modified.compareTo(dbFile.statSync().modified) < 0) return;
      // TODO parse old data
    }
  }
}
