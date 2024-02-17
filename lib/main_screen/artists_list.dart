import 'package:flutter/material.dart';

import '../globals/variables.dart';
import '../scroll_configuration.dart';
import '../songs_of_artist.dart';

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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ListView.builder(
          itemCount: artists.length,
          itemBuilder: (context, artistIndex) {
            String artistName = artists.keys.elementAt(artistIndex);
            int songCount = artists[artistName]?.length ?? 0;
            return ListTile(
              title: Text(artistName),
              subtitle: Text('$songCount song${songCount > 1 ? "s" : ""}'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ArtistSongsPage(artistName: artistName),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
