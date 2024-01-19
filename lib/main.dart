import 'package:flutter/material.dart';
import 'package:music_player_app/main_screen.dart';

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
    );
  }
  
}
