import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../globals/database_handler.dart';
import '../globals/functions.dart';
import '../globals/log_handler.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';

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
          backgroundColor: Theme.of(context).colorScheme.background,
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
                      await backupData(context, bu);
                      setState(() => getFileStats());
                    },
                    child: const Text('Backup Data'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (!bu.existsSync()) {
                        showToast(context, 'No backup data found');
                        return;
                      }

                      final res = await showGeneralDialog<bool>(
                        context: context,
                        transitionDuration: 300.ms,
                        transitionBuilder: (_, anim1, __, child) {
                          return ScaleTransition(
                            scale: anim1.drive(CurveTween(curve: Curves.easeOutQuart)),
                            child: child,
                          );
                        },
                        barrierDismissible: true,
                        barrierLabel: '',
                        pageBuilder: (context, _, __) {
                          return AlertDialog(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            title: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Overwrite Data',
                                textAlign: TextAlign.center,
                                style: bottomSheetTitle.copyWith(fontSize: 24),
                              ),
                            ),
                            alignment: Alignment.center,
                            contentPadding: const EdgeInsets.only(left: 10, right: 10, top: 20, bottom: 20),
                            content: const Text(
                              'Do you want to recover data from backup? '
                              'This will overwrite current data '
                              'and you\'d want to refresh the songs.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                            actionsAlignment: MainAxisAlignment.spaceAround,
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('NO'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('YES'),
                              ),
                            ],
                          );
                        },
                      );
                      if (res != true) return;
                      LogHandler.log('Recovering back up data from: ${bu.path}');

                      if (!File(Globals.dbPath).existsSync()) {
                        LogHandler.log('Database files should exists after app launched.', LogLevel.error);
                        // DatabaseHandler.init(); // may init again, will see
                      }

                      // TODO parse json & delete -> insert
                      final json = jsonDecode(bu.readAsStringSync()) as Map<String, dynamic>;

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
