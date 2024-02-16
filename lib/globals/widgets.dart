import 'package:flutter/material.dart';

import '../music_track.dart';
import 'config.dart';

const TextStyle modalBottomSheetText = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w500,
);

const Icon modalBottomSheetHandleIcon = Icon(
  Icons.horizontal_rule_rounded,
  size: 40,
);

ListTile sortingOptionTile({
  required String title,
  required void Function(void Function()) setState,
  required SongSorting sortOption,
  required BuildContext context,
}) =>
    ListTile(
      title: Text(title, style: modalBottomSheetText),
      onTap: () {
        sortAllTracks(sortOption);
        setState(() {});
        Navigator.of(context).pop();
      },
    );
