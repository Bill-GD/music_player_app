import 'dart:math';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../globals/extensions.dart';
import '../globals/globals.dart';
import '../globals/music_track.dart';
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
            final isNewTile = albumIndex == 0;
            final album = Globals.albums[min(isNewTile ? 0 : albumIndex - 1, Globals.albums.length - 1)];

            return OpenContainer(
              closedElevation: 0,
              closedColor: Theme.of(context).colorScheme.surface,
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
