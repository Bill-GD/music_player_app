import 'dart:convert';
import 'dart:io';

import '../globals/config.dart';
import '../globals/globals.dart';
import 'database_handler.dart';
import 'log_handler.dart';

class BackupHandler {
  static void init() {
    final buDir = Directory(Globals.backupPath);
    if (!buDir.existsSync()) buDir.createSync();
  }

  static void _cleanUpBackup() {
    final backupFiles = getBackups();
    if (backupFiles.length <= Config.backupCount) return;

    LogHandler.log('Cleaning up backup files');
    while (backupFiles.length > Config.backupCount) {
      final f = backupFiles.removeLast();
      LogHandler.log('Deleting backup file: ${f.path}');
      f.deleteSync();
    }
  }

  static Future<void> backupData() async {
    File bu =
        File('${Globals.backupPath}${Uri.encodeFull(DateTime.now().toIso8601String().replaceAll(':', "-"))}.json');
    if (bu.existsSync()) {
      LogHandler.log('Backup file with same name already exists, deleting');
      bu.deleteSync();
    } else {
      bu.createSync();
    }

    LogHandler.log('Backing up data to: ${bu.path}');
    final data = {
      'songs': await DatabaseHandler.db.query(Globals.songTable),
      'albums': await DatabaseHandler.db.query(Globals.albumTable),
      'album_songs': await DatabaseHandler.db.query(Globals.albumSongsTable),
    };

    bu.writeAsStringSync(jsonEncode(data));
    _cleanUpBackup();
  }

  static List<FileSystemEntity> getBackups() {
    final backupFiles = Directory(Globals.backupPath) //
        .listSync()
        .where((f) => f is File && f.path.endsWith('.json'))
        .toList();
    backupFiles.sort((a, b) => b.statSync().changed.compareTo(a.statSync().changed));
    return backupFiles;
  }

  static Future<void> recoverBackup(File bu) async {
    // final bu = getBackups().last;
    LogHandler.log('Recovering backup data from: ${bu.path}');

    if (!File(Globals.dbPath).existsSync()) {
      LogHandler.log('Database files should exists after app launched.', LogLevel.error);
      // DatabaseHandler.init(); // may init again, will see
    }

    final backupContent = bu //
        .readAsStringSync()
        .replaceAll('timeAdded', 'time_added')
        .replaceAll('timeListened', 'time_listened');

    final json = jsonDecode(backupContent) as Map<String, dynamic>;

    await DatabaseHandler.clearAllData();
    for (final o in json['songs']!) {
      await DatabaseHandler.db.insert(Globals.songTable, o);
    }
    for (final o in json['albums']!) {
      await DatabaseHandler.db.insert(Globals.albumTable, o);
    }
    for (final o in json['album_songs']!) {
      await DatabaseHandler.db.insert(Globals.albumSongsTable, o);
    }
  }
}
