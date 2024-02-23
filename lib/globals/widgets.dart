import 'dart:io';

import 'package:dedent/dedent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../player/music_player.dart';
import '../songs/song_info.dart';
import 'music_track.dart';
import 'variables.dart';

const TextStyle bottomSheetTitle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w700,
);
const TextStyle bottomSheetText = TextStyle(
  fontSize: 17,
  fontWeight: FontWeight.w600,
);

Color? iconColor(BuildContext context) => Theme.of(context).iconTheme.color;

InputDecoration textFieldDecoration(
  BuildContext context, {
  Color? fillColor,
  String? hintText,
  String? labelText,
  String? errorText,
  InputBorder? border,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) =>
    InputDecoration(
      filled: true,
      fillColor: fillColor,
      hintText: hintText,
      hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
      labelText: labelText,
      labelStyle: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
      errorText: errorText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minHeight: 2, minWidth: 2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      border: border,
    );

ButtonStyle textButtonStyle(BuildContext context) {
  return ButtonStyle(
    textStyle: const MaterialStatePropertyAll<TextStyle>(
      TextStyle(fontWeight: FontWeight.bold),
    ),
    backgroundColor: MaterialStateProperty.resolveWith<Color>(
      (states) {
        if (states.contains(MaterialState.disabled)) {
          return Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5);
        }
        return Theme.of(context).colorScheme.primaryContainer;
      },
    ),
    shape: MaterialStatePropertyAll<RoundedRectangleBorder>(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
  );
}

Route getMusicPlayerRoute(
  BuildContext context,
  MusicTrack song,
) {
  return PageRouteBuilder(
    pageBuilder: (context, _, __) => MusicPlayerPage(song: song),
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

AnimationController getBottomSheetAnimator(TickerProvider vsync) {
  final animationController = AnimationController(vsync: vsync, duration: 200.ms);
  CurvedAnimation(
    parent: Tween<double>(begin: 1, end: 0).animate(animationController),
    curve: Curves.easeInOutQuart,
  );
  return animationController;
}

Future<void> getBottomSheet(
  BuildContext context,
  TickerProvider ticker,
  Widget title,
  List<Widget> content,
) async {
  await showModalBottomSheet(
    context: context,
    useSafeArea: true,
    enableDrag: false,
    transitionAnimationController: getBottomSheetAnimator(ticker),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    constraints: BoxConstraints.loose(Size.fromWidth(MediaQuery.of(context).size.width * 0.95)),
    builder: (context) => bottomSheet(
      context: context,
      title: title,
      content: content,
    ),
  );
}

Widget bottomSheet({
  required BuildContext context,
  required Widget title,
  required List<Widget> content,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 30, bottom: 10, left: 20, right: 20),
          child: title,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: content,
          ),
        ),
      ],
    ),
  );
}

Future<void> showSongOptionsMenu(
  BuildContext context,
  MusicTrack song,
  TickerProvider ticker, {
  bool showDeleteOption = true,
}) async {
  await getBottomSheet(
    context,
    ticker,
    Text(
      song.trackName,
      style: bottomSheetTitle,
      textAlign: TextAlign.center,
      softWrap: true,
    ),
    [
      ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        leading: Icon(Icons.info_outline_rounded, color: iconColor(context)),
        title: const Text('Song Info', style: bottomSheetText),
        onTap: () async {
          bool needsUpdate = await Navigator.of(context).push(
            PageRouteBuilder(
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
              pageBuilder: (context, _, __) => SongInfo(
                songIndex: allMusicTracks.indexWhere(
                  (element) => element.absolutePath == song.absolutePath,
                ),
              ),
            ),
          );
          if (needsUpdate) {
            await updateMusicData();
            sortAllSongs();
          }
        },
      ),
      if (showDeleteOption)
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          leading: Icon(Icons.delete_rounded, color: iconColor(context)),
          title: const Text('Delete', style: bottomSheetText),
          onTap: () async {
            bool songDeleted = false;
            await showGeneralDialog(
              context: context,
              transitionDuration: 300.ms,
              barrierDismissible: true,
              barrierLabel: '',
              transitionBuilder: (_, anim1, __, child) {
                return ScaleTransition(
                  scale: anim1.drive(CurveTween(curve: Curves.easeOutQuart)),
                  alignment: Alignment.bottomCenter,
                  child: child,
                );
              },
              pageBuilder: (context, _, __) {
                return AlertDialog(
                  contentPadding: const EdgeInsets.only(left: 10, right: 10, top: 30),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  icon: Icon(
                    Icons.warning_rounded,
                    color: Theme.of(context).colorScheme.error,
                    size: 30,
                  ),
                  title: const Center(
                    child: Text(
                      'Delete Song',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  content: Text(
                    dedent('''
                      This CANNOT be undone.
                      Are you sure you want to delete

                      ${song.trackName}
                      '''),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  actionsAlignment: MainAxisAlignment.spaceAround,
                  actions: [
                    TextButton(
                      child: const Text('No'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    TextButton(
                      child: const Text('Yes'),
                      onPressed: () async {
                        File(song.absolutePath).deleteSync();
                        songDeleted = true;
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                );
              },
            );
            if (songDeleted) {
              await updateMusicData();
              sortAllSongs();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          },
        ),
    ],
  );
}
