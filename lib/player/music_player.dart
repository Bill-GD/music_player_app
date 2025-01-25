import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../globals/extensions.dart';
import '../globals/globals.dart';
import '../globals/music_track.dart';
import '../globals/widgets.dart';
import '../handlers/log_handler.dart';
import '../handlers/lyric_handler.dart';
import '../lyric/lyric_editor.dart';
import '../lyric/lyric_strip.dart';
import '../widgets/file_picker.dart';
import '../widgets/page_indicator.dart';
import '../widgets/playlist_sheet.dart';
import 'player_utils.dart';

Future<Route> getMusicPlayerRoute(BuildContext context, int songID) async {
  await Globals.audioHandler.setPlayerSong(songID, shouldPlay: !Globals.setDuplicate);
  return PageRouteBuilder(
    pageBuilder: (context, _, __) => MusicPlayer(songID: songID),
    transitionDuration: 400.ms,
    transitionsBuilder: (_, anim, __, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: const Offset(0, 0),
        ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(anim),
        child: child,
      );
    },
  );
}

class MusicPlayer extends StatefulWidget {
  final int songID;

  const MusicPlayer({super.key, required this.songID});

  @override
  State<MusicPlayer> createState() => _MusicPlayerState();
}

class _MusicPlayerState extends State<MusicPlayer> with TickerProviderStateMixin {
  int currentDuration = 0, maxDuration = 0;
  final List<StreamSubscription> subs = [];
  late final AnimationController animController;
  late final TabController tabController;
  late MusicTrack song;
  late Lyric lyric;

  void updateSongInfo([int? songID]) async {
    LogHandler.log("Updating player's UI");

    song = Globals.allSongs.firstWhere((e) => e.id == (songID ?? Globals.currentSongID));
    currentDuration = getCurrentDuration();
    maxDuration = getTotalDuration();
    updateLyric();
    setState(() {});
  }

  void updateLyric() {
    lyric = LyricHandler.getLyric(song.id, Globals.lyricPath + song.lyricPath) ??
        Lyric(
          songId: song.id,
          name: song.name,
          artist: song.artist,
          path: '${song.name}.lrc',
          list: [],
        );
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    updateSongInfo(widget.songID);

    animController = AnimationController(duration: 300.ms, reverseDuration: 300.ms, vsync: this);
    Globals.audioHandler.playing ? animController.forward(from: 0) : animController.reverse(from: 1);

    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() => setState(() {}));

