import 'package:flutter/material.dart';

import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../player/temp_player.dart';

class ArtistSongsPage extends StatefulWidget {
  final String artistName;
  const ArtistSongsPage({super.key, required this.artistName});

  @override
  State<ArtistSongsPage> createState() => _ArtistSongsPageState();
}

class _ArtistSongsPageState extends State<ArtistSongsPage> {
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
          itemCount: artists[widget.artistName]!.length,
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
                artists[widget.artistName]![songIndex].trackName,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                artists[widget.artistName]![songIndex].artist,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => TempPlayerDialog(song: artists[widget.artistName]![songIndex]),
                ).then((value) {
                  audioPlayer.stop();
                });
              },
              trailing: IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () =>
                    showSongOptionsMenu(context, artists[widget.artistName]![songIndex], setState),
              ),
            );
          },
        ),
      ),
    );
  }
}
