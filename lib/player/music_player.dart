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

class MusicPlayerPage extends StatefulWidget {
  final String songPath;
  const MusicPlayerPage({super.key, required this.songPath});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  int currentDuration = 0, maxDuration = 0;
  // bool isShuffle = true;
  late StreamSubscription<Duration> posStream;
  late MusicTrack song;

  @override
  void initState() {
    super.initState();

    song = Globals.allSongs.firstWhere((e) => e.absolutePath == widget.songPath);

    currentDuration = widget.songPath != Globals.currentSongPath ? 0 : getCurrentDuration();
    Globals.audioHandler.setPlayerSong(widget.songPath).then((value) => setState(() => maxDuration = value));

    Globals.showMinimizedPlayer = true;
    Globals.currentSongPath = widget.songPath;

    setState(() {});

    posStream = Globals.audioHandler.player.positionStream.listen((current) {
      currentDuration = current.inMilliseconds;
      setState(() {});
    });
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
              await posStream.cancel();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: () async {
                await showSongOptionsMenu(
                  context,
                  widget.songPath,
                  showDeleteOption: false,
                );
                setState(() {
                  song = Globals.allSongs.firstWhere((e) => e.absolutePath == widget.songPath);
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
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 25, bottom: 20),
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    children: [
                      Text(
                        song.trackName,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
                      ),
                      Text(
                        song.artist,
                        style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w400, fontSize: 16),
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
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 70),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          CupertinoIcons.shuffle,
                          color: Theme.of(context).colorScheme.primary,
                          size: 30,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Globals.audioHandler.skipToPrevious(),
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
                            Globals.audioHandler.player.playing
                                ? Globals.audioHandler.pause()
                                : Globals.audioHandler.play();
                            setState(() {});
                          },
                          icon: Icon(
                            Globals.audioHandler.player.playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 70,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Globals.audioHandler.skipToPrevious(),
                        icon: Icon(
                          Icons.skip_next_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 45,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
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
