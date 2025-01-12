import 'dart:async';

import 'package:flutter/material.dart';

import '../globals/extensions.dart';
import '../globals/functions.dart';
import '../globals/lyric_handler.dart';
import '../globals/variables.dart';

class LyricStrip extends StatefulWidget {
  final Lyric lyric;

  const LyricStrip({super.key, required this.lyric});

  @override
  State<LyricStrip> createState() => _LyricStripState();
}

class _LyricStripState extends State<LyricStrip> {
  late final List<String> lines;
  late final List<Duration> timestampList;
  late final StreamSubscription<Duration> sub;
  late final lineCount = lines.length, maxScrollExtent = scrollController.position.maxScrollExtent;

  final scrollController = PageController(viewportFraction: 0.25);
  int currentLine = 0;

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

  @override
  void initState() {
    super.initState();

    lines = widget.lyric.list.map((e) => e.line).toList();
    timestampList = widget.lyric.list.map((e) => e.timestamp).toList();
    if (timestampList.first.inMicroseconds != 0) {
      lines.insert(0, '');
      timestampList.insert(0, 0.ms);
    }
    currentLine = findCurrentLine();

    WidgetsBinding.instance.addPostFrameCallback((_) => scroll(100.ms));

    sub = Globals.audioHandler.player.positionStream.listen((event) {
      final newLine = findCurrentLine();
      if (newLine == currentLine) return;
      currentLine = newLine;
      scroll(700.ms);
    });
  }

  @override
  void dispose() {
    sub.cancel();
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
            final isCurrent = index == currentLine;

            return Center(
              child: ListTile(
                title: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isCurrent ? 0 : 4),
                  child: Text(
                    lines[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      shadows: [
                        if (isCurrent) const Shadow(color: Colors.white70, blurRadius: 35),
                      ],
                      fontSize: isCurrent ? 16 : null,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: !isCurrent
                          ? Colors.grey.withOpacity(0.7 / (currentLine - index).abs().clamp(1, double.infinity))
                          : null,
                    ),
                  ),
                ),
                leading: Text(isCurrent ? timestampList[currentLine].toMMSS() : '    '),
                trailing: isCurrent ? const Icon(Icons.arrow_left_rounded) : const Text('    '),
                visualDensity: VisualDensity.compact,
                dense: true,
              ),
            );
          },
        ),
        Positioned(
          right: 15,
          child: IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () {
              showToast(context, 'msg');
            },
          ),
        ),
        Positioned(
          right: 50,
          child: IconButton(
            icon: const Icon(Icons.delete_forever_rounded),
            onPressed: () {
              showToast(context, 'msg');
            },
          ),
        ),
      ],
    );
  }
}
