import 'dart:math';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../globals/extensions.dart';
import '../globals/functions.dart';
import '../globals/log_handler.dart';
import '../globals/music_track.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../player/music_player.dart';
import 'add_album_song.dart';
import 'album_info.dart';

class AlbumSongs extends StatefulWidget {
  final int albumID;

  const AlbumSongs({super.key, required this.albumID});

  @override
  State<AlbumSongs> createState() => _AlbumSongsState();
}

class _AlbumSongsState extends State<AlbumSongs> {
  late Album album;
  List<MusicTrack> songs = [];
  late int totalSongCount;

  void getSongs() {
    album = Globals.albums.firstWhere((e) => e.id == widget.albumID);
    songs = [];
    for (final sId in album.songs) {
      final s = Globals.allSongs.firstWhereOrNull((s) => s.id == sId);
      if (s != null) songs.add(s);
    }
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
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
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
                await getBottomSheet(
                  context,
                  Text(
                    album.name,
                    style: bottomSheetTitle,
                    textAlign: TextAlign.center,
                    softWrap: true,
                  ),
                  [
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      leading: Icon(Icons.info_outline_rounded, color: iconColor(context)),
                      title: const Text('Album info', style: bottomSheetText),
                      onTap: () async {
                        bool? needsUpdate = await Navigator.of(context).push(
                          PageRouteBuilder<bool>(
                            transitionDuration: 400.ms,
                            transitionsBuilder: (_, anim, __, child) {
                              return ScaleTransition(
                                alignment: Alignment.bottomCenter,
                                scale: Tween<double>(
                                  begin: 0,
                                  end: 1,
                                ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(anim),
                                child: child,
                              );
                            },
                            pageBuilder: (_, __, ___) => AlbumInfo(
                              albumID: widget.albumID,
                            ),
                          ),
                        );
                        if (needsUpdate == true) {
                          setState(() {
                            updateAlbumList();
                          });
                          if (context.mounted) Navigator.of(context).pop();
                        }
                      },
                    ),
                    if (album.id != 1)
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        leading: Icon(Icons.delete_rounded, color: iconColor(context)),
                        title: const Text('Delete album', style: bottomSheetText),
                        onTap: () async {
                          bool deleteAlbum = false;

                          await dialogWithActions<bool>(
                            context,
                            icon: Icon(
                              Icons.warning_rounded,
                              color: Theme.of(context).colorScheme.error,
                              size: 30,
                            ),
                            title: 'Delete Album',
                            titleFontSize: 24,
                            textContent: dedent('''
                                  This CANNOT be undone.
                                  Are you sure you want to delete
                    
                                  ${album.name}'''),
                            contentFontSize: 16,
                            time: 300.ms,
                            actions: [
                              TextButton(
                                onPressed: Navigator.of(context).pop,
                                child: const Text('No'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  deleteAlbum = true;
                                  await Globals.albums.firstWhereOrNull((a) => a.id == widget.albumID)?.delete();
                                  await updateAlbumList();
                                  if (context.mounted) Navigator.of(context).pop(true);
                                },
                                child: const Text('Yes'),
                              ),
                            ],
                          );
                          if (deleteAlbum && context.mounted) {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          }
                        },
                      )
                  ],
                );
              },
              icon: const Icon(Icons.more_vert_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  style: const ButtonStyle(splashFactory: NoSplash.splashFactory),
                  icon: FaIcon(
                    FontAwesomeIcons.shuffle,
                    size: 25,
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
                          if (!Globals.audioHandler.isShuffled) {
                            Globals.audioHandler.changeShuffleMode();
                          }
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
                TextButton.icon(
                  style: const ButtonStyle(splashFactory: NoSplash.splashFactory),
                  icon: FaIcon(
                    Icons.play_circle_filled_rounded,
                    size: 30,
                    color: iconColor(context, songs.isEmpty ? 0.5 : 1),
                  ),
                  label: Text(
                    'Play sequentially',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: iconColor(context, songs.isEmpty ? 0.5 : 1),
                    ),
                  ),
                  onPressed: songs.isEmpty
                      ? null
                      : () async {
                          final first = songs[0].id;
                          if (Globals.audioHandler.isShuffled) {
                            Globals.audioHandler.changeShuffleMode();
                          }
                          // get artistName or album.name depend on category
                          Globals.audioHandler.registerPlaylist(
                            album.name,
                            songs.map((e) => e.id).toList(),
                            first,
                          );
                          await Navigator.of(context).push(
                            await getMusicPlayerRoute(context, first),
                          );
                        },
                ),
              ],
            ),
            Expanded(
              child: album.id == 1
                  ? ListView.builder(
                      itemCount: totalSongCount,
                      itemBuilder: (context, songIndex) {
                        final song = songs[songIndex];
                        return songTile(song, songIndex);
                      },
                    )
                  : ReorderableListView.builder(
                      itemCount: totalSongCount + (album.id == 1 ? 0 : 1),
                      onReorder: (oIdx, nIdx) {
                        if (nIdx > oIdx) nIdx--;
                        oIdx--;
                        nIdx--;
                        if (nIdx > totalSongCount || album.id == 1 || nIdx == oIdx || nIdx < 0) return;
                        final oldSongId = songs[oIdx].id, newSongId = songs[nIdx].id;
                        LogHandler.log('Reorder album: $oIdx (id=$oldSongId) -> $nIdx (id=$newSongId)');
                        album.songs.insert(nIdx, album.songs.removeAt(oIdx));
                        album.update();
                        setState(getSongs);
                      },
                      proxyDecorator: (child, _, __) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Material(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: child,
                          ),
                        );
                      },
                      itemBuilder: (context, songIndex) {
                        final isNewTile = album.id == 1 ? false : songIndex == 0;
                        final song = isNewTile ? null : songs[songIndex - (album.id == 1 ? 0 : 1)];

                        if (isNewTile) {
                          if (album.id == 1) return const SizedBox.shrink(key: ValueKey(-1));

                          // add to album
                          return OpenContainer(
                            key: const ValueKey(-1),
                            closedElevation: 0,
                            closedColor: Theme.of(context).colorScheme.surface,
                            openColor: Colors.transparent,
                            transitionDuration: 400.ms,
                            onClosed: (_) => setState(getSongs),
                            openBuilder: (_, __) => AddAlbumSong(
                              albumID: widget.albumID,
                            ),
                            closedBuilder: (_, action) {
                              return ListTile(
                                title: const Icon(Icons.add_rounded),
                                onTap: action,
                              );
                            },
                          );
                        }
                        // song tile
                        return songTile(song!, songIndex);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  ListTile songTile(MusicTrack song, int songIndex) {
    return ListTile(
      key: ValueKey(song.id),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text((songIndex + (album.id == 1 ? 1 : 0)).toString().padLeft(2, '0')),
          ],
        ),
      ),
      title: Text(
        song.name,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        song.artist,
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
          song.id,
        );
        await Navigator.of(context).push(
          await getMusicPlayerRoute(
            context,
            song.id,
          ),
        );
        setState(() {});
      },
      trailing: IconButton(
        icon: const Icon(Icons.more_vert_rounded),
        onPressed: () async {
          await showSongOptionsMenu(
            context,
            song.id,
            setState,
            showDeleteOption: false,
            moreActions: [
              if (album.id != 1)
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  leading: Icon(Icons.delete_rounded, color: iconColor(context)),
                  title: const Text('Remove from playlist', style: bottomSheetText),
                  onTap: () async {
                    bool songRemoved = false;
                    await dialogWithActions<bool>(
                      context,
                      title: 'Remove from album',
                      titleFontSize: 24,
                      textContent: dedent("""
                                      Are you sure you want to remove
  
                                      ${song.name}
  
                                      from album '${album.name}'"""),
                      contentFontSize: 16,
                      time: 300.ms,
                      actions: [
                        TextButton(
                          child: const Text('No'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        TextButton(
                          child: const Text('Yes'),
                          onPressed: () async {
                            songRemoved = true;
                            await song.removeFromPlaylist(widget.albumID);
                            if (mounted) Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                    if (songRemoved) {
                      await updateAlbumList();
                      if (mounted) Navigator.of(context).pop();
                    }
                  },
                ),
            ],
          );
          getSongs();
          setState(() {});
        },
      ),
    );
  }
}
