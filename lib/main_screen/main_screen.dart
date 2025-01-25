import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../globals/extensions.dart';
import '../globals/music_track.dart';
import '../globals/utils.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../handlers/log_handler.dart';
import '../permission/storage_permission.dart';
import '../player/music_player.dart';
import '../player/player_utils.dart';
import '../search/search.dart';
import '../songs/artist_songs.dart';
import 'album_list.dart';
import 'drawer.dart';
import 'song_list.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  bool isLoading = true, isDarkTheme = false;
  late final AnimationController animController;
  int _childParam = 0;

  @override
  void initState() {
    super.initState();
    animController = AnimationController(duration: 300.ms, reverseDuration: 300.ms, vsync: this);
    Globals.audioHandler.playing ? animController.forward(from: 0) : animController.reverse(from: 1);

    _checkStoragePermission().then((storagePermissionStatus) async {
      if (storagePermissionStatus.isGranted) {
        LogHandler.log('Storage permission is granted');
        await updateMusicData();
        sortAllSongs();

        if (Config.backupOnLaunch && mounted) backupData(context, File(Globals.backupPath));
        await Globals.audioHandler.recoverSavedPlaylist();

        setState(() => isLoading = false);
        LogHandler.log('App is ready');
      }
    });
    Globals.audioHandler.player.processingStateStream.listen((state) {
      setState(() {});
    });
    Globals.audioHandler.player.positionStream.listen((current) {
      setState(() {});
    });
    Globals.audioHandler.onPlayingChange.listen((playing) {
      if (playing) {
        animController.forward(from: 0);
      } else {
        animController.reverse(from: 1);
      }
    });
    checkNewVersion();
  }

  @override
  void dispose() {
    super.dispose();
    Globals.audioHandler.player.dispose();
  }

  void updateChildren() {
    _childParam = _childParam == 0 ? 1 : 0;
    setState(() {});
  }

  Future<PermissionStatus> _checkStoragePermission() async {
    PermissionStatus storagePermissionStatus = await Permission.manageExternalStorage.status;
    if (!storagePermissionStatus.isGranted && context.mounted) {
      LogHandler.log('Storage permission not granted, redirecting to request page');

      if (Config.backupOnLaunch) {
        Config.backupOnLaunch = false;
        Config.saveConfig();
      }

      if (mounted) {
        await showDialog(
          context: context,
          builder: (_) => const StoragePermissionDialog(),
          barrierDismissible: false,
        );
      }

      storagePermissionStatus = await Permission.manageExternalStorage.status;
    }
    return storagePermissionStatus;
  }

  Future<void> checkNewVersion() async {
    final hasInternet = await checkInternetConnection();
    if (!hasInternet) return;
    final tags = (await getAllTags()).map((e) => e.$1).toList();
    if (tags.isEmpty || 'v${Globals.appVersion}' == tags.last) return;
    if (mounted) {
      showPopupMessage(
        context,
        title: 'New version available',
        content: 'Current version: v${Globals.appVersion}\n'
            'New version: ${tags.last}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Container(
              height: AppBar().preferredSize.height * 0.65,
              margin: const EdgeInsets.only(right: 15),
              child: TextField(
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
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  fillColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
                ),
                onTap: () async {
                  await Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, _, __) => const SearchScreen(),
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
                    ),
                  );
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
                Tab(child: Text('Albums')),
              ],
            ),
          ),
          drawer: const MainDrawer(),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : StretchingOverscrollIndicator(
                  axisDirection: AxisDirection.right,
                  child: TabBarView(
                    children: [
                      // song list
                      SongList(param: _childParam, updateParent: setState),
                      // artist list
                      ListView.builder(
                        itemCount: Globals.artists.length,
                        itemBuilder: (context, artistIndex) {
                          String artistName = Globals.artists.keys.elementAt(artistIndex);
                          return OpenContainer(
                            closedElevation: 0,
                            closedColor: Theme.of(context).colorScheme.surface,
                            openColor: Colors.transparent,
                            transitionDuration: 400.ms,
                            onClosed: (_) => setState(() {}),
                            openBuilder: (context, action) => ArtistSongs(artistName: artistName),
                            closedBuilder: (context, action) {
                              final songCount = Globals.artists[artistName];
                              if (songCount == null) return const SizedBox.shrink();
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                                title: Text(
                                  artistName,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  '$songCount song${songCount > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                onTap: action,
                              );
                            },
                          );
                        },
                      ),
                      const AlbumList(),
                    ],
                  ),
                ),
          // mini player
          bottomNavigationBar: Visibility(
            visible: Globals.showMinimizedPlayer,
            child: Container(
              margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 5,
                    offset: Offset(0, 5),
                  )
                ],
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
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: Icon(
                            Icons.music_note_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          Globals.currentSongID >= 0 && !isLoading
                              ? Globals.allSongs.firstWhere((e) => e.id == Globals.currentSongID).name
                              : 'None',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          Globals.currentSongID >= 0 && !isLoading
                              ? Globals.allSongs.firstWhere((e) => e.id == Globals.currentSongID).artist
                              : 'None',
                        ),
                        onTap: isLoading
                            ? null
                            : () async {
                                await Navigator.of(context).push(
                                  await getMusicPlayerRoute(
                                    context,
                                    Globals.currentSongID,
                                  ),
                                );
                                setState(() {});
                              },
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Globals.audioHandler.skipToPrevious(),
                    icon: Icon(
                      Icons.skip_previous_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        value: getCurrentDuration() / getTotalDuration(),
                      ),
                      IconButton(
                        onPressed: () {
                          if (Globals.setDuplicate) {
                            Globals.audioHandler.setPlayerSong(Globals.currentSongID);
                          } else {
                            Globals.audioHandler.playing ? Globals.audioHandler.pause() : Globals.audioHandler.play();
                          }
                          setState(() {});
                        },
                        icon: AnimatedIcon(
                          icon: AnimatedIcons.play_pause,
                          progress: Tween<double>(begin: 0.0, end: 1.0).animate(animController),
                          color: Theme.of(context).colorScheme.primary,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Globals.audioHandler.skipToNext(),
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
