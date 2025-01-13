import 'dart:async';

import 'package:flutter/material.dart';

import '../globals/extensions.dart';
import '../globals/log_handler.dart';
import '../globals/lyric_handler.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../player/lyric_editor.dart';

class LyricStrip extends StatefulWidget {
  final int songID;

  const LyricStrip({super.key, required this.songID});

  @override
  State<LyricStrip> createState() => _LyricStripState();
}

class _LyricStripState extends State<LyricStrip> {
  var lines = <String>[], timestampList = <Duration>[];
  late final lineCount = lines.length, maxScrollExtent = scrollController.position.maxScrollExtent;
  late Lyric lyric;

  final List<StreamSubscription> subs = [];
  final scrollController = PageController(viewportFraction: 0.3);
  int currentLine = 0, viewLine = 0;
  bool canAutoScroll = true;

  void scroll(Duration time) {
    if (!scrollController.hasClients) return;
    final ratio = currentLine + 1 == lineCount ? 1 : currentLine / lineCount;

    scrollController.animateTo(
      maxScrollExtent * ratio,
      duration: time,
      curve: Curves.decelerate,
    );
  }

  int findCurrentLine() {
    for (int i = lineCount - 1; i >= 0; i--) {
      if (Globals.audioHandler.player.position.inMilliseconds >= timestampList[i].inMilliseconds) {
        return i;
      }
    }
    return 0;
  }

  void updateLyric() {
    final song = Globals.allSongs.firstWhere((e) => e.id == widget.songID);
    lyric = LyricHandler.getLyric(widget.songID, Globals.lyricPath + song.lyricPath) ??
        Lyric(
          songId: widget.songID,
          name: song.name,
          artist: song.artist,
          path: song.path,
          list: [],
        );

    if (lyric.list.isNotEmpty) {
      lines = lyric.list.map((e) => e.line).toList();
      timestampList = lyric.list.map((e) => e.timestamp).toList();
      if (timestampList.first.inMicroseconds != 0) {
        lines.insert(0, '');
        timestampList.insert(0, 0.ms);
      }
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    updateLyric();

    viewLine = currentLine = findCurrentLine();
    WidgetsBinding.instance.addPostFrameCallback((_) => scroll(100.ms));

    subs.add(Globals.audioHandler.player.positionStream.listen((event) {
      final newLine = findCurrentLine();
      if (newLine == currentLine) return;
      viewLine = currentLine = newLine;
      if (canAutoScroll) scroll(600.ms);
    }));
    subs.add(Globals.lyricChangedController.stream.listen((_) {
      updateLyric();
    }));
  }

  @override
  void dispose() {
    for (final e in subs) {
      e.cancel();
    }
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: scrollController,
          scrollDirection: Axis.vertical,
          pageSnapping: false,
          padEnds: true,
          itemCount: lines.length,
          itemBuilder: (context, index) {
            final isCurrent = index == viewLine;

            return Center(
              child: ListTile(
                title: Text(
                  lines[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    shadows: [
                      if (isCurrent)
                        Shadow(
                          color: Theme.of(context).colorScheme.inverseSurface,
                          blurRadius: 35,
                        ),
                    ],
                    fontSize: isCurrent ? 16 : null,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: !isCurrent ? Colors.grey.withOpacity(0.15) : null,
                  ),
                ),
                leading: Text(
                  timestampList[index].toMMSS(),
                  style: TextStyle(
                    color: !isCurrent ? Colors.grey.withOpacity(0.07) : null,
                  ),
                ),
                trailing: isCurrent ? const Icon(Icons.arrow_left_rounded) : const Text('    '),
                visualDensity: VisualDensity.compact,
                dense: true,
              ),
            );
          },
          onPageChanged: (index) {
            viewLine = index;
            canAutoScroll = false;
            Future.delayed(300.ms, () => canAutoScroll = true);
            setState(() {});
          },
        ),
        Positioned(
          right: 15,
          child: IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => LyricEditor(songID: widget.songID),
              ));
            },
          ),
        ),
        Positioned(
          right: 50,
          child: IconButton(
            icon: const Icon(Icons.delete_forever_rounded),
            onPressed: () {
              dialogWithActions<bool>(
                context,
                title: 'Delete lyric',
                titleFontSize: 18,
                textContent: 'Are you sure you want to remove the lyrics?',
                contentFontSize: 14,
                time: 300.ms,
                actions: [
                  TextButton(
                    child: const Text('No'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  TextButton(
                    child: const Text('Yes'),
                    onPressed: () {
                      final song = Globals.allSongs.firstWhereOrNull((e) => e.id == lyric.songId);
                      if (song != null) {
                        LogHandler.log('Removing lyric for ${song.id}');
                        song.lyricPath = '';
                        song.update();
                      }
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              ).then(
                (value) {
                  if (value != true) return;
                  Globals.lyricChangedController.add(null);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
