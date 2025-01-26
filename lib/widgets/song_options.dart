import 'dart:io';

import 'package:flutter/material.dart';

import '../globals/extensions.dart';
import '../globals/globals.dart';
import '../globals/music_track.dart';
import '../globals/utils.dart';
import '../globals/widgets.dart';
import '../songs/song_info.dart';
import 'action_dialog.dart';

class SongInfoOption extends StatelessWidget {
  final int songID;
  final void Function() updateCallback;

  const SongInfoOption({super.key, required this.songID, required this.updateCallback});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      leading: Icon(Icons.info_outline_rounded, color: iconColor(context)),
      title: const Text('Song info', style: bottomSheetText),
      onTap: () async {
        bool? needsUpdate = await Navigator.of(context).push(
          PageRouteBuilder<bool>(
            transitionDuration: 400.ms,
            transitionsBuilder: (_, anim, __, child) {
              return ScaleTransition(
                alignment: Alignment.bottomCenter,
                scale: Tween<double>(
                  begin: 0,
                  end: 1,
                ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(anim),
                child: child,
              );
            },
            pageBuilder: (_, __, ___) => SongInfo(songID: songID),
          ),
        );
        if (needsUpdate == true) {
          updateArtistsList();
          sortAllSongs();
          updateCallback();
          if (context.mounted) Navigator.pop(context);
        }
      },
    );
  }
}

class DeleteSongOption extends StatelessWidget {
  final int songID;

  const DeleteSongOption({super.key, required this.songID});

  @override
  Widget build(BuildContext context) {
    MusicTrack song = Globals.allSongs.firstWhere((e) => e.id == songID);

    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      leading: Icon(Icons.delete_rounded, color: iconColor(context)),
      title: const Text('Delete', style: bottomSheetText),
      onTap: () async {
        bool songDeleted = false;
        await ActionDialog.static<void>(
          context,
          icon: Icon(
            Icons.warning_rounded,
            color: Theme.of(context).colorScheme.error,
            size: 30,
          ),
          title: 'Delete song',
          titleFontSize: 24,
          textContent: dedent('''
                      This CANNOT be undone.
                      Are you sure you want to delete
        
                      ${song.name}'''),
          contentFontSize: 16,
          time: 300.ms,
          scaleAlignment: Alignment.bottomCenter,
          actions: [
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () async {
                if (Globals.currentSongID == songID) {
                  Globals.currentSongID = -1;
                  Globals.showMinimizedPlayer = false;
                }
                Globals.audioHandler.pause();
                await song.delete();
                File(Globals.downloadPath + song.path).deleteSync();
                songDeleted = true;
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        );
        if (songDeleted) {
          await updateMusicData();
          sortAllSongs();
          if (context.mounted) Navigator.pop(context);
        }
      },
    );
  }
}
