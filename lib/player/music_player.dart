import 'dart:async';
import 'dart:math';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../globals/music_track.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import 'player_utils.dart';

Future<Route> getMusicPlayerRoute(
  BuildContext context,
  String songPath,
) async {
  await Globals.audioHandler.setPlayerSong(songPath);
  return PageRouteBuilder(
    pageBuilder: (context, _, __) => MusicPlayerPage(songPath: songPath),
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

class MusicPlayerPage extends StatefulWidget {
  final String songPath;
  const MusicPlayerPage({super.key, required this.songPath});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  int currentDuration = 0, maxDuration = 0;
  late StreamSubscription<Duration> posStream;
  late StreamSubscription<bool> songChangeStream;
  late MusicTrack song;

  void updateSongInfo([String? songPath]) async {
    song = Globals.allSongs.firstWhere((e) => e.absolutePath == (songPath ?? Globals.currentSongPath));
    debugPrint('Update song info: ${song.trackName}');

    debugPrint('Updating player duration values');
    currentDuration = getCurrentDuration();
    maxDuration = getTotalDuration();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    // Initial player state, KEEP IT
    updateSongInfo(widget.songPath);

    songChangeStream = Globals.audioHandler.onSongChange.listen((changed) {
      if (changed) {
        debugPrint('Detected song change, updating player');
        updateSongInfo();
      }
    });
    posStream = Globals.audioHandler.player.positionStream.listen((current) {
      currentDuration = current.inMilliseconds;
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    posStream.cancel();
    songChangeStream.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
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
                  Globals.currentSongPath,
                  setState,
                  showDeleteOption: false,
                );
                setState(() {
                  song = Globals.allSongs.firstWhere((e) => e.absolutePath == song.absolutePath);
                });
              },
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // "Image"
                Container(
                  margin: const EdgeInsets.only(top: 25, bottom: 15),
                  padding: const EdgeInsets.all(65),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer,
                        Colors.white60,
                        Theme.of(context).colorScheme.primaryContainer,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    border: Border.all(
                      width: 0,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.music_note_rounded,
                    color: Colors.grey[850],
                    size: 180,
                  ),
                ),
                // Song info
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 0),
                        child: Text(
                          Globals.audioHandler.playlistName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ),
                      Text(
                        song.trackName,
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
                ProgressBar(
                  progress: min(maxDuration, currentDuration).ms,
                  total: maxDuration.ms,
                  thumbCanPaintOutsideBar: false,
                  timeLabelPadding: 5,
                  timeLabelLocation: TimeLabelLocation.below,
                  timeLabelType: TimeLabelType.totalTime,
                  timeLabelTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                  onSeek: (seekDuration) async {
                    currentDuration = min(maxDuration, seekDuration.inMilliseconds);
                    await Globals.audioHandler.seek(seekDuration);
                    setState(() {});
                  },
                ),
                // Controls
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 70),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: Globals.audioHandler.changeShuffleMode,
                        icon: Icon(
                          CupertinoIcons.shuffle,
                          color: Theme.of(context).colorScheme.primary,
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
                            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1)),
                        child: IconButton(
                          onPressed: () async {
                            Globals.audioHandler.playing
                                ? Globals.audioHandler.pause()
                                : Globals.audioHandler.play();
                            setState(() {});
                          },
                          icon: Icon(
                            Globals.audioHandler.playing
                                ? Icons.pause_rounded //
                                : Icons.play_arrow_rounded,
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
                        onPressed: Globals.audioHandler.changeRepeatMode,
                        icon: Icon(
                          CupertinoIcons.repeat,
                          color: Theme.of(context).colorScheme.primary,
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
