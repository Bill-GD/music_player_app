// import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player_app/scroll_configuration.dart';

import '../music_track.dart';

class TempPlayerDialog extends StatefulWidget {
  final AudioPlayer player;
  final MusicTrack song;
  const TempPlayerDialog({super.key, required this.player, required this.song});

  @override
  State<TempPlayerDialog> createState() => _TempPlayerDialogState();
}

class _TempPlayerDialogState extends State<TempPlayerDialog> {
  bool isPlaying = false;
  int currentDuration = 0, maxDuration = 0;

  @override
  Widget build(BuildContext context) {
    // StreamSubscription? posStream;
    widget.player
        .setAudioSource(
          AudioSource.uri(
            Uri.parse(Uri.encodeComponent(widget.song.absolutePath)),
          ),
          initialPosition: Duration.zero,
          preload: true,
        )
        .then((value) => maxDuration = value!.inMilliseconds);

    return StatefulBuilder(
      builder: (stfContext, stfSetState) {
        // posStream =
        widget.player.positionStream.listen((current) {
          currentDuration = current.inMilliseconds;
          if (currentDuration >= maxDuration) {
            isPlaying = false;
          }
          if (stfContext.mounted) {
            stfSetState(() {});
          }
        });
        return Dialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.song.toJson().entries.length,
                itemBuilder: (context, i) {
                  final valuePair = widget.song.toJson().entries.elementAt(i);
                  return ListTile(
                    title: Text('${valuePair.key}: ${valuePair.value}'),
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(getTimeString(currentDuration)),
                  IconButton(
                    onPressed: () {
                      if (currentDuration >= maxDuration) {
                        widget.player.seek(Duration.zero);
                        currentDuration = 0;
                      }
                      if (currentDuration <= 0) {
                        widget.song.timeListened++;
                        // saveTracksToStorage(allMusicTracks);
                      }
                      isPlaying ? widget.player.pause() : widget.player.play();
                      isPlaying = !isPlaying;
                      stfSetState(() {});
                    },
                    icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  ),
                  Text(getTimeString(maxDuration)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

extension DurationExtension on Duration {
  /// Converts duration to MM:SS format
  String toMMSS() => toString().split('.').first.padLeft(8, '0').substring(3);
}

String getTimeString(int milliseconds) {
  int timeInSeconds = milliseconds ~/ 1000;
  return Duration(seconds: timeInSeconds).toMMSS();
}
