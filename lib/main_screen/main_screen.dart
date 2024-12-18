import 'dart:io';

import 'package:flutter/material.dart';

import 'package:animations/animations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:theme_provider/theme_provider.dart';

import '../globals/functions.dart';
import '../globals/log_handler.dart';
import '../globals/music_track.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../music_downloader/music_downloader.dart';
import '../permission/storage_permission.dart';
import '../player/music_player.dart';
import '../player/player_utils.dart';
import '../search/search_page.dart';
import '../setting/setting.dart';
import '../songs/artist_songs.dart';
import 'album_list.dart';
import 'backup.dart';
import 'songs_list.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool isLoading = true, isDarkTheme = false;

  int _childParam = 0;

  void updateChildren() {
    _childParam = _childParam == 0 ? 1 : 0;
    setState(() {});
  }

  Future<PermissionStatus> _checkStoragePermission() async {
    PermissionStatus storagePermissionStatus = await Permission.manageExternalStorage.status;
    if (!storagePermissionStatus.isGranted && context.mounted) {
      LogHandler.log('Storage permission not granted, redirecting to request page');

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

  Divider listItemDivider() => const Divider(indent: 20, endIndent: 20);

  @override
  void initState() {
    super.initState();
    _checkStoragePermission().then((storagePermissionStatus) async {
      if (storagePermissionStatus.isGranted) {
        LogHandler.log('Storage permission is granted');
        await updateMusicData();
        sortAllSongs();
        setState(() => isLoading = false);
      }
    });
    Globals.audioHandler.player.processingStateStream.listen((state) {
      setState(() {});
    });
    Globals.audioHandler.player.positionStream.listen((current) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    Globals.audioHandler.player.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Globals.currentSongID < 0) {
      Globals.showMinimizedPlayer = false;
    }

    return SafeArea(
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.background,
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
                      color: Theme.of(context).colorScheme.onBackground,
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
                            Globals.packageInfo.appName,
                            style: bottomSheetTitle.copyWith(fontSize: 24),
                          ),
                        ),
                        ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          leading: FaIcon(FontAwesomeIcons.gear, color: iconColor(context)),
                          title: const Text(
                            'Settings',
                            style: bottomSheetTitle,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) => const SettingsPage(),
                                transitionsBuilder: (context, anim1, _, child) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(-1, 0),
                                      end: const Offset(0, 0),
                                    ).animate(anim1.drive(CurveTween(curve: Curves.decelerate))),
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        listItemDivider(),
                        ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          leading: Icon(Icons.download_rounded, color: iconColor(context)),
                          title: const Text('Download Music', style: bottomSheetTitle),
                          onTap: () async {
                            bool hasChange = await Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) => const MusicDownloader(),
                                transitionsBuilder: (context, anim1, _, child) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(-1, 0),
                                      end: const Offset(0, 0),
                                    ).animate(anim1.drive(CurveTween(curve: Curves.decelerate))),
                                    child: child,
                                  );
                                },
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          leading: FaIcon(Icons.file_copy, color: iconColor(context)),
                          title: const Text('Backup', style: bottomSheetTitle),
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) => const BackupScreen(),
                                transitionsBuilder: (context, anim1, _, child) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(-1, 0),
                                      end: const Offset(0, 0),
                                    ).animate(anim1.drive(CurveTween(curve: Curves.decelerate))),
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        listItemDivider(),
                        ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          leading: FaIcon(Icons.color_lens_rounded, color: iconColor(context)),
                          title: const Text('Change Theme', style: bottomSheetTitle),
                          onTap: () => ThemeProvider.controllerOf(context).nextTheme(),
                        ),
                        listItemDivider(),
                        ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          leading: FaIcon(Icons.logo_dev, color: iconColor(context)),
                          title: const Text('Log', style: bottomSheetTitle),
                          onTap: () async {
                            final logContent = File(Globals.logPath).readAsStringSync();
                            showGeneralDialog(
                              context: context,
                              transitionDuration: 300.ms,
                              transitionBuilder: (_, anim1, __, child) {
                                return ScaleTransition(
                                  scale: anim1.drive(CurveTween(curve: Curves.easeOutQuart)),
                                  child: child,
                                );
                              },
                              barrierDismissible: true,
                              barrierLabel: '',
                              pageBuilder: (context, _, __) {
                                return AlertDialog(
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                  ),
                                  title: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Application log',
                                      textAlign: TextAlign.center,
                                      style: bottomSheetTitle.copyWith(fontSize: 24),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  contentPadding: const EdgeInsets.only(left: 10, right: 10, top: 40),
                                  content: SingleChildScrollView(
                                    physics: const ClampingScrollPhysics(),
                                    child: Text(
                                      logContent,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  actionsAlignment: MainAxisAlignment.center,
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Ok'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
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
                          'v${Globals.packageInfo.version}',
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.5),
                          ),
                        ),
                        onTap: () => showGeneralDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierLabel: '',
                          transitionDuration: 300.ms,
                          transitionBuilder: (_, anim1, __, child) {
                            return ScaleTransition(
                              scale: anim1.drive(CurveTween(curve: Curves.easeOutQuart)),
                              alignment: Alignment.bottomLeft,
                              child: child,
                            );
                          },
                          pageBuilder: (context, _, __) => AboutDialog(
                            applicationName: Globals.packageInfo.appName,
                            applicationVersion: 'v${Globals.packageInfo.version}',
                          ),
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
                      ListView.builder(
                        itemCount: Globals.artists.length,
                        itemBuilder: (context, artistIndex) {
                          String artistName = Globals.artists.keys.elementAt(artistIndex);
                          return OpenContainer(
                            closedElevation: 0,
                            closedColor: Theme.of(context).colorScheme.background,
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
                                  '$songCount song${songCount > 1 ? "s" : ""}',
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
            visible: Globals.showMinimizedPlayer && Globals.currentSongID >= 0,
            child: Container(
              margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
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
                          Globals.currentSongID >= 0
                              ? Globals.allSongs.firstWhereOrNull((e) => e.id == Globals.currentSongID)!.name
                              : 'None',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          Globals.currentSongID >= 0
                              ? Globals.allSongs.firstWhereOrNull((e) => e.id == Globals.currentSongID)!.artist
                              : 'None',
                        ),
                        onTap: () async {
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
                          Globals.audioHandler.playing ? Globals.audioHandler.pause() : Globals.audioHandler.play();
                          setState(() {});
                        },
                        icon: Icon(
                          Globals.audioHandler.playing
                              ? Icons.pause_rounded //
                              : Icons.play_arrow_rounded,
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
