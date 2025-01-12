import 'package:flutter/material.dart';

import '../globals/extensions.dart';
import '../globals/music_track.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';

class SongInfo extends StatefulWidget {
  final int songID;

  const SongInfo({super.key, required this.songID});

  @override
  State<SongInfo> createState() => _SongInfoState();
}

class _SongInfoState extends State<SongInfo> {
  final _songController = TextEditingController(), _artistController = TextEditingController();

  late MusicTrack song = Globals.allSongs.firstWhere((e) => e.id == widget.songID);

  @override
  void dispose() {
    super.dispose();
    _songController.dispose();
    _artistController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 40),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Edit song info',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.check_rounded, size: 30),
              onPressed: () async {
                bool needsUpdate = false;
                FocusManager.instance.primaryFocus?.unfocus();
                _songController.text = _songController.text.trim();
                _artistController.text = _artistController.text.trim();
                // only update if changed
                if (_songController.text != song.name || _artistController.text != song.artist) {
                  needsUpdate = true;

                  song.name = _songController.text.isEmpty
                      ? song.path.split('/').last.split('.mp3').first
                      : _songController.text;

                  song.artist = _artistController.text.isEmpty
                      ? 'Unknown' //
                      : _artistController.text;

                  if (widget.songID == Globals.currentSongID) {
                    Globals.audioHandler.updateNotificationInfo(
                      songID: widget.songID,
                      trackName: _songController.text,
                      artist: _artistController.text,
                    );
                  }
                  await song.update();
                }
                if (context.mounted) {
                  Navigator.of(context).pop(needsUpdate);
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: TextField(
                  controller: _songController..text = song.name,
                  decoration: textFieldDecoration(
                    context,
                    labelText: 'Name',
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    suffixIcon: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.edit_rounded),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: TextField(
                  controller: _artistController..text = song.artist,
                  decoration: textFieldDecoration(
                    context,
                    labelText: 'Artist',
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    suffixIcon: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.edit_rounded),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 30, bottom: 20),
              child: const Text(
                'Other Information',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30, right: 15),
              child: Row(
                children: [
                  leadingText(context, 'ID'),
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      scrollPadding: const EdgeInsets.only(right: 0),
                      initialValue: song.id.toString(),
                      decoration: textFieldDecoration(
                        context,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30, right: 15),
              child: Row(
                children: [
                  leadingText(context, 'Time Played'),
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      scrollPadding: const EdgeInsets.only(right: 0),
                      initialValue: song.timeListened.toString(),
                      decoration: textFieldDecoration(
                        context,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30, right: 15),
              child: Row(
                children: [
                  leadingText(context, 'Time Added'),
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      scrollPadding: const EdgeInsets.only(right: 0),
                      initialValue: song.timeAdded.toDateString(),
                      decoration: textFieldDecoration(
                        context,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30, right: 15),
              child: Row(
                children: [
                  leadingText(context, 'Path'),
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      scrollPadding: const EdgeInsets.only(right: 0),
                      initialValue: song.fullPath,
                      decoration: textFieldDecoration(
                        context,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30, right: 15),
              child: Row(
                children: [
                  leadingText(context, 'Lyric'),
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      scrollPadding: const EdgeInsets.only(right: 0),
                      initialValue: song.lyricPath,
                      decoration: textFieldDecoration(
                        context,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
