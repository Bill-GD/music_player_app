import 'dart:math';

import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../globals/music_track.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../player/music_player.dart';

class ArtistSongs extends StatefulWidget {
  final String artistName;

  const ArtistSongs({super.key, required this.artistName});

  @override
  State<ArtistSongs> createState() => _ArtistSongsState();
}

class _ArtistSongsState extends State<ArtistSongs> {
  late List<MusicTrack> songs;

  void getSongs() {
    songs = Globals.allSongs.where((s) => s.artist == widget.artistName).toList()
      ..sort(
        (track1, track2) => track1.name.toLowerCase().compareTo(track2.name.toLowerCase()),
      );
  }

  @override
  void initState() {
    super.initState();
    getSongs();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 40),
          ),
          centerTitle: true,
          title: Text(
            widget.artistName,
            style: const TextStyle(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ),
        body: Column(
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
              onPressed: () async {
                final randomSong = songs[Random().nextInt(songs.length)].id;
                // get artistName or albumName depend on category
                Globals.audioHandler.registerPlaylist(
                  widget.artistName,
                  songs.map((e) => e.id).toList(),
                  randomSong,
                );
                await Navigator.of(context).push(
                  await getMusicPlayerRoute(
                    context,
                    randomSong,
                  ),
                );
              },
            ),
            Expanded(
              child: StretchingOverscrollIndicator(
                axisDirection: AxisDirection.down,
                child: ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, songIndex) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text((songIndex + 1).toString().padLeft(2, '0')),
                        ],
                      ),
                    ),
                    title: Text(
                      songs[songIndex].name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      songs[songIndex].artist,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    onTap: () async {
                      Globals.audioHandler.registerPlaylist(
                        widget.artistName,
                        songs.map((e) => e.id).toList(),
                        songs[songIndex].id,
                      );
                      await Navigator.of(context).push(
                        await getMusicPlayerRoute(
                          context,
                          songs[songIndex].id,
                        ),
                      );
                      setState(() {});
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert_rounded),
                      onPressed: () async {
                        await showSongOptionsMenu(
                          context,
                          songs[songIndex].id,
                          setState,
                        );
                        getSongs();
                        if (songs.isEmpty && context.mounted) {
                          Navigator.of(context).pop();
                        } else {
                          setState(() {});
                        }
                      },
                    ),
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
