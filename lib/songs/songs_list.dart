import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../globals/config.dart';
import '../globals/music_track.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../player/temp_player.dart';

class SongList extends StatefulWidget {
  final int param;
  const SongList({super.key, required this.param});

  @override
  State<SongList> createState() => _SongListState();
}

class _SongListState extends State<SongList> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    setState(() {});
    return Column(
      children: [
        // sorting header
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => TempPlayerDialog(
                          song: allMusicTracks[Random().nextInt(allMusicTracks.length)],
                        ),
                      ).then((value) {
                        audioPlayer.stop();
                      });
                    }),
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
                    onPressed: () => showSongSortingOptionsMenu(
                      context,
                      setState: setState,
                      ticker: this,
                    ),
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
                itemBuilder: (context, songIndex) {
                  return ListTile(
                    contentPadding: const EdgeInsets.only(left: 30, right: 10),
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => TempPlayerDialog(song: allMusicTracks[songIndex]),
                      ).then((value) {
                        audioPlayer.stop();
                      });
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
                              allMusicTracks[songIndex],
                            );
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
