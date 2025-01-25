import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../globals/extensions.dart';
import '../globals/globals.dart';
import '../globals/utils.dart';
import '../handlers/database_handler.dart';
import '../handlers/log_handler.dart';
import '../widgets/action_dialog.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final bu = File(Globals.backupPath);
  late FileStat dataStat, buStat;

  @override
  void initState() {
    super.initState();
    getFileStats();
    setState(() {});
  }

  void getFileStats() {
    buStat = bu.statSync();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Backup'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_left_rounded, size: 40),
            onPressed: Navigator.of(context).pop,
          ),
        ),
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Text(
                'Path: ${bu.path}'
                '\nSize: ${max(buStat.size, 0)} bytes'
                '\nLast modified: ${buStat.modified}',
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final res = await ActionDialog.static<bool>(
                        context,
                        title: 'Backup data',
                        titleFontSize: 24,
                        textContent: 'Do you want to back up the current data? '
                            'This will overwrite the backed up data.\n'
                            'Is disabled if app is just re-installed.',
                        contentFontSize: 16,
                        time: 300.ms,
                        barrierDismissible: false,
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Yes'),
                          ),
                        ],
                      );
                      if (res != true) return;
                      if (context.mounted) await backupData(context, bu);
                      setState(() => getFileStats());
                    },
                    child: const Text('Backup Data'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (!bu.existsSync()) {
                        return showToast(context, 'No backup data found');
                      }

                      final res = await ActionDialog.static<bool>(
                        context,
                        title: 'Overwrite data',
                        titleFontSize: 24,
                        textContent: 'Do you want to recover data from backup? '
                            'This will overwrite current data '
                            'and you\'d want to refresh the songs.',
                        contentFontSize: 16,
                        time: 300.ms,
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Yes'),
                          ),
                        ],
                      );
                      if (res != true) return;
                      LogHandler.log('Recovering backup data from: ${bu.path}');

                      if (!File(Globals.dbPath).existsSync()) {
                        LogHandler.log('Database files should exists after app launched.', LogLevel.error);
                        // DatabaseHandler.init(); // may init again, will see
                      }

                      // TODO parse json & delete -> insert
                      final backupContent = bu
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

                      if (context.mounted) {
                        showToast(context, 'Data recovered successfully');
                      }
                      setState(() => getFileStats());
                    },
                    child: const Text('Recover Backup'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
