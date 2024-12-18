import 'package:flutter/material.dart';

import '../globals/functions.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';

class AlbumInfo extends StatefulWidget {
  final int albumID;

  const AlbumInfo({super.key, required this.albumID});

  @override
  State<AlbumInfo> createState() => _AlbumInfoState();
}

class _AlbumInfoState extends State<AlbumInfo> {
  final albumController = TextEditingController();
  String errorText = '';
  bool canChange = false;

  late final album = Globals.albums.firstWhere((e) => e.id == widget.albumID);

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
              onPressed: canChange
                  ? () async {
                      FocusManager.instance.primaryFocus?.unfocus();

                      album.name = albumController.text;
                      Globals.audioHandler.updatePlaylistName(album.name);
                      await album.update();

                      if (context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    }
                  : null,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: BorderDirectional(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    leadingText(context, 'Name'),
                    Expanded(
                      child: TextField(
                        controller: albumController..text = album.name,
                        readOnly: album.name == 'Unknown',
                        onChanged: (val) {
                          albumController.text = val.trim();
                          if (![album.name, 'Unknown'].contains(albumController.text) && //
                              albumController.text.isNotEmpty) {
                            canChange = true;
                            errorText = '';
                          } else {
                            canChange = false;
                            errorText = 'Name is invalid';
                          }
                          setState(() {});
                        },
                        decoration: textFieldDecoration(
                          context,
                          fillColor: Theme.of(context).colorScheme.background,
                          border: InputBorder.none,
                          suffixIcon: const Icon(Icons.edit_rounded),
                          errorText: errorText.isNotEmpty ? errorText : null,
                        ),
                      ),
                    ),
                  ],
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
                        fillColor: Theme.of(context).colorScheme.background,
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
                        fillColor: Theme.of(context).colorScheme.background,
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
                        fillColor: Theme.of(context).colorScheme.background,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
