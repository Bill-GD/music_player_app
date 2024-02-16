import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

import '../globals/variables.dart';
import '../music_track.dart';
import '../permission/storage_permission.dart';
import '../scroll_configuration.dart';
import 'artists_list.dart';
import 'extra_menu.dart';
import 'songs_list.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  // late TabController _tabController;

  bool isLoading = true, isDarkTheme = false;

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
    await getTrackFromStorage();

    // get artists
    groupMusicByArtist();

    isLoading = false;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _checkStoragePermission();
    audioPlayer = AudioPlayer();
    // _tabController = TabController(
    //   initialIndex: 0,
    //   length: 2,
    //   vsync: this,
    // );
  }

  @override
  void dispose() {
    super.dispose();
    audioPlayer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
            title: TextField(
              readOnly: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Search songs and artists',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.all(0),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onTap: () {
                // go to search page/open search area
                debugPrint('Search');
              },
            ),
            bottom: TabBar(
              indicatorSize: TabBarIndicatorSize.label,
              indicator: UnderlineTabIndicator(
                borderRadius: BorderRadius.circular(10),
                insets: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                borderSide: const BorderSide(
                  width: 3,
                  color: Colors.white,
                ),
              ),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
              ),
              tabs: const [
                Tab(child: Text('Songs')),
                Tab(child: Text('Artists')),
              ],
              labelPadding: EdgeInsets.zero,
            ),
          ),
          drawer: const ExtraMenu(),
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.black,
                  ),
                )
              : setOverscroll(
                  overscroll: false,
                  child: const TabBarView(
                    children: [
                      SongList(),
                      ArtistList(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
