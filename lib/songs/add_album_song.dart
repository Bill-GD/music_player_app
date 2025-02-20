import 'package:flutter/material.dart';

import '../globals/extensions.dart';
import '../globals/globals.dart';
import '../globals/music_track.dart';
import '../globals/utils.dart';
import '../globals/widgets.dart';

class AddAlbumSong extends StatefulWidget {
  final int albumID;

  const AddAlbumSong({super.key, required this.albumID});

  @override
  State<AddAlbumSong> createState() => _AddAlbumSongState();
}

class _AddAlbumSongState extends State<AddAlbumSong> {
  late final Album album;
  late final List<MusicTrack> availableSongs;
  late final List<int> order;
  final searchController = TextEditingController();
  bool canAdd = false;
  int songAddedCount = 0;
  String searchText = '';

  @override
  void initState() {
    super.initState();
    album = Globals.albums.firstWhere((e) => e.id == widget.albumID);
    availableSongs = Globals.allSongs
        .where((e) => !album.songs.contains(e.id)) //
        .toList()
      ..sort((a, b) => a.id - b.id);
    order = List.generate(availableSongs.length, (_) => -1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 40),
        ),
        centerTitle: true,
        title: const Text(
          'Add new song',
          style: TextStyle(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        actions: [
          IconButton(
            onPressed: canAdd
                ? () async {
                    // LogHandler.log('$order');
                    // LogHandler.log('${availableSongs.map((e) => e.id)}');
                    final unknown = Globals.albums.firstWhere((e) => e.id == 1);
                    for (final i in range(1, songAddedCount)) {
                      final si = availableSongs[order.indexOf(i)].id;
                      Globals.allSongs.firstWhereOrNull((e) => e.id == si)?.hasAlbum = true;
                      album.songs.add(si);
                      unknown.songs.remove(si);
                    }
                    await album.update();
                    await unknown.update();
                    await updateAlbumList();
                    if (context.mounted) Navigator.of(context).pop();
                  }
                : null,
            icon: const Icon(Icons.check_rounded, size: 30),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: TextField(
              controller: searchController,
              onChanged: (val) {
                searchText = val;
                setState(() {});
              },
              decoration: textFieldDecoration(
                context,
                labelText: 'Search',
                hintText: 'Search names and artists',
                fillColor: Theme.of(context).colorScheme.surface,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                itemCount: availableSongs.length,
                itemBuilder: (context, songIndex) {
                  final song = availableSongs[songIndex];
                  final tile = CheckboxListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    value: order[songIndex] != -1,
                    secondary: Text(
                      order[songIndex] < 0 ? '' : order[songIndex].padIntLeft(2, '0'),
                      style: const TextStyle(fontSize: 14),
                    ),
                    title: Text(
                      song.name,
                      // '${song.id}. ${song.name}',
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
                    onChanged: (val) {
                      if (val == true) {
                        order[songIndex] = ++songAddedCount;
                      } else {
                        // order.map((e) => e > songAddedCount ? e - 1 : e);
                        for (int i = 0; i < order.length; i++) {
                          if (order[i] > order[songIndex]) order[i]--;
                        }
                        order[songIndex] = -1;
                        songAddedCount--;
                      }
                      canAdd = order.any((e) => e != -1);
                      setState(() {});
                    },
                  );
                  if (searchText.isEmpty) return tile;
                  return song.name.toLowerCase().contains(searchText.toLowerCase()) ||
                          song.artist.toLowerCase().contains(searchText.toLowerCase())
                      ? tile
                      : const SizedBox.shrink();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
