import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../globals/functions.dart';
import '../globals/log_handler.dart';
import '../globals/music_track.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import 'player_utils.dart';

Future<Route> getMusicPlayerRoute(
  BuildContext context,
  int songID,
) async {
  await Globals.audioHandler.setPlayerSong(songID);
  return PageRouteBuilder(
    pageBuilder: (context, _, __) => MusicPlayerPage(songID: songID),
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
  final int songID;
  const MusicPlayerPage({super.key, required this.songID});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> with TickerProviderStateMixin {
  int currentDuration = 0, maxDuration = 0;
  late StreamSubscription<Duration> posStream;
  late StreamSubscription<bool> songChangeStream;
  late MusicTrack song;
  late final AnimationController animController;
  late final ScrollController playlistScrollController;
  AnimatedIconData playIcon = Globals.audioHandler.playing
      ? AnimatedIcons.pause_play //
      : AnimatedIcons.play_pause;

  void updateSongInfo([int? songID]) async {
    song = Globals.allSongs.firstWhere((e) => e.id == (songID ?? Globals.currentSongID));
    LogHandler.log('Update song info: ${song.trackName}');

    LogHandler.log('Updating player duration values');
    currentDuration = getCurrentDuration();
    maxDuration = getTotalDuration();
    animController = AnimationController(duration: 500.ms, reverseDuration: 500.ms, vsync: this);
    playlistScrollController = ScrollController();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    // Initial player state, KEEP IT
    updateSongInfo(widget.songID);

    songChangeStream = Globals.audioHandler.onSongChange.listen((changed) {
      if (changed) {
        LogHandler.log('Detected song change, updating player');
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
    posStream.cancel();
    songChangeStream.cancel();
    animController.dispose();
    playlistScrollController.dispose();
    super.dispose();
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
                  Globals.currentSongID,
                  setState,
                  showDeleteOption: false,
                );
                setState(() {
                  song = Globals.allSongs.firstWhere((e) => e.path == song.path);
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
                // playlist list
                InkWell(
                  borderRadius: BorderRadius.circular(5),
                  onTap: () {
                    playlistSheet(
                      context,
                      title: Text(
                        Globals.audioHandler.playlistName,
                        style: bottomSheetTitle,
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                      content: Globals.audioHandler.playlist
                          .mapIndexed(
                            (i, sId) => ListTile(
                              key: ValueKey('$i'),
                              visualDensity: VisualDensity.compact,
                              titleAlignment: ListTileTitleAlignment.threeLine,
                              leading: SizedBox(
                                width: 32,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Globals.currentSongID == sId
                                      ? const FaIcon(FontAwesomeIcons.headphonesSimple, size: 20)
                                      : Text((i + 1).padIntLeft(2, '0')),
                                ),
                              ),
                              title: Text(
                                Globals.allSongs.firstWhere((e) => e.id == sId).trackName,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                Globals.allSongs.firstWhere((e) => e.id == sId).artist,
                              ),
                            ),
                          )
                          .toList(),
                      scrollController: playlistScrollController,
                      onReorder: (o, n) {
                        LogHandler.log(
                          'Old song id: ${Globals.audioHandler.playlist[o]}',
                        );
                        LogHandler.log(
                          'New song id: ${Globals.audioHandler.playlist[n]}',
                        );
                        Globals.audioHandler.moveSong(o, n);
                      },
                    );

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (playlistScrollController.hasClients) {
                        final count = Globals.audioHandler.playlist.length;
                        final current = Globals.audioHandler.playlist.indexOf(Globals.currentSongID);
                        final maxScrollExtent = playlistScrollController.position.maxScrollExtent;

                        playlistScrollController.animateTo(
                          maxScrollExtent * (current / count),
                          duration: 100.ms,
                          curve: Curves.easeIn,
                        );
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_rounded),
                        const SizedBox(width: 5),
                        Text(
                          Globals.audioHandler.playlistName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                // Song info
                Padding(
                  padding: const EdgeInsets.only(bottom: 30, top: 12),
                  child: Column(
                    children: [
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
                Stack(
                  children: [
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
                // Controls
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 70),
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
                          playIcon = Globals.audioHandler.playing ? AnimatedIcons.play_pause : AnimatedIcons.pause_play;
                        },
                        icon: Icon(
                          Icons.skip_previous_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 45,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1)),
                        child: IconButton(
                          onPressed: () async {
                            playIcon = AnimatedIcons.pause_play;
                            if (Globals.audioHandler.playing) {
                              Globals.audioHandler.pause();
                              animController.forward(from: 0);
                            } else {
                              Globals.audioHandler.play();
                              animController.reverse(from: 1);
                            }
                            setState(() {});
                          },
                          icon: AnimatedIcon(
                            icon: playIcon,
                            progress: Tween<double>(begin: 0.0, end: 1.0).animate(animController),
                            color: Theme.of(context).colorScheme.primary,
                            size: 70,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await Globals.audioHandler.skipToNext();
                          playIcon = Globals.audioHandler.playing ? AnimatedIcons.play_pause : AnimatedIcons.pause_play;
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
