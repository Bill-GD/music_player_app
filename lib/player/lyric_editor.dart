import 'package:flutter/material.dart';

import '../globals/extensions.dart';
import '../globals/log_handler.dart';
import '../globals/lyric_handler.dart';
import '../globals/music_track.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../setting/timestamp_editor.dart';

class LyricEditor extends StatefulWidget {
  final int songID;

  const LyricEditor({super.key, required this.songID});

  @override
  State<LyricEditor> createState() => _LyricEditorState();
}

class _LyricEditorState extends State<LyricEditor> {
  late final MusicTrack song;
  late final Lyric lyric;

  final lineEditController = TextEditingController();
  int listCount = 0, editingIndex = -1;
  bool hasChanged = false, isEditing = false;

  void updateListCount() => listCount = lyric.list.length;

  @override
  void initState() {
    super.initState();
    song = Globals.allSongs.firstWhere((e) => e.id == widget.songID);
    lyric = LyricHandler.getLyric(song.id, Globals.lyricPath + song.lyricPath) ??
        Lyric(
          songId: song.id,
          name: song.name,
          artist: song.artist,
          path: '${song.name}.lrc',
          list: [],
        );
    updateListCount();
    LogHandler.log('Editing lyric for ${song.id}');
    debugPrint('Lyric info \n$lyric');
  }

  @override
  void dispose() {
    lineEditController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () {
              if (!hasChanged) {
                Navigator.of(context).pop();
                return;
              }
              dialogWithActions<bool>(
                context,
                title: 'Discard changes',
                titleFontSize: 18,
                textContent: 'Are you sure you want to discard changes?',
                contentFontSize: 14,
                time: 300.ms,
                actions: [
                  TextButton(
                    child: const Text('No'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  TextButton(
                    child: const Text('Yes'),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ).then(
                (value) {
                  if (value != true) return;
                  LogHandler.log('Discarded lyric changes');
                  Navigator.of(context).pop();
                },
              );
            },
          ),
          title: const Text(
            'Lyric Editor',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.save_rounded),
              onPressed: hasChanged
                  ? () {
                      dialogWithActions<bool>(
                        context,
                        title: 'Save changes',
                        titleFontSize: 18,
                        textContent: 'Are you sure you want to save changes?',
                        contentFontSize: 14,
                        time: 300.ms,
                        actions: [
                          TextButton(
                            child: const Text('No'),
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                          TextButton(
                            child: const Text('Yes'),
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                        ],
                      ).then((value) {
                        if (value != true) return;
                        if (song.lyricPath != lyric.path) {
                          song.lyricPath = lyric.path;
                          song.update();
                        }
                        LyricHandler.addLyric(lyric);
                        Globals.lyricChangedController.add(null);
                        Navigator.of(context).pop();
                      });
                    }
                  : null,
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
                  lyric.list.add(const LyricItem(timestamp: Duration.zero, line: ''));
                  updateListCount();
                  setState(() => hasChanged = true);
                },
              );
            }

            final item = lyric.list[index];

            if (isEditing && index == editingIndex) {
              return ListTile(
                leading: Text(item.timestamp.toLyricTimestamp()),
                title: TextField(
                  controller: lineEditController,
                  maxLines: null,
                  decoration: textFieldDecoration(
                    context,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check_rounded),
                      onPressed: () {
                        isEditing = false;
                        hasChanged = item.line != lineEditController.text;
                        if (hasChanged) {
                          lyric.list[index] = LyricItem(
                            timestamp: item.timestamp,
                            line: lineEditController.text,
                          );
                        }
                        setState(() {});
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.only(left: 10, top: 5, bottom: 5),
                  ),
                ),
              );
            }
            return ListTile(
              leading: GestureDetector(
                onTap: () {
                  final parts = item.timestamp
                      .toLyricTimestamp() //
                      .split(RegExp(r'[:.]'))
                      .map(int.parse)
                      .toList();
                  final timestamp = (parts[0], parts[1], parts[2] * 10);

                  Navigator.push<List<int>>(
                    context,
                    DialogRoute(
                      context: context,
                      builder: (context) => TimestampEditor(timestamp: timestamp),
                    ),
                  ).then((value) {
                    if (value == null) return;
                    hasChanged = timestamp != (value[0], value[1], value[2]);
                    if (!hasChanged) return;

                    lyric.list[index] = LyricItem(
                      timestamp: Duration(minutes: value[0], seconds: value[1], milliseconds: value[2]),
                      line: item.line,
                    );
                    setState(() {});
                  });
                },
                child: Text(item.timestamp.toLyricTimestamp()),
              ),
              title: GestureDetector(
                onTap: () {
                  isEditing = true;
                  editingIndex = index;
                  lineEditController.text = item.line;
                  // timeEditController.text = item.timestamp.toLyricTimestamp();
                  setState(() {});
                },
                child: Text(item.line),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_forever_rounded),
                onPressed: () {
                  lyric.list.removeAt(index);
                  updateListCount();
                  setState(() => hasChanged = true);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
