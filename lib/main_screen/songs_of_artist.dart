import 'package:flutter/material.dart';

import '../globals/music_track.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../player/music_player.dart';

class ArtistSongsPage extends StatefulWidget {
  final String artistName;
  const ArtistSongsPage({super.key, required this.artistName});

  @override
  State<ArtistSongsPage> createState() => _ArtistSongsPageState();
}

class _ArtistSongsPageState extends State<ArtistSongsPage> {
  late List<MusicTrack> songs;

  void getSongs() {
    songs = allMusicTracks.where((song) => song.artist == widget.artistName).toList()
      ..sort(
        (track1, track2) => track1.trackName.toLowerCase().compareTo(track2.trackName.toLowerCase()),
      );
  }

  @override
  void initState() {
    super.initState();
    getSongs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
        centerTitle: true,
        title: Text(
          widget.artistName,
          style: const TextStyle(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
      ),
      body: StretchingOverscrollIndicator(
        axisDirection: AxisDirection.down,
        child: ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, songIndex) {
            return ListTile(
              leading: Padding(
                padding: const EdgeInsets.only(left: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text((songIndex + 1).toString().padLeft(2, '0')),
                  ],
                ),
              ),
              title: Text(
                songs[songIndex].trackName,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                songs[songIndex].artist,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MusicPlayerPage(song: songs[songIndex]),
                  ),
                );
                setState(() {});
              },
              trailing: IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () async {
                  await showSongOptionsMenu(context, songs[songIndex]);
                  getSongs();
                  if (songs.isEmpty && context.mounted) {
                    Navigator.of(context).pop();
                  } else {
                    setState(() {});
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}