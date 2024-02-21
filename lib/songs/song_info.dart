import 'package:flutter/material.dart';

import '../globals/music_track.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';

class SongInfo extends StatefulWidget {
  final int songIndex;
  const SongInfo({super.key, required this.songIndex});

  @override
  State<SongInfo> createState() => _SongInfoState();
}

class _SongInfoState extends State<SongInfo> {
  final _songController = TextEditingController(), _artistController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
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
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();
              // save info changes
              allMusicTracks[widget.songIndex].trackName = _songController.text.isEmpty
                  ? allMusicTracks[widget.songIndex].absolutePath.split('/').last.split('.mp3').first
                  : _songController.text;
              allMusicTracks[widget.songIndex].artist =
                  _artistController.text.isEmpty ? 'Unknown' : _artistController.text;

              debugPrint('Song: ${allMusicTracks[widget.songIndex].trackName}');
              debugPrint('Artist: ${allMusicTracks[widget.songIndex].artist}');
              await saveTracksToStorage();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  border: BorderDirectional(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    leadingText(context, 'Song'),
                    Expanded(
                      child: TextField(
                        controller: _songController..text = allMusicTracks[widget.songIndex].trackName,
                        decoration: textFieldDecoration(
                          context,
                          fillColor: Theme.of(context).colorScheme.background,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  border: BorderDirectional(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    leadingText(context, 'Artist'),
                    Expanded(
                      child: TextField(
                        controller: _artistController..text = allMusicTracks[widget.songIndex].artist,
                        decoration: textFieldDecoration(
                          context,
                          fillColor: Theme.of(context).colorScheme.background,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Text leadingText(BuildContext context, String text) => Text(
      text,
      style: TextStyle(
        fontSize: 18,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        fontWeight: FontWeight.bold,
      ),
    );
