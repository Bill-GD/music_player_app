import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../songs/song_info.dart';
import 'config.dart';
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
  String? hintText,
  String? labelText,
  String? errorText,
  Widget? prefixIcon,
  InputBorder? border,
  Color? fillColor,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      border: border,
    );

ButtonStyle textButtonStyle(BuildContext context) => ButtonStyle(
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

void showSongSortingOptionsMenu(
  BuildContext context, {
  required void Function(void Function()) setState,
  required TickerProvider ticker,
}) {
  showModalBottomSheet(
    context: context,
    useSafeArea: true,
    enableDrag: false,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
    constraints: BoxConstraints.loose(
      Size.fromWidth(MediaQuery.of(context).size.width * 0.95),
    ),
    builder: (context) => bottomSheet(
      context: context,
      title: const Text(
        'Sort Songs',
        style: bottomSheetTitle,
        textAlign: TextAlign.center,
        softWrap: true,
      ),
      content: [
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          leading: FaIcon(FontAwesomeIcons.arrowDownAZ, color: iconColor(context)),
          title: const Text('By name', style: bottomSheetText),
          onTap: () {
            setState(() => sortAllTracks(SortOptions.name));
            Navigator.of(context).pop();
          },
        ),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          leading: FaIcon(FontAwesomeIcons.arrowDown91, color: iconColor(context)),
          title: const Text('By the number of times played', style: bottomSheetText),
          onTap: () {
            setState(() => sortAllTracks(SortOptions.mostPlayed));
            Navigator.of(context).pop();
          },
        ),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          leading: FaIcon(FontAwesomeIcons.clock, color: iconColor(context)),
          title: const Text('By adding time', style: bottomSheetText),
          onTap: () {
            setState(() => sortAllTracks(SortOptions.recentlyAdded));
            Navigator.of(context).pop();
          },
        ),
      ],
    ),
  );
}

void showSongOptionsMenu(
  BuildContext context,
  MusicTrack song,
  void Function(void Function()) setState,
) {
  showModalBottomSheet<void>(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
    useSafeArea: true,
    enableDrag: false,
    constraints: BoxConstraints.loose(
      Size.fromWidth(MediaQuery.of(context).size.width * 0.95),
    ),
    builder: (context) => bottomSheet(
      context: context,
      title: Text(
        song.trackName,
        style: bottomSheetTitle,
        textAlign: TextAlign.center,
        softWrap: true,
      ),
      content: [
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          leading: Icon(Icons.info_outline_rounded, color: iconColor(context)),
          title: const Text('Song Info', style: bottomSheetText),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SongInfo(
                  songIndex: allMusicTracks.indexWhere(
                    (element) => element.absolutePath == song.absolutePath,
                  ),
                ),
              ),
            );
            await getMusicData();
            setState(() {});
          },
        ),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          leading: Icon(Icons.delete_rounded, color: iconColor(context)),
          title: const Text('Delete', style: bottomSheetText),
          onTap: () => debugPrint('Delete song'),
        ),
      ],
    ),
  );
}
