import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'package:music_player_app/music_track.dart';
import 'package:music_player_app/player/temp_player.dart';
import 'package:music_player_app/scroll_configuration.dart';

class SongList extends StatefulWidget {
  final List<MusicTrack> allMusicTracks;
  final AudioPlayer player;
  const SongList({super.key, required this.allMusicTracks, required this.player});

  @override
  State<SongList> createState() => _SongListState();
}

class _SongListState extends State<SongList> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                splashColor: const Color(0x00000000),
                icon: const Icon(Icons.sort),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: const Color(0x00000000),
                    useSafeArea: true,
                    builder: (context) => Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                        color: Colors.white,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.horizontal_rule_rounded,
                              size: 40,
                            ),
                            const Text(
                              'Sort Songs',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
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
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      onTap: () {
                                        widget.allMusicTracks.sort(
                                            (track1, track2) => track1.trackName.compareTo(track2.trackName));
                                        setState(() {});
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    ListTile(
                                      title: const Text(
                                        'By the number of times played',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      onTap: () {
                                        debugPrint('Sort time played');
                                        widget.allMusicTracks.sort((track1, track2) =>
                                            track2.timeListened.compareTo(track1.timeListened));
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
        Expanded(
          child: setOverscroll(
            overscroll: false,
            child: ListView.builder(
              itemCount: widget.allMusicTracks.length,
              itemBuilder: (context, songIndex) {
                // TrackPopupOptions? selectedOption;
                return ListTile(
                  leading: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Icon(Icons.music_note_rounded),
                    ],
                  ),
                  title: Text(
                    widget.allMusicTracks[songIndex].trackName,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    widget.allMusicTracks[songIndex].artist,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: const Color(0x00000000),
                        useSafeArea: true,
                        builder: (context) => Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                            color: Colors.white,
                          ),
                          // alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.horizontal_rule_rounded,
                                  size: 40,
                                ),
                                Text(
                                  widget.allMusicTracks[songIndex].trackName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          onTap: () => debugPrint('Delete song'),
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
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => TempPlayerDialog(
                        player: widget.player,
                        song: widget.allMusicTracks[songIndex],
                      ),
                    ).then((value) {
                      // posStream?.cancel();
                      widget.player.stop();
                      // setState(() {});
                    });
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
