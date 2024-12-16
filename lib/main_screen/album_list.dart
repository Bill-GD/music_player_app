import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../globals/functions.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../songs/album_songs.dart';

class AlbumList extends StatefulWidget {
  const AlbumList({super.key});

  @override
  State<AlbumList> createState() => _AlbumListState();
}

class _AlbumListState extends State<AlbumList> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  style: const ButtonStyle(splashFactory: NoSplash.splashFactory),
                  icon: FaIcon(
                    Icons.add_rounded,
                    size: 30,
                    color: iconColor(context),
                  ),
                  label: Text(
                    'Add new album',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: iconColor(context),
                    ),
                  ),
                  onPressed: () async {
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: Globals.albums.length,
            itemBuilder: (context, albumIndex) {
              final album = Globals.albums[albumIndex];

              return OpenContainer(
                closedElevation: 0,
                closedColor: Theme.of(context).colorScheme.background,
                openColor: Colors.transparent,
                transitionDuration: 400.ms,
                onClosed: (_) => setState(() {}),
                openBuilder: (context, action) => AlbumSongs(albumID: albumIndex),
                closedBuilder: (context, action) {
                  final songCount = album.songs.length;
                  if (songCount <= 0) return const SizedBox.shrink();

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    title: Text(
                      album.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
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
      ],
    );
  }
}
