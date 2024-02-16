import 'package:flutter/material.dart';

import '../globals/variables.dart';
import '../scroll_configuration.dart';

class ArtistList extends StatefulWidget {
  const ArtistList({super.key});

  @override
  State<ArtistList> createState() => _ArtistListState();
}

class _ArtistListState extends State<ArtistList> {
  @override
  Widget build(BuildContext context) {
    return setOverscroll(
      overscroll: false,
      child: ListView.builder(
        itemCount: artists.length,
        itemBuilder: (context, artistIndex) {
          String artistName = artists.keys.elementAt(artistIndex);
          int songCount = artists[artistName]?.length ?? 0;
          return ListTile(
            title: Text(artistName),
            subtitle: Text('$songCount song${songCount > 1 ? "s" : ""}'),
            onTap: () {
              // to song list of artist
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
                            itemCount: artists[artistName]!.length,
                            itemBuilder: (context, i) {
                              final song = artists[artistName]!.elementAt(i);
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
