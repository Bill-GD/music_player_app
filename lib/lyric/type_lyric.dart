import 'package:flutter/material.dart';

import '../globals/widgets.dart';

class TypeLyric extends StatefulWidget {
  final List<String> lines;
  const TypeLyric({super.key, required this.lines});

  @override
  State<TypeLyric> createState() => _TypeLyricState();
}

class _TypeLyricState extends State<TypeLyric> {
  late final lyricController = TextEditingController(text: widget.lines.join('\n'));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: Navigator.of(context).pop,
          ),
          title: const Text('Type lyric'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.check_rounded),
              onPressed: () {
                Navigator.of(context).pop(lyricController.text);
              },
            ),
          ],
          shape: BorderDirectional(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 1,
            ),
          ),
        ),
        body: Container(
          padding: const EdgeInsets.all(10),
          height: MediaQuery.of(context).size.height,
          child: TextField(
            controller: lyricController,
            maxLines: null,
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            decoration: textFieldDecoration(
              context,
              border: InputBorder.none,
              hintText: 'Type lyric here,\n'
                  'separated by new line.\n'
                  'Use space for empty line.',
              fillColor: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}
