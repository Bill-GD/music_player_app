import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../globals/music_track.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../player/music_player.dart';

class CategorySongsPage extends StatefulWidget {
  final String artistName, albumName;
  const CategorySongsPage({super.key, this.artistName = '', this.albumName = ''});

  @override
  State<CategorySongsPage> createState() => _CategorySongsPageState();
}

class _CategorySongsPageState extends State<CategorySongsPage> {
  late List<MusicTrack> songs;

  late bool categoryIsArtist;

  void getSongs() {
    if (categoryIsArtist) {
      songs = Globals.allSongs.where((song) => song.artist == widget.artistName).toList()
        ..sort(
          (track1, track2) => track1.trackName.toLowerCase().compareTo(track2.trackName.toLowerCase()),
        );
    } else {
      songs = Globals.allSongs.where((song) => song.album == widget.albumName).toList()
        ..sort(
          (track1, track2) => track1.trackName.toLowerCase().compareTo(track2.trackName.toLowerCase()),
        );
    }
  }

  @override
  void initState() {
    super.initState();
    categoryIsArtist = widget.artistName.isNotEmpty;
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
            categoryIsArtist ? widget.artistName : widget.albumName,
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
                final randomSong = songs[Random().nextInt(songs.length)].absolutePath;
                // get artistName or albumName depend on category
                Globals.audioHandler.registerPlaylist(
                  categoryIsArtist ? widget.artistName : widget.albumName,
                  songs.map((e) => e.absolutePath).toList(),
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
                      songs[songIndex].trackName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${songs[songIndex].artist} | ${songs[songIndex].album}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    onTap: () async {
                      Globals.audioHandler.registerPlaylist(
                        categoryIsArtist ? widget.artistName : widget.albumName,
                        songs.map((e) => e.absolutePath).toList(),
                        songs[songIndex].absolutePath,
                      );
                      await Navigator.of(context).push(
                        await getMusicPlayerRoute(
                          context,
                          songs[songIndex].absolutePath,
                        ),
                      );
                      setState(() {});
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert_rounded),
                      onPressed: () async {
                        await showSongOptionsMenu(
                          context,
                          songs[songIndex].absolutePath,
                          setState,
                          isCategoryArtist: categoryIsArtist,
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
