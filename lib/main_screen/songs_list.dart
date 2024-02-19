import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: TextButton(
                  style: const ButtonStyle(
                    splashFactory: NoSplash.splashFactory,
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          getSortOptionDisplayString(),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: iconColor(context),
                          ),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.sort_down,
                        size: 30,
                        color: iconColor(context),
                      ),
                    ],
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
