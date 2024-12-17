import 'dart:math';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../globals/functions.dart';
import '../globals/music_track.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../player/music_player.dart';
import 'add_album_song.dart';

class AlbumSongs extends StatefulWidget {
  final int albumID;

  const AlbumSongs({super.key, required this.albumID});

  @override
  State<AlbumSongs> createState() => _AlbumSongsState();
}

class _AlbumSongsState extends State<AlbumSongs> {
  late Album album;
  late List<MusicTrack> songs;
  late final int totalSongCount;

  void getSongs() {
    album = Globals.albums.firstWhere((e) => e.id == widget.albumID);
    songs = album.songs
        .map(
          (e) => Globals.allSongs.firstWhere((s) => s.id == e),
        )
        .toList();
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
            album.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          actions: [
            IconButton(
              onPressed: () async {
                bool deleteAlbum = false;

                await showGeneralDialog<bool>(
                  context: context,
                  transitionDuration: 300.ms,
                  barrierDismissible: true,
                  barrierLabel: '',
                  transitionBuilder: (_, anim1, __, child) {
                    return ScaleTransition(
                      scale: anim1.drive(CurveTween(curve: Curves.easeOutQuart)),
                      alignment: Alignment.bottomCenter,
                      child: child,
                    );
                  },
                  pageBuilder: (context, _, __) {
                    return AlertDialog(
                      contentPadding: const EdgeInsets.only(left: 10, right: 10, top: 30),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      icon: Icon(
                        Icons.warning_rounded,
                        color: Theme.of(context).colorScheme.error,
                        size: 30,
                      ),
                      title: const Center(
                        child: Text(
                          'Delete Album',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      content: Text(
                        dedent('''
                        This CANNOT be undone.
                        Are you sure you want to delete
          
                        ${album.name}'''),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      actionsAlignment: MainAxisAlignment.spaceAround,
                      actions: [
                        TextButton(
                          onPressed: Navigator.of(context).pop,
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () {
                            deleteAlbum = true;
                            Navigator.of(context).pop(true);
                          },
                          child: const Text('Yes'),
                        ),
                      ],
                    );
                  },
                );
                if (deleteAlbum) {
                  await Globals.albums.firstWhereOrNull((a) => a.id == widget.albumID)?.delete();
                  await updateAlbumList();
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.delete_rounded),
            )
          ],
        ),
        body: Column(
          children: [
            TextButton.icon(
              style: const ButtonStyle(splashFactory: NoSplash.splashFactory),
              icon: FaIcon(
                Icons.play_circle_filled_rounded,
                size: 30,
                color: iconColor(context, songs.isEmpty ? 0.5 : 1),
              ),
              label: Text(
                'Shuffle playback',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: iconColor(context, songs.isEmpty ? 0.5 : 1),
                ),
              ),
              onPressed: songs.isEmpty
                  ? null
                  : () async {
                      final randomSong = songs[Random().nextInt(songs.length)].id;
                      // get artistName or album.name depend on category
                      Globals.audioHandler.registerPlaylist(
                        album.name,
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
                              album.name,
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: Text('${widget.albumID}'),
        ),
      ),
    );
  }
}