    subs.add(Globals.audioHandler.onSongChange.listen((changed) {
      if (changed) updateSongInfo();
    }));
    subs.add(Globals.audioHandler.player.positionStream.listen((current) {
      currentDuration = current.inMilliseconds;
      setState(() {});
    }));
    subs.add(Globals.audioHandler.onPlayingChange.listen((playing) {
      if (playing) {
        animController.forward(from: 0);
      } else {
        animController.reverse(from: 1);
      }
    }));
    subs.add(Globals.lyricChangedController.stream.listen((_) {
      updateLyric();
    }));
  }

  @override
  void dispose() {
    for (final e in subs) {
      e.cancel();
    }
    tabController.dispose();
    animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.primaryContainer,
            ],
            stops: const [0.0, 0.8],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 40),
              onPressed: () async {
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () async {
                  await showSongOptionsMenu(
                    context,
                    Globals.currentSongID,
                    setState,
                    showDeleteOption: false,
                  );
                  song = Globals.allSongs.firstWhere((e) => e.path == song.path);
                  setState(() {});
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // "Image" & Lyric
                ConstrainedBox(
                  constraints: const BoxConstraints.tightFor(height: 320),
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            constraints: BoxConstraints.tight(const Size(320, 320)),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primaryContainer,
                                  Colors.white70,
                                  Theme.of(context).colorScheme.primaryContainer,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              border: Border.all(
                                width: 1,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.music_note_rounded,
                              color: Colors.grey[850],
                              size: 180,
                            ),
                          ),
                        ],
                      ),
                      song.lyricPath.isEmpty || lyric.list.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  style: const ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                                    side: WidgetStatePropertyAll(BorderSide(
                                      color: Colors.white54,
                                    )),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => LyricEditor(songID: song.id),
                                    ));
                                  },
                                  child: const Text(
                                    'Add lyric',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    var path = await FilePicker.open(
                                      context: context,
                                      rootDirectory: Directory(Globals.lyricPath),
                                      allowedExtensions: const ['lrc'],
                                    );
                                    if (path == null) return;
                                    path = path.split(Globals.lyricPath).last;
                                    if (song.lyricPath == path) return;

                                    LogHandler.log('Chosen new lrc: $path');
                                    song.lyricPath = path;
                                    await song.update();
                                    updateLyric();
                                  },
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(
                                      Theme.of(context).colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                  child: Text(
                                    'Select file',
                                    style: TextStyle(color: Theme.of(context).colorScheme.surface),
                                  ),
                                ),
                              ],
                            )
                          : const LyricStrip(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                  child: PageIndicator(pageCount: 2, currentIndex: tabController.index),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(5),
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoModalPopupRoute(builder: (context) => const PlaylistSheet()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.list_rounded),
                        const SizedBox(width: 5),
                        Text(
                          Globals.audioHandler.playlistDisplayName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                // Song info
                Padding(
                  padding: const EdgeInsets.only(bottom: 30, top: 12, left: 30, right: 30),
                  child: Column(
                    children: [
                      Text(
                        song.name,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                      ),
                      Text(
                        song.artist,
                        style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 18),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Stack(
                    children: [
                      ProgressBar(
                        progress: min(maxDuration, currentDuration).ms,
                        total: maxDuration.ms,
                        thumbCanPaintOutsideBar: false,
                        timeLabelPadding: 5,
                        timeLabelLocation: TimeLabelLocation.below,
                        timeLabelType: TimeLabelType.totalTime,
                        timeLabelTextStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        onSeek: (seekDuration) async {
                          currentDuration = min(maxDuration, seekDuration.inMilliseconds);
                          await Globals.audioHandler.seek(seekDuration);
                          setState(() {});
                        },
                      ),
                      Container(
                        height: 4.5,
                        width: 2,
                        margin: EdgeInsets.only(
                          top: 8,
                          left: Globals.audioHandler.minTimePercent * MediaQuery.of(context).size.width,
                        ),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                // Controls
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 70, left: 30, right: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          Globals.audioHandler.changeShuffleMode();
                          setState(() {});
                        },
                        icon: Icon(
                          CupertinoIcons.shuffle,
                          color: Globals.audioHandler.isShuffled
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          size: 30,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await Globals.audioHandler.skipToPrevious();
                        },
                        icon: Icon(
                          Icons.skip_previous_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 45,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                        ),
                        child: IconButton(
                          onPressed: () {
                            Globals.audioHandler.playing ? Globals.audioHandler.pause() : Globals.audioHandler.play();
                            setState(() {});
                          },
                          icon: AnimatedIcon(
                            icon: AnimatedIcons.play_pause,
                            progress: Tween<double>(begin: 0.0, end: 1.0).animate(animController),
                            color: Theme.of(context).colorScheme.primary,
                            size: 70,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await Globals.audioHandler.skipToNext();
                        },
                        icon: Icon(
                          Icons.skip_next_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 45,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await Globals.audioHandler.changeRepeatMode();
                          setState(() {});
                        },
                        icon: Icon(
                          Globals.audioHandler.repeatMode == AudioServiceRepeatMode.one
                              ? CupertinoIcons.repeat_1
                              : CupertinoIcons.repeat,
                          color: Globals.audioHandler.repeatMode == AudioServiceRepeatMode.none
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                              : Theme.of(context).colorScheme.primary,
                          size: 35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
