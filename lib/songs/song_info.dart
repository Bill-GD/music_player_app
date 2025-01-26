import 'dart:io';

import 'package:flutter/material.dart';

import '../globals/extensions.dart';
import '../globals/globals.dart';
import '../globals/widgets.dart';
import '../widgets/file_picker.dart';

class SongInfo extends StatefulWidget {
  final int songID;

  const SongInfo({super.key, required this.songID});

  @override
  State<SongInfo> createState() => _SongInfoState();
}

class _SongInfoState extends State<SongInfo> {
  final _songController = TextEditingController(), _artistController = TextEditingController();
  bool hasCover = false, hasChanges = false;

  late final song = Globals.allSongs.firstWhere((e) => e.id == widget.songID);
  late String imagePath = song.imagePath;

  @override
  void initState() {
    super.initState();
    _songController.text = song.name;
    _artistController.text = song.artist;
    hasCover = File(imagePath).existsSync();
  }

  @override
  void dispose() {
    super.dispose();
    _songController.dispose();
    _artistController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 40),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Edit song info',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.check_rounded, size: 30),
              onPressed: hasChanges
                  ? () async {
                      FocusManager.instance.primaryFocus?.unfocus();
                      _songController.text = _songController.text.trim();
                      _artistController.text = _artistController.text.trim();

                      song.name = _songController.text.isEmpty
                          ? song.path.split('/').last.split('.mp3').first
                          : _songController.text;

                      song.artist = _artistController.text.isEmpty
                          ? 'Unknown' //
                          : _artistController.text;

                      song.imagePath = imagePath;

                      await song.update();
                      if (widget.songID == Globals.currentSongID) {
                        Globals.audioHandler.updateNotificationInfo(songID: widget.songID);
                      }

                      // setState(() => hasChanges = false);
                      if (context.mounted) {
                        Navigator.of(context).pop(hasChanges);
                      }
                    }
                  : null,
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // song name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: TextField(
                    controller: _songController,
                    onChanged: (value) => setState(() => hasChanges = value != song.name),
                    decoration: textFieldDecoration(
                      context,
                      labelText: 'Name',
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      suffixIcon: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.edit_rounded),
                      ),
                    ),
                  ),
                ),
              ),
              // song artist
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: TextField(
                    controller: _artistController,
                    onChanged: (value) => setState(() => hasChanges = value != song.artist),
                    decoration: textFieldDecoration(
                      context,
                      labelText: 'Artist',
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      suffixIcon: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.edit_rounded),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 30, bottom: 20),
                child: const Text(
                  'Other information',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 30, right: 15),
                child: Row(
                  children: [
                    leadingText(context, 'ID'),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        scrollPadding: const EdgeInsets.only(right: 0),
                        initialValue: song.id.toString(),
                        decoration: textFieldDecoration(
                          context,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 30, right: 15),
                child: Row(
                  children: [
                    leadingText(context, 'Time played'),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        scrollPadding: const EdgeInsets.only(right: 0),
                        initialValue: song.timeListened.toString(),
                        decoration: textFieldDecoration(
                          context,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 30, right: 15),
                child: Row(
                  children: [
                    leadingText(context, 'Time added'),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        scrollPadding: const EdgeInsets.only(right: 0),
                        initialValue: song.timeAdded.toDateString(),
                        decoration: textFieldDecoration(
                          context,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 30, right: 15),
                child: Row(
                  children: [
                    leadingText(context, 'Path'),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        scrollPadding: const EdgeInsets.only(right: 0),
                        initialValue: song.fullPath,
                        decoration: textFieldDecoration(
                          context,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 30, right: 15),
                child: Row(
                  children: [
                    leadingText(context, 'Lyric'),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        scrollPadding: const EdgeInsets.only(right: 0),
                        initialValue: song.lyricPath.isNotEmpty ? Globals.lyricPath + song.lyricPath : 'No lyric',
                        decoration: textFieldDecoration(
                          context,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // cover image
              Container(
                margin: const EdgeInsets.only(top: 30, bottom: 20),
                child: const Text(
                  'Cover image',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: GestureDetector(
                  onTap: () async {
                    final path = await FilePicker.open(
                      context: context,
                      rootDirectory: Directory('/storage/emulated/0'),
                      allowedExtensions: ['jpg', 'jpeg', 'png'],
                    );
                    if (path == null) return;
                    imagePath = path;
                    hasChanges = imagePath != song.imagePath;
                    setState(() => hasCover = true);
                  },
                  child: Stack(
                    children: [
                      Container(
                        constraints: BoxConstraints.tight(const Size(320, 320)),
                        decoration: !hasCover
                            ? BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  width: 1,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              )
                            : null,
                        child: hasCover
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(
                                  File(imagePath),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.image_not_supported_rounded, size: 80),
                                  Text(
                                    imagePath.isNotEmpty
                                        ? 'Image not found\nTap to relocate or change'
                                        : 'No cover image\nTap to change',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                      ),
                      if (hasCover)
                        Positioned(
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded),
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                Theme.of(context).colorScheme.surface.withOpacity(0.2),
                              ),
                            ),
                            onPressed: () {
                              imagePath = '';
                              hasChanges = imagePath != song.imagePath;
                              setState(() => hasCover = false);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
