import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../globals/functions.dart';
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

Future<void> getBottomSheet(
  BuildContext context,
  Widget title,
  List<ListTile> content, {
  double? maxHeight,
  bool scrollable = false,
  void Function(int oldIndex, int newIndex)? onReorder,
}) async {
  if (scrollable) assert(onReorder != null, 'onReorder must be provided if scrollable is true');
  await showCupertinoModalPopup(
    context: context,
    builder: (context) => Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.5,
        ),
        padding: const EdgeInsets.only(left: 10, right: 10, top: 30, bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: const EdgeInsets.only(left: 20, right: 20), child: title),
            if (scrollable)
              Flexible(
                child: SingleChildScrollView(
                  child: ReorderableListView(
                    onReorder: (o, n) {
                      if (n > o) n--;
                      onReorder?.call(o, n);
                      content.insert(n, content.removeAt(o));
                      for (int i = 0; i < content.length; i++) {
                        content[i] = ListTile(
                          key: ValueKey('$i'),
                          leading: Text((i + 1).padIntLeft(2, '0')),
                          title: content[i].title,
                          subtitle: content[i].subtitle,
                        );
                      }
                    },
                    proxyDecorator: (child, _, __) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Material(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: child,
                        ),
                      );
                    },
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: content,
                  ),
                ),
              )
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: content,
              ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showSongOptionsMenu(
  BuildContext context,
  String songPath,
  void Function(void Function()) setState, {
  bool showDeleteOption = true,
}) async {
  MusicTrack song = Globals.allSongs.firstWhere((e) => e.absolutePath == songPath);
  await getBottomSheet(
    context,
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
              pageBuilder: (_, __, ___) => SongInfo(songPath: songPath),
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
        
                      ${song.trackName}'''),
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
                        if (Globals.currentSongPath == songPath) {
                          Globals.currentSongPath = '';
                          Globals.showMinimizedPlayer = false;
                        }
                        Globals.audioHandler.pause();
                        File(songPath).deleteSync();
                        songDeleted = true;
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
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

Future<void> showErrorPopup(BuildContext context, String error) async {
  await showGeneralDialog(
    context: context,
    transitionDuration: 300.ms,
    barrierDismissible: true,
    barrierLabel: '',
    transitionBuilder: (_, anim1, __, child) {
      return ScaleTransition(
        scale: anim1.drive(CurveTween(curve: Curves.easeOutQuart)),
        alignment: Alignment.center,
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
          Icons.error_rounded,
          color: Theme.of(context).colorScheme.error,
          size: 30,
        ),
        title: const Center(
          child: Text(
            'Error',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            dedent('''
            An error occurred while performing the operation.
            Error: $error'''),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceAround,
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
}
