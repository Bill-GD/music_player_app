import 'dart:io';

import 'package:flutter/material.dart';
import 'package:music_player_app/music_track.dart';

/// The main screen of the application. This screen has: settings, tabs (songs list, artists), app bar for current song...
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late List<MusicTrack> allMusicTracks;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getTrackFromStorage().then((value) {
      allMusicTracks = value;
      isLoading = false;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const CircularProgressIndicator(
              color: Colors.black,
            )
          : ListView.builder(
              itemCount: allMusicTracks.length,
              itemBuilder: (context, index) => Text(
                '${allMusicTracks[index].toJson()}\n',
              ),
            ),
    );
  }
}
