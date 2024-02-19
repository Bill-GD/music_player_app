import 'package:flutter/material.dart';

import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../player/temp_player.dart';

class ArtistSongsPage extends StatelessWidget {
  final String artistName;
  const ArtistSongsPage({super.key, required this.artistName});

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
          artistName,
          textAlign: TextAlign.center,
        ),
      ),
      body: setOverscroll(
          overscroll: false,
          child: ListView.builder(
            itemCount: artists[artistName]!.length,
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
                  artists[artistName]![songIndex].trackName,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  artists[artistName]![songIndex].artist,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => TempPlayerDialog(song: artists[artistName]![songIndex]),
                  ).then((value) {
                    audioPlayer.stop();
                  });
                },
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  onPressed: () => showSongOptionsMenu(context, songIndex),
                ),
              );
            },
          )),
    );
  }
}
