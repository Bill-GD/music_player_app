import 'package:flutter/material.dart';

import '../globals/globals.dart';
import '../globals/music_track.dart';
import '../globals/widgets.dart';

class AddAlbum extends StatefulWidget {
  const AddAlbum({super.key});

  @override
  State<AddAlbum> createState() => _AddAlbumState();
}

class _AddAlbumState extends State<AddAlbum> {
  final albumNameController = TextEditingController();
  String errorText = '';
  bool canAdd = false;
  late final names = Globals.albums.map((e) => e.name);

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
          'Add new album',
          style: TextStyle(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        actions: [
          IconButton(
            onPressed: canAdd
                ? () async {
                    await Album(name: albumNameController.text, timeAdded: DateTime.now()).insert();
                    await updateAlbumList();
                    if (context.mounted) Navigator.of(context).pop();
                  }
                : null,
            icon: const Icon(Icons.check_rounded, size: 30),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: TextField(
          controller: albumNameController,
          onChanged: (val) {
            if (val.trim().isEmpty) {
              errorText = "Name can't be empty";
              canAdd = false;
            } else if (names.contains(val.trim())) {
              errorText = 'This name is already taken';
              canAdd = false;
            } else {
              errorText = '';
              canAdd = true;
            }
            setState(() {});
          },
          decoration: textFieldDecoration(
            context,
            labelText: 'Name',
            fillColor: Theme.of(context).colorScheme.surface,
            errorText: errorText.isEmpty ? null : errorText,
            suffixIcon: const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.edit_rounded),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}
