import 'package:flutter/material.dart';
import 'package:music_player_app/music_track.dart';
import 'package:music_player_app/storage_permission.dart';
import 'package:permission_handler/permission_handler.dart';

/// The main screen of the application. This screen has: settings, tabs (songs list, artists), app bar for current song...
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late List<MusicTrack> allMusicTracks;
  bool isLoading = true;

  void checkStoragePermission() async {
    PermissionStatus storagePermissionStatus = await Permission.manageExternalStorage.status;

    if (!storagePermissionStatus.isGranted && context.mounted) {
      debugPrint('Storage permission not granted, redirecting to request page');
      // await Navigator.pushNamed(context, '/storage_permission');

      await showDialog(
        context: context,
        builder: (_) => const StoragePermissionDialog(),
        barrierDismissible: false,
      );

      storagePermissionStatus = await Permission.manageExternalStorage.status;
      if (storagePermissionStatus.isGranted) {
        debugPrint('Storage permission is granted');
        getTrackFromStorage().then((value) {
          allMusicTracks = value;
          isLoading = false;
          setState(() {});
        });
      }
    } else {
      debugPrint('Storage permission already granted');
      if (storagePermissionStatus.isGranted) {
        getTrackFromStorage().then((value) {
          allMusicTracks = value;
          isLoading = false;
          setState(() {});
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    checkStoragePermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const CircularProgressIndicator(
              color: Colors.black,
            )
          : ListView.builder(
              itemCount: allMusicTracks.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(allMusicTracks[index].trackName),
                onTap: () => {},
              ),
            ),
    );
  }
}
