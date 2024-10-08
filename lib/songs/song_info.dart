import 'package:flutter/material.dart';

import '../globals/functions.dart';
import '../globals/music_track.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';

class SongInfo extends StatefulWidget {
  final String songPath;
  const SongInfo({super.key, required this.songPath});

  @override
  State<SongInfo> createState() => _SongInfoState();
}

class _SongInfoState extends State<SongInfo> {
  final _songController = TextEditingController(),
      _artistController = TextEditingController(),
      _albumController = TextEditingController();

  late MusicTrack song;

  @override
  void initState() {
    super.initState();
    song = Globals.allSongs.firstWhere((e) => e.absolutePath == widget.songPath);
  }

  @override
  void dispose() {
    super.dispose();
    _songController.dispose();
    _artistController.dispose();
    _albumController.dispose();
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
                _albumController.text = _albumController.text.trim();
                // only update if changed
                if (_songController.text != song.trackName ||
                    _artistController.text != song.artist ||
                    _albumController.text != song.album) {
                  needsUpdate = true;

                  song.trackName = _songController.text.isEmpty
                      ? song.absolutePath.split('/').last.split('.mp3').first
                      : _songController.text;

                  song.artist = _artistController.text.isEmpty
                      ? 'Unknown' //
                      : _artistController.text;

                  song.album = _albumController.text.isEmpty
                      ? 'Unknown' //
                      : _albumController.text;

                  if (widget.songPath == Globals.currentSongPath) {
                    Globals.audioHandler.updateNotificationInfo(
                      songPath: widget.songPath,
                      trackName: _songController.text,
                      artist: _artistController.text,
                    );
                  }

                  saveSongsToStorage();
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
                        controller: _songController..text = song.trackName,
                        decoration: textFieldDecoration(
                          context,
                          fillColor: Theme.of(context).colorScheme.background,
                          border: InputBorder.none,
                          suffixIcon: const Icon(Icons.edit_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
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
                        controller: _artistController..text = song.artist,
                        decoration: textFieldDecoration(
                          context,
                          fillColor: Theme.of(context).colorScheme.background,
                          border: InputBorder.none,
                          suffixIcon: const Icon(Icons.edit_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: BorderDirectional(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    leadingText(context, 'Album'),
                    Expanded(
                      child: TextField(
                        controller: _albumController..text = song.album,
                        decoration: textFieldDecoration(
                          context,
                          fillColor: Theme.of(context).colorScheme.background,
                          border: InputBorder.none,
                          suffixIcon: const Icon(Icons.edit_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 30, bottom: 20),
              child: const Text(
                'Other Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                        fillColor: Theme.of(context).colorScheme.background,
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
                        fillColor: Theme.of(context).colorScheme.background,
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
                      initialValue: widget.songPath,
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
          ],
        ),
      ),
    );
  }
}

extension DateString on DateTime {
  String toDateString() {
    return '${formatDay(day)} ${_monthNames[month - 1]} $year, ${hour.padIntLeft(2, '0')}:${minute.padIntLeft(2, '0')}:${second.padIntLeft(2, '0')}';
  }
}

String formatDay(int day) {
  switch (day) {
    case 1:
      return '${day}st';
    case 2:
      return '${day}nd';
    case 3:
      return '${day}rd';
    default:
      return '${day}th';
  }
}

const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
