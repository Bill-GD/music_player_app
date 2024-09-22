import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../globals/functions.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  late final File dataFile;
  final bu = File('/storage/emulated/0/Android/tracks.json');
  bool loading = true;
  late FileStat dataStat, buStat;

  @override
  void initState() {
    super.initState();
    getExternalStorageDirectory().then((value) {
      if (value == null) return;
      dataFile = File('${value.path}/tracks.json');
      getFileStats();
      loading = false;
      setState(() {});
    });
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
                loading
                    ? 'Loading'
                    : 'Path: ${dataFile.path}'
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
                    onPressed: () {
                      if (!bu.existsSync()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No backup data found')),
                        );

                        return;
                      }
                      if (!dataFile.existsSync()) dataFile.createSync();

                      dataFile.writeAsStringSync(bu.readAsStringSync());

                      debugPrint('Recovering back up data from: ${bu.path}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Data recovered successfully')),
                      );
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
