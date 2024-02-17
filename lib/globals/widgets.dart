import 'package:flutter/material.dart';

import '../music_track.dart';
import 'config.dart';
import 'variables.dart';

const TextStyle bottomSheetTitle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w500,
);
const TextStyle bottomSheetText = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
);

const Icon bottomSheetHandleIcon = Icon(
  Icons.horizontal_rule_rounded,
  size: 40,
);

ListTile sortingOptionTile({
  required String title,
  required void Function(void Function()) setState,
  required SortOptions sortOption,
  required BuildContext context,
}) =>
    ListTile(
      title: Text(title, style: bottomSheetText),
      onTap: () {
        setState(() => sortAllTracks(sortType: sortOption));
        Navigator.of(context).pop();
      },
    );

Widget bottomSheet({
  required Widget title,
  required List<Widget> content,
}) {
  return Container(
    margin: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      color: Colors.white,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          bottomSheetHandleIcon,
          title,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ListView(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: content),
            ),
          ),
        ],
      ),
    ),
  );
}

void showSongOptionsMenu(
  BuildContext context,
  int songIndex,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0x00000000),
    useSafeArea: true,
    builder: (context) => bottomSheet(
      title: Text(
        allMusicTracks[songIndex].trackName,
        style: bottomSheetTitle,
        textAlign: TextAlign.center,
        softWrap: true,
      ),
      content: [
        ListTile(
          title: const Text(
            'Delete',
            style: bottomSheetText,
          ),
          onTap: () => debugPrint('Delete song'),
        ),
        ListTile(
          title: const Text(
            'Song Info',
            style: bottomSheetText,
          ),
          onTap: () => debugPrint('Check song info'),
        )
      ],
    ),
  );
}
