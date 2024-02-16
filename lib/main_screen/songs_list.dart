import 'package:flutter/material.dart';

import '../globals/config.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../music_track.dart';
import '../player/temp_player.dart';
import '../scroll_configuration.dart';

class SongList extends StatefulWidget {
  const SongList({super.key});

  @override
  State<SongList> createState() => _SongListState();
}

class _SongListState extends State<SongList> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // sorting header
        SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                splashColor: const Color(0x00000000),
                icon: const Icon(Icons.sort_rounded, size: 30),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: const Color(0x00000000),
                    useSafeArea: true,
                    builder: (context) => Container(
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.white,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            modalBottomSheetHandleIcon,
                            const Text(
                              'Sort Songs',
                              style: modalBottomSheetText,
                              textAlign: TextAlign.center,
                              softWrap: true,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: ListView(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    ListTile(
                                      title: const Text(
                                        'By name',
                                        style: modalBottomSheetText,
                                      ),
                                      onTap: () {
                                        sortAllTracks(SongSorting.name);
                                        setState(() {});
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    ListTile(
                                      title: const Text(
                                        'By the number of times played',
                                        style: modalBottomSheetText,
                                      ),
                                      onTap: () {
                                        sortAllTracks(SongSorting.mostPlayed);
                                        setState(() {});
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    ListTile(
                                      title: const Text(
                                        'By adding time',
                                        style: modalBottomSheetText,
                                      ),
                                      onTap: () {
                                        sortAllTracks(SongSorting.recentlyAdded);
                                        setState(() {});
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        // song list
        Expanded(
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
                      builder: (context) => TempPlayerDialog(songIndex: songIndex),
                    ).then((value) {
                      audioPlayer.stop();
                    });
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Visibility(
                        visible: currentSortType == SongSorting.mostPlayed,
                        child: Text('${allMusicTracks[songIndex].timeListened}'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: const Color(0x00000000),
                            useSafeArea: true,
                            builder: (context) => Container(
                              margin: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: Colors.white,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 25),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    modalBottomSheetHandleIcon,
                                    Text(
                                      allMusicTracks[songIndex].trackName,
                                      style: modalBottomSheetText,
                                      textAlign: TextAlign.center,
                                      softWrap: true,
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: ListView(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          children: [
                                            ListTile(
                                              title: const Text(
                                                'Delete',
                                                style: modalBottomSheetText,
                                              ),
                                              onTap: () => debugPrint('Delete song'),
                                            ),
                                            ListTile(
                                              title: const Text(
                                                'Song Info',
                                                style: modalBottomSheetText,
                                              ),
                                              onTap: () => debugPrint('Check song info'),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
