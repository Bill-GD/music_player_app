import 'package:flutter/material.dart';

import '../globals/extensions.dart';
import '../globals/lyric_handler.dart';
import '../globals/music_track.dart';
import '../globals/variables.dart';

class LyricEditor extends StatefulWidget {
  final Lyric? lyric;

  const LyricEditor({super.key, this.lyric});

  @override
  State<LyricEditor> createState() => _LyricEditorState();
}

class _LyricEditorState extends State<LyricEditor> {
  late final lyricCopy = widget.lyric == null ? null : Lyric.from(widget.lyric!);
  int listCount = 0;
  late final MusicTrack song;

  void updateListCount() {
    listCount = lyricCopy?.list.length ?? 0;
  }

  @override
  void initState() {
    super.initState();
    updateListCount();
    song = Globals.allSongs.firstWhere((e) => e.id == lyricCopy!.songId);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Lyric Editor',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.save_rounded),
              onPressed: () {
                LyricHandler.addLyric(lyricCopy!);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        body: ListView.builder(
          itemCount: listCount + 1,
          itemBuilder: (context, index) {
            if (index == listCount) {
              return ListTile(
                title: const Icon(Icons.add_rounded),
                onTap: () {
                  lyricCopy!.list.add(const LyricItem(timestamp: Duration.zero, line: ''));
                  updateListCount();
                  setState(() {});
                },
              );
            }

            final item = lyricCopy!.list[index];

            return ListTile(
              title: Text(item.line),
              leading: Text(item.timestamp.toLyricTimestamp()),
              trailing: IconButton(
                icon: const Icon(Icons.delete_forever_rounded),
                onPressed: () {
                  lyricCopy!.list.removeAt(index);
                  updateListCount();
                  setState(() {});
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
