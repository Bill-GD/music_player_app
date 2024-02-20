import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../artists/music_track.dart';
import '../globals/config.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../player/temp_player.dart';

class SongList extends StatefulWidget {
  const SongList({super.key});

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
                    style: const ButtonStyle(
                      splashFactory: NoSplash.splashFactory,
                      // backgroundColor: MaterialStatePropertyAll<Color>(
                      //   Theme.of(context).buttonTheme.colorScheme!.primaryContainer,
                      // ),
                      // visualDensity: VisualDensity.compact,
                      // padding: const MaterialStatePropertyAll<EdgeInsetsGeometry>(
                      //   EdgeInsets.only(left: 10, right: 20, top: 10, bottom: 10),
                      // ),
                    ),
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
              await getMusicData();
              if (context.mounted) {
                setState(() {});
              }
            },
            child: setOverscroll(
              overscroll: false,
              child: ListView.builder(
                itemCount: allMusicTracks.length,
                itemBuilder: (context, songIndex) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: ListTile(
                      leading: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.music_note_rounded, color: Theme.of(context).colorScheme.primary),
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
                            onPressed: () => showSongOptionsMenu(context, songIndex),
                          ),
                        ],
                      ),
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
