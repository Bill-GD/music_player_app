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
  void dispose() {
    super.dispose();
    _songController.dispose();
    _artistController.dispose();
  }

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
              bool needsUpdate = false;
              FocusManager.instance.primaryFocus?.unfocus();
              _songController.text = _songController.text.trim();
              _artistController.text = _artistController.text.trim();
              // only update if changed
              if (_songController.text != allMusicTracks[widget.songIndex].trackName ||
                  _artistController.text != allMusicTracks[widget.songIndex].artist) {
                needsUpdate = true;

                allMusicTracks[widget.songIndex].trackName = _songController.text.isEmpty
                    ? allMusicTracks[widget.songIndex].absolutePath.split('/').last.split('.mp3').first
                    : _songController.text;

                allMusicTracks[widget.songIndex].artist = _artistController.text.isEmpty
                    ? 'Unknown' //
                    : _artistController.text;

                await saveSongsToStorage();
              }
              if (context.mounted) {
                Navigator.of(context).pop(needsUpdate);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            Container(
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
                      controller: _songController..text = allMusicTracks[widget.songIndex].trackName,
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
            Container(
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
                      controller: _artistController..text = allMusicTracks[widget.songIndex].artist,
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
            Container(
              margin: const EdgeInsets.only(top: 30, bottom: 20),
              child: const Text(
                'Other Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            Row(
              children: [
                leadingText(context, 'Time Played'),
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    initialValue: allMusicTracks[widget.songIndex].timeListened.toString(),
                    decoration: textFieldDecoration(
                      context,
                      fillColor: Theme.of(context).colorScheme.background,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                leadingText(context, 'Time Added'),
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    initialValue: allMusicTracks[widget.songIndex].timeAdded.toDateString(),
                    decoration: textFieldDecoration(
                      context,
                      fillColor: Theme.of(context).colorScheme.background,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                leadingText(context, 'Path'),
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    initialValue: allMusicTracks[widget.songIndex].absolutePath,
                    decoration: textFieldDecoration(
                      context,
                      fillColor: Theme.of(context).colorScheme.background,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
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

extension DateString on DateTime {
  String toDateString() {
    return '${formatDay(day)} ${_monthNames[month - 1]} $year, $hour:$minute:$second';
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
