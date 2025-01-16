import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../globals/extensions.dart';
import '../globals/log_handler.dart';
import '../globals/lyric_handler.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../player/lyric_editor.dart';

class LyricStrip extends StatefulWidget {
  const LyricStrip({super.key});

  @override
  State<LyricStrip> createState() => _LyricStripState();
}

class _LyricStripState extends State<LyricStrip> {
  final scrollController = PageController(viewportFraction: 0.3);
  final List<StreamSubscription> subs = [];
  var lines = <String>[], timestampList = <Duration>[];
  int currentLine = 0, viewLine = 0, lineCount = 0, currentSongID = 0;
  bool canAutoScroll = true;

  late Lyric lyric;

  void scroll(Duration time) {
    if (!scrollController.hasClients) return;
    scrollController.animateToPage(
      currentLine,
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
    final song = Globals.allSongs.firstWhere((e) => e.id == Globals.currentSongID);
    currentSongID = song.id;
    lyric = LyricHandler.getLyric(currentSongID, Globals.lyricPath + song.lyricPath) ??
        Lyric(
          songId: currentSongID,
          name: song.name,
          artist: song.artist,
          path: song.path,
          list: [],
        );

    if (lyric.list.isNotEmpty) {
      lines = lyric.list.map((e) => e.line).toList();
      timestampList = lyric.list.map((e) => e.timestamp).toList();
      if (timestampList.first.inMicroseconds != 0) {
        lines.insert(0, '[Music]');
        timestampList.insert(0, 0.ms);
      }
    }
    lineCount = lines.length;
    LogHandler.log('Updated lyric for $currentSongID: ${song.lyricPath}');
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
      viewLine = currentLine = findCurrentLine();
      scroll(600.ms);
    }));

    subs.add(Globals.audioHandler.onSongChange.listen((_) {
      Globals.lyricChangedController.add(null);
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
            final isCurrent = index == currentLine, isViewed = index == viewLine;
            final highlight = isCurrent || isViewed;

            return Center(
              child: ListTile(
                leading: Text(
                  timestampList[index].toMMSS(),
                  style: TextStyle(
                    shadows: [
                      if (highlight)
                        Shadow(
                          color: Theme.of(context).colorScheme.inverseSurface.withOpacity(isViewed ? 1 : 0.4),
                          blurRadius: 25,
                        ),
                    ],
                    color: isViewed
                        ? null
                        : isCurrent
                            ? Theme.of(context).colorScheme.inverseSurface.withOpacity(0.4)
                            : Colors.grey.withOpacity(0.07),
                  ),
                ),
                title: Text(
                  lines[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    shadows: [
                      if (highlight)
                        Shadow(
                          color: Theme.of(context).colorScheme.inverseSurface,
                          blurRadius: isViewed ? 30 : 20,
                        ),
                    ],
                    fontSize: highlight ? 16 : null,
                    fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                    color: isViewed
                        ? null
                        : isCurrent
                            ? Theme.of(context).colorScheme.inverseSurface.withOpacity(0.4)
                            : Colors.grey.withOpacity(0.15),
                  ),
                ),
                trailing: isCurrent
                    ? const Padding(
                        padding: EdgeInsets.only(right: 5),
                        child: FaIcon(FontAwesomeIcons.volumeHigh, size: 10),
                      )
                    : isViewed
                        ? const Icon(Icons.arrow_left_rounded)
                        : const Text(''),
                visualDensity: VisualDensity.compact,
                dense: true,
              ),
            );
          },
          onPageChanged: (index) {
            viewLine = index;
            canAutoScroll = false;
            Future.delayed(250.ms, () => canAutoScroll = true);
            setState(() {});
          },
        ),
        Positioned(
          right: 15,
          child: IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => LyricEditor(songID: currentSongID),
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
