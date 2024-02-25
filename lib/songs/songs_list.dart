import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../globals/config.dart';
import '../globals/music_track.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';

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
                      await Navigator.of(context).push(
                        getMusicPlayerRoute(
                          context,
                          allMusicTracks[Random().nextInt(allMusicTracks.length)].absolutePath,
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
                      getSortOptionDisplayString(),
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
            child: StretchingOverscrollIndicator(
              axisDirection: AxisDirection.down,
              child: ListView.builder(
                itemCount: allMusicTracks.length,
                itemBuilder: (context, songIndex) => ListTile(
                  contentPadding: const EdgeInsets.only(left: 30, right: 10),
                  leading: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_note_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                  title: Text(
                    allMusicTracks[songIndex].trackName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    allMusicTracks[songIndex].artist,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  onTap: () async {
                    await Navigator.of(context).push(
                      getMusicPlayerRoute(context, allMusicTracks[songIndex].absolutePath),
                    );
                    setState(() {});
                    widget.updateParent(() {});
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Visibility(
                        visible: currentSortOption == SortOptions.mostPlayed,
                        child: Text('${allMusicTracks[songIndex].timeListened}'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded),
                        onPressed: () async {
                          await showSongOptionsMenu(
                            context,
                            allMusicTracks[songIndex].absolutePath,
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
        ),
      ],
    );
  }
}
