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
  final MusicTrack song;
  const MusicPlayerPage({super.key, required this.song});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> with TickerProviderStateMixin {
  int currentDuration = 0, maxDuration = 0;
  // bool isShuffle = true;
  late StreamSubscription<Duration> posStream;

  @override
  void initState() {
    super.initState();

    currentDuration = widget.song != currentSong ? 0 : getCurrentDuration();
    setPlayerSong(widget.song).then((value) => setState(() => maxDuration = value));

    showMinimizedPlayer = true;
    currentSong = widget.song;

    setState(() {});

    posStream = audioPlayer.positionStream.listen((current) {
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
            padding: const EdgeInsets.only(left: 10),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 40),
            onPressed: () async {
              await posStream.cancel();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          actions: [
            IconButton(
              padding: const EdgeInsets.only(right: 10),
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: () async {
                await showSongOptionsMenu(context, widget.song, showDeleteOption: false, this);
                setState(() {});
              },
            ),
          ],
        ),
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  children: [
                    Text(
                      widget.song.trackName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 30),
                    ),
                    Text(
                      widget.song.artist,
                      style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w400, fontSize: 20),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 60),
                padding: const EdgeInsets.all(50),
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
              ProgressBar(
                progress: min(maxDuration, currentDuration).ms,
                total: maxDuration.ms,
                timeLabelPadding: 20,
                timeLabelLocation: TimeLabelLocation.below,
                timeLabelType: TimeLabelType.totalTime,
                timeLabelTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                  fontWeight: FontWeight.bold,
                ),
                onSeek: (seekDuration) async {
                  currentDuration = min(maxDuration, seekDuration.inMilliseconds);
                  await audioPlayer.seek(seekDuration);
                  setState(() {});
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 40, bottom: 70),
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
                      onPressed: () => toPreviousSong(),
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
                          audioPlayer.playing ? pausePlayer() : playPlayer();
                          setState(() {});
                        },
                        icon: Icon(
                          audioPlayer.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 70,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => toNextSong(),
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
    );
  }
}
