import 'dart:async';

import 'package:flutter/material.dart';
import 'package:music_player_app/globals/variables.dart';

import '../globals/extensions.dart';
import '../globals/lyric_handler.dart';

class LyricStrip extends StatefulWidget {
  final Lyric lyric;

  const LyricStrip({super.key, required this.lyric});

  @override
  State<LyricStrip> createState() => _LyricStripState();
}

class _LyricStripState extends State<LyricStrip> {
  late final StreamSubscription sub;
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    sub = Globals.audioHandler.player.positionStream.listen((event) {
      // final idx = widget.lyric.list.indexWhere((e) => e.timestamp.compareTo(event));
      // if (idx == -1) return;
      // scroll to the current line
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      itemCount: widget.lyric.list.length,
      itemBuilder: (context, index) {
        final item = widget.lyric.list.elementAt(index);
        return ListTile(
          title: Text(item.line, textAlign: TextAlign.center),
          leading: Text(item.timestamp.toMMSS()),
          trailing: const Text(''),
          visualDensity: VisualDensity.compact,
        );
      },
    );
  }
}
