import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../globals/music_track.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../player/music_player.dart';

class SongList extends StatefulWidget {
  final int param;
  final void Function(void Function()) updateParent;

  const SongList({super.key, required this.param, required this.updateParent});

  @override
  State<SongList> createState() => _SongListState();
}

class _SongListState extends State<SongList> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // shuffle playback
                TextButton.icon(
                    style: const ButtonStyle(splashFactory: NoSplash.splashFactory),
                    icon: FaIcon(
                      Icons.play_circle_filled_rounded,
                      size: 30,
                      color: iconColor(context),
                    ),
                    label: Text(
                      'Shuffle playback',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: iconColor(context),
                      ),
                    ),
                    onPressed: () async {
                      final randomSong = Globals.allSongs[Random().nextInt(Globals.allSongs.length)].id;
                      Globals.audioHandler.registerPlaylist(
                        'All songs',
                        Globals.allSongs.map((e) => e.id).toList(),
                        randomSong,
                      );
                      await Navigator.of(context).push(
                        await getMusicPlayerRoute(
                          context,
                          randomSong,
                        ),
                      );
                      setState(() {});
                    }),
                // sort songs
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: TextButton.icon(
                    style: const ButtonStyle(
                      splashFactory: NoSplash.splashFactory,
                    ),
                    icon: Icon(
                      CupertinoIcons.sort_down,
                      size: 30,
                      color: iconColor(context),
                    ),
                    label: Text(
                      Config.getSortOptionString(),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: iconColor(context),
                      ),
                    ),
                    onPressed: () async {
                      await getBottomSheet(
                        context,
                        const Text(
                          'Sort Songs',
                          style: bottomSheetTitle,
                          textAlign: TextAlign.center,
                          softWrap: true,
                        ),
                        [
                          ListTile(
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            leading: FaIcon(FontAwesomeIcons.arrowDownAZ, color: iconColor(context)),
                            title: const Text('By name', style: bottomSheetText),
                            onTap: () {
                              setState(() => sortAllSongs(SortOptions.name));
                              Navigator.of(context).pop();
                              Config.saveConfig();
                            },
                          ),
                          ListTile(
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            leading: FaIcon(FontAwesomeIcons.arrowDown91, color: iconColor(context)),
                            title: const Text('By the number of times played', style: bottomSheetText),
                            onTap: () {
                              setState(() => sortAllSongs(SortOptions.mostPlayed));
                              Navigator.of(context).pop();
                              Config.saveConfig();
                            },
                          ),
                          ListTile(
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            leading: FaIcon(FontAwesomeIcons.clock, color: iconColor(context)),
                            title: const Text('By adding time', style: bottomSheetText),
                            onTap: () {
                              setState(() => sortAllSongs(SortOptions.recentlyAdded));
                              Navigator.of(context).pop();
                              Config.saveConfig();
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        // song list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await updateMusicData();
              sortAllSongs();
              if (context.mounted) {
                setState(() {});
              }
            },
            child: ListView.builder(
              itemCount: Globals.allSongs.length,
              itemBuilder: (context, songIndex) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Icon(
                        Icons.music_note_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                title: Text(
                  Globals.allSongs[songIndex].name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  Globals.allSongs[songIndex].artist,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                onTap: () async {
                  Globals.audioHandler.registerPlaylist(
                    'All songs',
                    Globals.allSongs.map((e) => e.id).toList(),
                    Globals.allSongs[songIndex].id,
                  );
                  await Navigator.of(context).push(
                    await getMusicPlayerRoute(
                      context,
                      Globals.allSongs[songIndex].id,
                    ),
                  );
                  setState(() {});
                  widget.updateParent(() {});
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Visibility(
                      visible: Config.currentSortOption == SortOptions.mostPlayed,
                      child: Text('${Globals.allSongs[songIndex].timeListened}'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded),
                      onPressed: () async {
                        await showSongOptionsMenu(
                          context,
                          Globals.allSongs[songIndex].id,
                          setState,
                        );
                        setState(() {});
                        widget.updateParent(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
