import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:theme_provider/theme_provider.dart';

import '../globals/config.dart';
import '../globals/music_track.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../music_downloader/music_downloader.dart';
import '../permission/storage_permission.dart';
import '../player/music_player.dart';
import '../songs/songs_list.dart';
import 'songs_of_artist.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  bool isLoading = true, isDarkTheme = false;

  int _childParam = 0;

  void updateChildren() {
    _childParam = _childParam == 0 ? 1 : 0;
    setState(() {});
  }

  Future<PermissionStatus> _checkStoragePermission() async {
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
    return storagePermissionStatus;
  }

  Divider listItemDivider() => const Divider(indent: 20, endIndent: 20);

  @override
  void initState() {
    super.initState();
    _checkStoragePermission().then((storagePermissionStatus) async {
      if (storagePermissionStatus.isGranted) {
        debugPrint('Storage permission is granted');
        await updateMusicData();
        sortAllSongs(SortOptions.name);
        setState(() => isLoading = false);
      }
    });
    audioPlayer = AudioPlayer();
    audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        setState(() {});
      }
    });
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
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  fillColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
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
          drawer: Drawer(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.only(left: 15, bottom: 10, top: 5),
                          title: Text(
                            packageInfo.appName,
                            style: bottomSheetTitle.copyWith(fontSize: 24),
                          ),
                        ),
                        ListTile(
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          leading: Icon(CupertinoIcons.gear_alt_fill, color: iconColor(context)),
                          title: const Text(
                            'Settings',
                            style: bottomSheetTitle,
                          ),
                          onTap: () {
                            debugPrint('To app settings page');
                          },
                        ),
                        listItemDivider(),
                        ListTile(
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          leading: Icon(Icons.download_rounded, color: iconColor(context)),
                          title: const Text('Download Music', style: bottomSheetTitle),
                          onTap: () async {
                            bool hasChange = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MusicDownloader(),
                              ),
                            );
                            if (hasChange) {
                              await updateMusicData();
                              sortAllSongs();
                              updateChildren();
                            }
                          },
                        ),
                        listItemDivider(),
                        ListTile(
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          leading: FaIcon(Icons.color_lens_rounded, color: iconColor(context)),
                          title: const Text('Change Theme', style: bottomSheetTitle),
                          onTap: () => ThemeProvider.controllerOf(context).nextTheme(),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, bottom: 4),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: GestureDetector(
                        child: Text(
                          'v${packageInfo.version}',
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.5),
                          ),
                        ),
                        onTap: () => showAboutDialog(
                          context: context,
                          applicationName: packageInfo.appName,
                          applicationVersion: 'v${packageInfo.version}',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : StretchingOverscrollIndicator(
                  axisDirection: AxisDirection.right,
                  child: TabBarView(
                    children: [
                      // song list
                      SongList(param: _childParam, updateParent: setState),
                      // artist list
                      StretchingOverscrollIndicator(
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
                      ),
                    ],
                  ),
                ),
          bottomNavigationBar: Visibility(
            visible: showMinimizedPlayer && currentSong != null,
            child: Container(
              margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: Icon(
                          Icons.music_note_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          currentSong?.trackName ?? 'None',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(currentSong?.artist ?? 'None'),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => MusicPlayerPage(song: currentSong!),
                            ),
                          );
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      debugPrint('Previous song');
                    },
                    icon: Icon(
                      Icons.skip_previous_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
                    ),
                    child: IconButton(
                      onPressed: () async {
                        audioPlayer.playing ? audioPlayer.pause() : audioPlayer.play();
                        setState(() {});
                      },
                      icon: Icon(
                        audioPlayer.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 30,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      debugPrint('Next song');
                    },
                    icon: Icon(
                      Icons.skip_next_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
