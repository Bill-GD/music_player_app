import 'package:flutter/material.dart';

import '../globals/variables.dart';
import 'songs_of_artist.dart';

class ArtistList extends StatefulWidget {
  const ArtistList({super.key});

  @override
  State<ArtistList> createState() => _ArtistListState();
}

class _ArtistListState extends State<ArtistList> {
  @override
  Widget build(BuildContext context) {
    return StretchingOverscrollIndicator(
      axisDirection: AxisDirection.down,
      child: ListView.builder(
        itemCount: artists.length,
        itemBuilder: (context, artistIndex) {
          String artistName = artists.keys.elementAt(artistIndex);
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: Text(
              artistName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${artists[artistName]} song${artists[artistName]! > 1 ? "s" : ""}',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ArtistSongsPage(artistName: artistName),
                ),
              );
              setState(() {});
            },
          );
        },
      ),
    );
  }
}
