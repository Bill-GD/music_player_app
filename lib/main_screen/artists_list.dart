import 'package:flutter/material.dart';
import 'package:music_player_app/music_track.dart';
import 'package:music_player_app/scroll_configuration.dart';

class ArtistList extends StatefulWidget {
  final Map<String, List<MusicTrack>> artists;
  const ArtistList({super.key, required this.artists});

  @override
  State<ArtistList> createState() => _ArtistListState();
}

class _ArtistListState extends State<ArtistList> {
  @override
  Widget build(BuildContext context) {
    return setOverscroll(
      overscroll: false,
      child: ListView.builder(
        itemCount: widget.artists.length,
        itemBuilder: (context, artistIndex) {
          String artistName = widget.artists.keys.elementAt(artistIndex);
          int songCount = widget.artists[artistName]?.length ?? 0;
          return ListTile(
            title: Text(artistName),
            subtitle: Text('$songCount song${songCount > 1 ? "s" : ""}'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return Dialog(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        setOverscroll(
                          overscroll: false,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: widget.artists[artistName]!.length,
                            itemBuilder: (context, i) {
                              final song = widget.artists[artistName]!.elementAt(i);
                              return ListTile(
                                title: Text(song.trackName),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
