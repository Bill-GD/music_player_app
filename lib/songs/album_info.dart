import 'dart:io';

import 'package:flutter/material.dart';

import '../globals/extensions.dart';
import '../globals/globals.dart';
import '../globals/music_track.dart';
import '../globals/widgets.dart';
import '../widgets/file_picker.dart';

class AlbumInfo extends StatefulWidget {
  final int albumID;

  const AlbumInfo({super.key, required this.albumID});

  @override
  State<AlbumInfo> createState() => _AlbumInfoState();
}

class _AlbumInfoState extends State<AlbumInfo> {
  late final TextEditingController albumController;
  late final Album album;
  String errorText = '', imagePath = '';
  bool hasChanges = false, hasCover = false;

  @override
  void initState() {
    super.initState();
    album = Globals.albums.firstWhere((e) => e.id == widget.albumID);
    albumController = TextEditingController(text: album.name);
    imagePath = album.imagePath;
    hasCover = File(imagePath).existsSync();
  }

  @override
  void dispose() {
    super.dispose();
    albumController.dispose();
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
            'Edit album info',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.check_rounded, size: 30),
              onPressed: hasChanges
                  ? () async {
                      FocusManager.instance.primaryFocus?.unfocus();

                      album.name = albumController.text.trim();
                      Globals.audioHandler.playlistName = album.name;
                      album.imagePath = imagePath;
                      await album.update();

                      if (context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    }
                  : null,
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: TextField(
                    controller: albumController,
                    readOnly: album.name == 'Unknown',
                    onChanged: (val) {
                      if (![album.name, 'Unknown'].contains(val.trim()) && //
                          val.trim().isNotEmpty) {
                        hasChanges = true;
                        errorText = '';
                      } else {
                        hasChanges = false;
                        errorText = 'Name is invalid';
                      }
                      setState(() {});
                    },
                    decoration: textFieldDecoration(
                      context,
                      labelText: 'Name',
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      errorText: errorText.isNotEmpty ? errorText : null,
                      suffixIcon: widget.albumID == 1
                          ? null
                          : const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(Icons.edit_rounded),
                            ),
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 30, bottom: 20),
                child: const Text(
                  'Other Information',
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
                        initialValue: album.id.toString(),
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
                    leadingText(context, 'Song count'),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        scrollPadding: const EdgeInsets.only(right: 0),
                        initialValue: album.songs.length.toString(),
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
                    leadingText(context, 'Time Added'),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        scrollPadding: const EdgeInsets.only(right: 0),
                        initialValue: album.timeAdded.toDateString(),
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
                    final path = await FilePicker.image(
                      context: context,
                      rootDirectory: Directory('/storage/emulated/0'),
                    );
                    if (path == null) return;
                    imagePath = path;
                    hasChanges = imagePath != album.imagePath;
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
                              hasChanges = imagePath != album.imagePath;
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
