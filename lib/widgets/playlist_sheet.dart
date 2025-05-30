import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../globals/extensions.dart';
import 'song_options.dart';
import '../globals/globals.dart';
import '../globals/widgets.dart';
import '../handlers/log_handler.dart';

class PlaylistSheet extends StatefulWidget {
  const PlaylistSheet({super.key});

  @override
  State<PlaylistSheet> createState() => _PlaylistSheetState();
}

class _PlaylistSheetState extends State<PlaylistSheet> {
  late final ScrollController scrollController = ScrollController();
  List<ListTile> content = [];
  late final StreamSubscription<bool> sub;

  void updateList() {
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
                child: sId == Globals.currentSongID
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
            trailing: Globals.currentSongID != sId
                ? IconButton(
                    icon: const Icon(Icons.playlist_add_rounded),
                    onPressed: () {
                      final playlist = Globals.audioHandler.playlist;

                      final currentIdx = playlist.indexOf(Globals.currentSongID);
                      final selectedIdx = playlist.indexOf(sId);

                      LogHandler.log('Adding song #$selectedIdx to play next');

                      playlist.insert(currentIdx + 1, sId);
                      playlist.removeAt(selectedIdx);

                      Globals.audioHandler.savePlaylist(Globals.currentSongID);

                      setState(updateList);
                    },
                  )
                : null,
          ),
        )
        .toList();
  }

  void scroll(Duration time) {
    if (!scrollController.hasClients) return;
    final count = Globals.audioHandler.playlist.length;
    final current = Globals.audioHandler.playlist.indexOf(Globals.currentSongID);
    final maxScrollExtent = scrollController.position.maxScrollExtent;

    scrollController.animateTo(
      maxScrollExtent * (current / count),
      duration: time,
      curve: Curves.easeIn,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => scroll(100.ms));

    updateList();

    sub = Globals.audioHandler.onSongChange.listen((event) {
      scroll(300.ms);
      setState(updateList);
    });
  }

  @override
  void dispose() {
    sub.cancel();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
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
              child: Scrollbar(
                controller: scrollController,
                interactive: true,
                thumbVisibility: true,
                radius: const Radius.circular(16),
                thickness: min(content.length ~/ 3, 8).toDouble(),
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ReorderableListView(
                    scrollController: scrollController,
                    onReorder: (oIdx, nIdx) {
                      if (nIdx > oIdx) nIdx--;
                      LogHandler.log(
                        'Reorder: old: $oIdx (id=${Globals.audioHandler.playlist[oIdx]}) - new: $nIdx (id=${Globals.audioHandler.playlist[nIdx]})',
                      );
                      Globals.audioHandler.moveSong(oIdx, nIdx);
                      // final idx = content.
                      content.insert(nIdx, content.removeAt(oIdx));
                      updateList();
                      setState(() {});
                    },
                    proxyDecorator: (child, _, __) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Material(
                          color: Theme.of(context).colorScheme.tertiaryContainer,
                          child: child,
                        ),
                      );
                    },
                    // shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    children: content,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
