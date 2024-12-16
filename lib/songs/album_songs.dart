import 'dart:math';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:music_player_app/globals/functions.dart';
import 'package:music_player_app/songs/add_album_song.dart';

import '../globals/music_track.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../player/music_player.dart';

class AlbumSongs extends StatefulWidget {
  final int albumID;

  const AlbumSongs({super.key, required this.albumID});

  @override
  State<AlbumSongs> createState() => _AlbumSongsState();
}

class _AlbumSongsState extends State<AlbumSongs> {
  String albumName = '';
  late List<MusicTrack> songs;
  late final totalSongCount;

  void getSongs() {
    songs = Globals.albums[widget.albumID].songs.map((e) => Globals.allSongs.firstWhere((s) => s.id == e)).toList();
    albumName = Globals.albums[widget.albumID].name;
    totalSongCount = songs.length;
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
            albumName,
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
                  albumName,
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
              child: ListView.builder(
                itemCount: totalSongCount + 1,
                itemBuilder: (context, songIndex) {
                  final isNewTile = songIndex == totalSongCount;

                  return isNewTile
                      // add to album
                      ? OpenContainer(
                          closedElevation: 0,
                          closedColor: Theme.of(context).colorScheme.background,
                          openColor: Colors.transparent,
                          transitionDuration: 400.ms,
                          onClosed: (_) => setState(() {}),
                          openBuilder: (_, __) => const AddAlbumSong(),
                          closedBuilder: (_, action) {
                            return ListTile(
                              title: const Icon(Icons.add_rounded),
                              onTap: action,
                            );
                          },
                        )
                      // song
                      : ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          leading: isNewTile
                              ? null
                              : Padding(
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
                              albumName,
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
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
