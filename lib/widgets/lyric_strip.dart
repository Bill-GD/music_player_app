import 'package:flutter/material.dart';

import '../globals/extensions.dart';
import '../globals/lyric_handler.dart';

class LyricStrip extends StatefulWidget {
  final Lyric lyric;

  const LyricStrip({super.key, required this.lyric});

  @override
  State<LyricStrip> createState() => _LyricStripState();
}

class _LyricStripState extends State<LyricStrip> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: widget.lyric.list.length,
        itemBuilder: (context, index) {
          final item = widget.lyric.list.elementAt(index);
          return ListTile(
            title: Text(item.line),
            subtitle: Text(item.timestamp.toLyricTimestamp()),
          );
        },
      ),
    );
  }
}
