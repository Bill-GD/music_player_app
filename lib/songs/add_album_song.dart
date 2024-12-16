import 'package:flutter/material.dart';

class AddAlbumSong extends StatefulWidget {
  const AddAlbumSong({super.key});

  @override
  State<AddAlbumSong> createState() => _AddAlbumSongState();
}

class _AddAlbumSongState extends State<AddAlbumSong> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 40),
        ),
        centerTitle: true,
        title: const Text(
          'Add new song',
          style: TextStyle(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
