import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'extensions.dart';
import 'variables.dart';
import 'widgets.dart';

class PlaylistSheet extends StatefulWidget {
  final ScrollController scrollController;
  final void Function(int oldIndex, int newIndex)? onReorder;

  const PlaylistSheet({
    super.key,
    required this.scrollController,
    this.onReorder,
  });

  @override
  State<PlaylistSheet> createState() => _PlaylistSheetState();
}

class _PlaylistSheetState extends State<PlaylistSheet> {
  late final List<ListTile> content;
  late final StreamSubscription<bool> sub;

  void updateList() {
    for (int i = 0; i < content.length; i++) {
      content[i] = ListTile(
        key: ValueKey(i),
        visualDensity: VisualDensity.compact,
        leading: SizedBox(
          width: 32,
          child: Align(
            alignment: Alignment.center,
            child: Globals.audioHandler.playlist[i] == Globals.currentSongID
                ? const FaIcon(FontAwesomeIcons.headphonesSimple, size: 20)
                : Text((i + 1).padIntLeft(2, '0')),
          ),
        ),
        title: content[i].title,
        subtitle: content[i].subtitle,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    content = Globals.audioHandler.playlist
        .mapIndexed(
          (i, sId) => ListTile(
            key: ValueKey(i),
            visualDensity: VisualDensity.compact,
            titleAlignment: ListTileTitleAlignment.threeLine,
            leading: SizedBox(
              width: 32,
              child: Align(
                alignment: Alignment.center,
                child: Globals.currentSongID == sId
                    ? const FaIcon(FontAwesomeIcons.headphonesSimple, size: 20)
                    : Text((i + 1).padIntLeft(2, '0')),
              ),
            ),
            title: Text(
              Globals.allSongs.firstWhere((e) => e.id == sId).name,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              Globals.allSongs.firstWhere((e) => e.id == sId).artist,
            ),
          ),
        )
        .toList();
    sub = Globals.audioHandler.onSongChange.listen((event) {
      if (widget.scrollController.hasClients) {
        final count = Globals.audioHandler.playlist.length;
        final current = Globals.audioHandler.playlist.indexOf(Globals.currentSongID);
        final maxScrollExtent = widget.scrollController.position.maxScrollExtent;

        widget.scrollController.animateTo(
          maxScrollExtent * (current / count),
          duration: 100.ms,
          curve: Curves.easeIn,
        );
      }
      setState(updateList);
    });
  }

  @override
  void dispose() {
    sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        padding: const EdgeInsets.only(left: 10, right: 10, top: 30, bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
              child: Text(
                Globals.audioHandler.playlistDisplayName,
                style: bottomSheetTitle,
                textAlign: TextAlign.center,
                softWrap: true,
              ),
            ),
            Flexible(
              child: ReorderableListView(
                scrollController: widget.scrollController,
                onReorder: (oIdx, nIdx) {
                  if (nIdx > oIdx) nIdx--;
                  widget.onReorder?.call(oIdx, nIdx);
                  // final idx = content.
                  content.insert(nIdx, content.removeAt(oIdx));
                  updateList();
                  setState(() {});
                },
                proxyDecorator: (child, _, __) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Material(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      child: child,
                    ),
                  );
                },
                // shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                children: content,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
