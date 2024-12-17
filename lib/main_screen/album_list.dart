import 'dart:math';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../globals/functions.dart';
import '../globals/music_track.dart';
import '../globals/variables.dart';
import '../songs/album_songs.dart';
import 'add_album.dart';

class AlbumList extends StatefulWidget {
  const AlbumList({super.key});

  @override
  State<AlbumList> createState() => _AlbumListState();
}

class _AlbumListState extends State<AlbumList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await updateAlbumList();
          if (context.mounted) setState(() {});
        },
        child: ListView.builder(
          itemCount: Globals.albums.length + 1,
          itemBuilder: (context, albumIndex) {
            final album = Globals.albums[min(albumIndex, Globals.albums.length - 1)];
            final isNewTile = albumIndex == Globals.albums.length;

            return OpenContainer(
              closedElevation: 0,
              closedColor: Theme.of(context).colorScheme.background,
              openColor: Colors.transparent,
              transitionDuration: 400.ms,
              onClosed: (_) => setState(() {}),
              openBuilder: (_, __) {
                return isNewTile ? const AddAlbum() : AlbumSongs(albumID: album.id);
              },
              closedBuilder: (_, action) {
                final songCount = album.songs.length;
                if (songCount < 0) return const SizedBox.shrink();

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  title: isNewTile
                      ? const Icon(Icons.add_rounded)
                      : Text(
                          album.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                  subtitle: isNewTile
                      ? null
                      : Text(
                          '$songCount song${songCount > 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                  onTap: action,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
