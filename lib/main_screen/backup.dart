import 'dart:io';

import 'package:flutter/material.dart';

import '../globals/functions.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  late final File dataFile;
  final bu = File('/storage/emulated/0/Android/tracks.json');
  late FileStat dataStat, buStat;

  @override
  void initState() {
    super.initState();
    dataFile = File('${Globals.storagePath}/tracks.json');
    getFileStats();
    setState(() {});
  }

  void getFileStats() {
    dataStat = dataFile.statSync();
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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // data
              const Text('Data file', textAlign: TextAlign.center, style: TextStyle(fontSize: 24)),
              Text(
                'Path: ${dataFile.path}'
                '\nSize: ${getSizeString(dataStat.size.toDouble())}'
                '\nLast modified: ${dataStat.modified}',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(),
              ),
              // backup
              const Text('Backup file', textAlign: TextAlign.center, style: TextStyle(fontSize: 24)),
              Row(
                children: [
                  Text(
                    'Path: ${bu.path}'
                    '\nSize: ${getSizeString(buStat.size.toDouble())}'
                    '\nLast modified: ${buStat.modified}',
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (!dataFile.existsSync()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No data to backup')),
                        );
                        return;
                      }
                      if (!bu.existsSync()) bu.createSync();

                      bu.writeAsStringSync(dataFile.readAsStringSync());

                      debugPrint('Backing up data to: ${bu.path}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Data backed up successfully')),
                      );
                      setState(() => getFileStats());
                    },
                    child: const Text('Backup Data'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (!bu.existsSync()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No backup data found')),
                        );
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
                                'Overwite Data',
                                textAlign: TextAlign.center,
                                style: bottomSheetTitle.copyWith(fontSize: 24),
                              ),
                            ),
                            alignment: Alignment.center,
                            contentPadding: const EdgeInsets.only(left: 10, right: 10, top: 40),
                            content: const Text(
                              'Do you want to recover data from backup? This will overwrite current data.',
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

                      if (!dataFile.existsSync()) dataFile.createSync();
                      dataFile.writeAsStringSync(bu.readAsStringSync());

                      debugPrint('Recovering back up data from: ${bu.path}');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Data recovered successfully')),
                        );
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
