import 'package:flutter/material.dart';

class LyricEditor extends StatefulWidget {
  final int songID;
  const LyricEditor({super.key, required this.songID});

  @override
  State<LyricEditor> createState() => _LyricEditorState();
}

class _LyricEditorState extends State<LyricEditor> {
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
        ),
        body: null,
      ),
    );
  }
}
