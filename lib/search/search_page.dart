import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../player/music_player.dart';

Future<Route> getSearchPageRoute(
  BuildContext context,
) async {
  return PageRouteBuilder(
    pageBuilder: (context, _, __) => const SearchPage(),
    transitionDuration: 400.ms,
    transitionsBuilder: (_, anim, __, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: const Offset(0, 0),
        ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(anim),
        child: child,
      );
    },
  );
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPage();
}

class _SearchPage extends State<SearchPage> {
  List<String> filteredSongs = [];

  @override
  void initState() {
    super.initState();
  }

  void searchSongs(String keyword) {
    setState(() {
      filteredSongs = Globals.allSongs
          .where((song) =>
              song.trackName.toLowerCase().contains(keyword.toLowerCase()) ||
              song.artist.toLowerCase().contains(keyword.toLowerCase()))
          .map((e) => e.absolutePath)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 40),
          onPressed: () async {
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
        title: Container(
          height: AppBar().preferredSize.height * 0.65,
          margin: const EdgeInsets.only(right: 15),
          child: TextField(
            autofocus: true,
            onChanged: searchSongs,
            decoration: textFieldDecoration(
              context,
              hintText: 'Search songs and artists',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              fillColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        itemCount: filteredSongs.length,
        itemBuilder: (context, index) {
          final song = Globals.allSongs.firstWhere((e) => e.absolutePath == filteredSongs[index]);
          return ListTile(
            // contentPadding: const EdgeInsets.symmetric(horizontal: 30),
            title: Text(
              song.trackName,
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
            onTap: () async {
              FocusManager.instance.primaryFocus?.unfocus();
              Globals.audioHandler.registerPlaylist(
                'All songs',
                Globals.allSongs.map((e) => e.absolutePath).toList(),
                song.absolutePath,
              );
              await Navigator.of(context).push(
                await getMusicPlayerRoute(
                  context,
                  song.absolutePath,
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
