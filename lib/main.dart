import 'package:flutter/material.dart';
import 'package:music_player_app/main_screen.dart';
// import 'package:music_player_app/storage_permission.dart';

void main() {
  runApp(const MusicPlayerApp());
}

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Music Player',
      home: MainScreen(),
      // setup route to use Navigator.pushNamed to wait page navigation (pause previous page until return)
      // routes: {
      //   '/storage_permission': (context) => const StoragePermissionDialog(),
      // },
    );
  }
}
