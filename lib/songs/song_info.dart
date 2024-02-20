import 'package:flutter/material.dart';

class SongInfo extends StatefulWidget {
  final int songIndex;
  const SongInfo({super.key, required this.songIndex});

  @override
  State<SongInfo> createState() => _SongInfoState();
}

class _SongInfoState extends State<SongInfo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            // doesn't save info changes
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Edit song info',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: () {
              // save info changes
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      // body: ,
    );
  }
}
