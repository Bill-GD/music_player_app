import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

import '../artists/artists_list.dart';
import '../artists/music_track.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../permission/storage_permission.dart';
import 'extra_menu.dart';
import 'songs_list.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
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
      await getMusicData();
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _checkStoragePermission();
    audioPlayer = AudioPlayer();
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
            backgroundColor: Theme.of(context).colorScheme.background,
            title: Container(
              height: AppBar().preferredSize.height * 0.65,
              margin: const EdgeInsets.only(right: 15),
              child: TextFormField(
                readOnly: true,
                decoration: textFieldDecoration(
                  context,
                  hintText: 'Search songs and artists',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                onTap: () {
                  // go to search page/open search area
                  debugPrint('Search');
                },
              ),
            ),
            bottom: TabBar(
              enableFeedback: false,
              splashFactory: NoSplash.splashFactory,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: UnderlineTabIndicator(
                borderRadius: BorderRadius.circular(10),
                insets: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                borderSide: BorderSide(
                  width: 3,
                  color: Theme.of(context).colorScheme.primary,
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
            ),
          ),
          drawer: const ExtraMenu(),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : const StretchingOverscrollIndicator(
                  axisDirection: AxisDirection.right,
                  child: TabBarView(
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
