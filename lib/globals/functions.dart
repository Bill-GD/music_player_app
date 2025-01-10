import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import 'database_handler.dart';
import 'extensions.dart';
import 'log_handler.dart';
import 'variables.dart';

String getTimeString(int milliseconds) {
  return Duration(milliseconds: milliseconds).toStringNoMilliseconds();
}

String sanitizeFilePath(String path) {
  return path.replaceAll(RegExp(r'[\\|?*<":>+\[\]/]'), '').replaceAll("'", '');
}

String getSizeString(double bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  int unitIndex = 0;
  while (bytes > 900 && unitIndex < units.length - 1) {
    bytes /= 1024;
    unitIndex++;
  }
  return '${bytes.toStringAsFixed(2)} ${units[unitIndex]}';
}

void showToast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

Future<bool> checkInternetConnection([List<ConnectivityResult>? result]) async {
  final connectivityResult = result ?? await Connectivity().checkConnectivity();
  final isInternetConnected = !connectivityResult.contains(ConnectivityResult.none);
  return isInternetConnected;
}

Future<void> backupData(BuildContext context, File bu) async {
  if (!File(Globals.dbPath).existsSync()) {
    return showToast(context, 'No data to backup');
  }
  if (!bu.existsSync()) bu.createSync();
  LogHandler.log('Backing up data to: ${bu.path}');

  // TODO query & write to backup
  final data = {
    'songs': await DatabaseHandler.db.query(Globals.songTable),
    'albums': await DatabaseHandler.db.query(Globals.albumTable),
    'album_songs': await DatabaseHandler.db.query(Globals.albumSongsTable),
  };

  bu.writeAsStringSync(jsonEncode(data));
  if (context.mounted) showToast(context, 'Data backed up successfully');
}

/// [start] and [end] are inclusive
List<int> range(int start, int end) {
  return List<int>.generate(end - start + 1, (i) => i + start);
}

/// From https://pub.dev/packages/dedent, modified to not use extra packages
String dedent(String text) {
  final whitespaceOnlyRe = RegExp(r'^[ \t]+$', multiLine: true);
  final leadingWhitespaceRe = RegExp(r'(^[ \t]*)(?:[^ \t\n])', multiLine: true);

  // Look for the longest leading string of spaces and tabs common to all lines.
  String? margin;
  text = text.replaceAll(whitespaceOnlyRe, '');
  final indents = leadingWhitespaceRe.allMatches(text);

  for (final indentRegEx in indents) {
    String indent = text.substring(indentRegEx.start, indentRegEx.end - 1);
    if (margin == null) {
      margin = indent;
    }

    // Current line more deeply indented than previous winner:
    // no change (previous winner is still on top).
    else if (indent.startsWith(margin)) {
    }

    // Current line consistent with and no deeper than previous winner:
    // it's the new winner.
    else if (margin.startsWith(indent)) {
      margin = indent;
    }

    // Find the largest common whitespace between current line and previous winner.
    else {
      final it = zip([margin.split(''), indent.split('')]).toList();
      for (int i = 0; i < it.length; i++) {
        if (it[0] != it[1]) {
          final till = (i == 0) // compensate for lack of [:-1] Python syntax
              ? margin!.length - 1
              : i - 1;
          margin = margin!.substring(0, till);
          break;
        }
      }
    }
  }

  if (margin != null && margin != '') {
    final r = RegExp(r'^' + margin, multiLine: true); // python r"(?m)^" illegal in js regex so leave it out
    text = text.replaceAll(r, '');
  }
  return text;
}

/// From https://pub.dev/packages/quiver
Iterable<List<T>> zip<T>(Iterable<Iterable<T>> iterables) sync* {
  if (iterables.isEmpty) return;
  final iterators = iterables.map((e) => e.iterator).toList(growable: false);
  while (iterators.every((e) => e.moveNext())) {
    yield iterators.map((e) => e.current).toList(growable: false);
  }
}
