import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:music_player_app/music_track.dart';
import 'package:music_player_app/storage_permission.dart';
// import 'package:theme_provider/theme_provider.dart';

/// The main screen of the application. This screen has: settings, tabs (songs list, artists), app bar for current song...
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

enum TrackPopupOptions { delete }

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late List<MusicTrack> allMusicTracks;
  Map<String, List<MusicTrack>> artists = {};
  bool isLoading = true, isDarkTheme = false, isPlaying = false;

  void _checkStoragePermission() async {
    PermissionStatus storagePermissionStatus = await Permission.manageExternalStorage.status;

    if (!storagePermissionStatus.isGranted && context.mounted) {
      debugPrint('Storage permission not granted, redirecting to request page');

      await showDialog(
        context: context,
        builder: (_) => const StoragePermissionDialog(),
        barrierDismissible: false,
      );

      storagePermissionStatus = await Permission.manageExternalStorage.status;
    }
    if (storagePermissionStatus.isGranted) {
      debugPrint('Storage permission is granted');
      _getMusicData();
    }
  }

  void _getMusicData() async {
    // get songs
    allMusicTracks = (await getTrackFromStorage())
      ..sort((track1, track2) => track1.trackName.compareTo(track2.trackName));

    // get artists
    artists = Map.fromEntries(allMusicTracks.groupListsBy((element) => element.artist).entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key)));

    isLoading = false;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _checkStoragePermission();
    _tabController = TabController(length: 2, vsync: this);
    // _tabController.addListener(() {
    //   debugPrint('${_tabController.index}');
    // });
  }

  // @override
  // void dispose() {
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                // go to settings page/sidebar
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
          title: TextField(
            autocorrect: false,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Search songs and artists',
              hintStyle: const TextStyle(
                decoration: TextDecoration.none,
              ),
              prefixIcon: const Icon(Icons.search_rounded),
              contentPadding: const EdgeInsets.all(0),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            textAlignVertical: TextAlignVertical.center,
            onTap: () {
              // go to search page/open search area
            },
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(child: Text('Songs')),
              Tab(child: Text('Artists')),
            ],
          ),
        ),
        drawer: Drawer(
          child: Column(
            children: const [
              DrawerHeader(
                child: Text('Menu'),
              ),
            ],
          ),
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.black,
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  ListView.builder(
                    itemCount: allMusicTracks.length,
                    itemBuilder: (context, index) {
                      TrackPopupOptions? selectedOption;
                      return ListTile(
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: const [
                            Icon(Icons.music_note_rounded),
                          ],
                        ),
                        title: Text(
                          allMusicTracks[index].trackName,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          allMusicTracks[index].artist,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // trailing: PopupMenuButton<TrackPopupOptions>(
                        //   initialValue: selectedOption,
                        //   onSelected: (item) {
                        //     debugPrint(item.name);
                        //   },
                        //   itemBuilder: (context) => <PopupMenuEntry<TrackPopupOptions>>[
                        //     const PopupMenuItem(
                        //       value: TrackPopupOptions.delete,
                        //       child: Text(
                        //         'Delete song',
                        //       ),
                        //     )
                        //   ],
                        // ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert_rounded),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: const Color(0x00000000),
                              useSafeArea: true,
                              // enableDrag: false,
                              builder: (context) => Container(
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                                  color: Colors.white,
                                ),
                                // alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 25),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.horizontal_rule_rounded),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 15),
                                        child: Text(
                                          allMusicTracks[index].trackName,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                          softWrap: true,
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 10),
                                          child: ListView(
                                            shrinkWrap: true,
                                            children: [
                                              ListTile(
                                                title: const Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                onTap: () => debugPrint('Delete song'),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        onTap: () => {},
                      );
                    },
                  ),
                  ListView.builder(
                    itemCount: artists.length,
                    itemBuilder: (context, index) {
                      String artistName = artists.keys.elementAt(index);
                      int songCount = artists[artistName]?.length ?? 0;
                      return ListTile(
                        title: Text(artistName),
                        subtitle: Text('$songCount song${songCount > 1 ? "s" : ""}'),
                        onTap: () => {},
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }
}
