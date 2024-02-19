import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../globals/config.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../artists/music_track.dart';
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                child: Row(
                  children: [
                    Text(getSortOptionDisplayString()),
                    const Icon(CupertinoIcons.sort_down, size: 30),
                  ],
                ),
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: const Color(0x00000000),
                    useSafeArea: true,
                    enableDrag: false,
                    builder: (context) => bottomSheet(
                      title: const Text(
                        'Sort Songs',
                        style: bottomSheetTitle,
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                      content: [
                        sortingOptionTile(
                          title: 'By name',
                          sortOption: SortOptions.name,
                          setState: setState,
                          context: context,
                        ),
                        sortingOptionTile(
                          title: 'By the number of times played',
                          sortOption: SortOptions.mostPlayed,
                          setState: setState,
                          context: context,
                        ),
                        sortingOptionTile(
                          title: 'By adding time',
                          sortOption: SortOptions.recentlyAdded,
                          setState: setState,
                          context: context,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
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
                  return ListTile(
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [
                        Icon(Icons.music_note_rounded),
                      ],
                    ),
                    title: Text(
                      allMusicTracks[songIndex].trackName,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      allMusicTracks[songIndex].artist,
                      overflow: TextOverflow.ellipsis,
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
