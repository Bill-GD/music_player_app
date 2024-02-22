import 'dart:async';
import 'dart:math';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../globals/music_track.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';

class MusicPlayerPage extends StatefulWidget {
  final MusicTrack song;
  const MusicPlayerPage({super.key, required this.song});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  int currentDuration = 0, maxDuration = 0;
  bool isShuffle = false;
  late StreamSubscription<Duration> posStream;

  @override
  void initState() {
    super.initState();

    currentDuration = currentSong == null ? 0 : audioPlayer.position.inMilliseconds;
    maxDuration = currentSong == null ? 0 : audioPlayer.duration!.inMilliseconds;
    if (currentSong == null || currentSong != widget.song) {
      audioPlayer
          .setAudioSource(
        audioPlayer.audioSource ?? AudioSource.uri(Uri.parse(Uri.encodeComponent(widget.song.absolutePath))),
        initialPosition: Duration.zero,
        preload: true,
      )
          .then((value) {
        maxDuration = value!.inMilliseconds;
        setState(() {});
      });
    }

    showMinimizedPlayer = true;
    currentSong = widget.song;

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
            onPressed: () async {
              await posStream.cancel();
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 40,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: () async {
                await showSongOptionsMenu(context, widget.song);
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
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  children: [
                    Text(
                      widget.song.trackName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 40),
                    ),
                    Text(
                      widget.song.artist,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              ProgressBar(
                progress: Duration(milliseconds: min(maxDuration, currentDuration)),
                total: Duration(milliseconds: maxDuration),
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
                padding: const EdgeInsets.only(top: 50),
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
                      onPressed: () {
                        debugPrint('Previous song');
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
                          if (currentDuration >= maxDuration) {
                            audioPlayer.seek(Duration.zero);
                            currentDuration = 0;
                          }
                          if (currentDuration <= 0) {
                            widget.song.timeListened++;
                            await saveSongsToStorage();
                          }
                          audioPlayer.playing ? audioPlayer.pause() : audioPlayer.play();
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
                      onPressed: () {
                        debugPrint('Next song');
                      },
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
