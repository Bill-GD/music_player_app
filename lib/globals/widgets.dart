import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../globals/utils.dart';
import '../songs/song_info.dart';
import '../widgets/action_dialog.dart';
import 'extensions.dart';
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

Color? iconColor(BuildContext context, [double opacity = 1]) => Theme.of(context).iconTheme.color?.withOpacity(opacity);

Text leadingText(BuildContext context, String text, [bool bold = true, double size = 18]) => Text(
      text,
      style: TextStyle(
        fontSize: size,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      ),
    );

InputDecoration textFieldDecoration(
  BuildContext context, {
  Color? fillColor,
  String? hintText,
  String? labelText,
  String? errorText,
  InputBorder? border,
  Widget? prefixIcon,
  Widget? suffixIcon,
  EdgeInsetsGeometry? contentPadding,
  BoxConstraints? constraints,
}) =>
    InputDecoration(
      filled: true,
      fillColor: fillColor,
      hintText: hintText,
      hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
      labelText: labelText,
      labelStyle: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
      errorText: errorText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minHeight: 2, minWidth: 2),
      contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 20),
      border: border,
      constraints: constraints,
    );

Future<void> showSongOptionsMenu(
  BuildContext context,
  int songID,
  void Function(void Function()) setState, {
  List<Widget>? moreActions,
  bool showDeleteOption = true,
}) async {
  MusicTrack song = Globals.allSongs.firstWhere((e) => e.id == songID);
  await getBottomSheet(
    context,
    Text(
      song.name,
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
            setState(() {
              updateArtistsList();
              updateAlbumList();
              sortAllSongs();
            });
            if (context.mounted) Navigator.of(context).pop();
          }
        },
      ),
      ...?moreActions,
      if (showDeleteOption)
        ListTile(
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
              if (context.mounted) Navigator.of(context).pop();
            }
          },
        ),
    ],
  );
}

Future<void> getBottomSheet(
  BuildContext context,
  Widget title,
  List<Widget> content,
) async {
  await showCupertinoModalPopup(
    context: context,
    builder: (context) => Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        constraints: BoxConstraints.loose(Size.fromWidth(MediaQuery.of(context).size.width * 0.90)),
        decoration: BoxDecoration(
          border: Border.all(
            width: 1,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 10, top: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: title,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: content,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showErrorPopup(BuildContext context, String error) async {
  await ActionDialog.static<void>(
    context,
    barrierDismissible: true,
    time: 300.ms,
    icon: Icon(
      Icons.error_rounded,
      color: Theme.of(context).colorScheme.error,
      size: 30,
    ),
    title: 'Error',
    titleFontSize: 24,
    textContent: dedent('''
            An error occurred while performing the operation.
            Error: $error'''),
    contentFontSize: 16,
    actions: [
      TextButton(
        child: const Text('OK'),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ],
  );
}

Future<void> showPopupMessage(
  BuildContext context, {
  Icon? icon,
  required String title,
  required String content,
  Duration time = const Duration(milliseconds: 200),
  bool centerContent = true,
  double? horizontalPadding,
  bool enableButton = true,
  bool barrierDismissible = true,
}) async {
  await ActionDialog.static<void>(
    context,
    icon: icon,
    title: title,
    titleFontSize: 24,
    textContent: content,
    contentFontSize: 16,
    centerContent: centerContent,
    time: time,
    actions: [
      TextButton(
        onPressed: enableButton ? () => Navigator.of(context).pop() : null,
        child: const Text('OK'),
      ),
    ],
    horizontalPadding: horizontalPadding,
    barrierDismissible: barrierDismissible,
    allowScroll: true,
  );
}
