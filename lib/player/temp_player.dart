import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../globals/functions.dart';
import '../globals/music_track.dart';
import '../globals/variables.dart';

class TempPlayerDialog extends StatefulWidget {
  final MusicTrack song;
  const TempPlayerDialog({super.key, required this.song});

  @override
  State<TempPlayerDialog> createState() => _TempPlayerDialogState();
}

class _TempPlayerDialogState extends State<TempPlayerDialog> {
  bool isPlaying = false;
  int currentDuration = 0, maxDuration = 0;

  @override
  Widget build(BuildContext context) {
    // StreamSubscription? posStream;
    audioPlayer
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
        audioPlayer.positionStream.listen((current) {
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
                        audioPlayer.seek(Duration.zero);
                        currentDuration = 0;
                      }
                      if (currentDuration <= 0) {
                        widget.song.timeListened++;
                        saveTracksToStorage();
                      }
                      isPlaying ? audioPlayer.pause() : audioPlayer.play();
                      stfSetState(() => isPlaying = !isPlaying);
                    },
                    icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Theme.of(context).colorScheme.primary),
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
