import 'dart:io';

import '../globals/extensions.dart';
import '../globals/globals.dart';
import 'log_handler.dart';

class LyricHandler {
  static void addLyric(Lyric lyric) {
    const appName = 'Music Hub';
    const version = Globals.appVersion;

    final lrcFile = File(Globals.lyricPath + lyric.path);
    if (!lrcFile.existsSync()) lrcFile.createSync(recursive: true);

    LogHandler.log('Writing lyric: p=${lrcFile.path}, id=${lyric.songId}, ve=$version');

    lrcFile.writeAsStringSync('');

    lrcFile.writeAsStringSync('[ti: ${lyric.name}]\n', mode: FileMode.append);
    lrcFile.writeAsStringSync('[ar: ${lyric.artist}]\n', mode: FileMode.append);
    lrcFile.writeAsStringSync('[al:]\n', mode: FileMode.append);

    lrcFile.writeAsStringSync('[re: $appName]\n', mode: FileMode.append);
    lrcFile.writeAsStringSync('[ve: $version]\n', mode: FileMode.append);
    lrcFile.writeAsStringSync('[length:]\n\n', mode: FileMode.append);

    for (final l in lyric.list) {
      lrcFile.writeAsStringSync('[${l.timestamp.toLyricTimestamp()}] ${l.line}\n', mode: FileMode.append);
    }
  }

  static String? _getMetadata(List<String> lines, String begin) => lines //
      .firstWhereOrNull((e) => e.startsWith(begin))
      ?.substring(4)
      .replaceAll(']', '')
      .trim();

  static Lyric? getLyric(int songID, String path) {
    final lrcFile = File(path);
    if (!lrcFile.existsSync()) return null;

    var lines = lrcFile.readAsLinesSync();

    final name = _getMetadata(lines, '[ti:') ?? '';
    final artist = _getMetadata(lines, '[ar:') ?? '';
    // final album = _getMetadata(lines, '[al:') ?? '';

    lines = lines.where((e) => e.trim().isNotEmpty && e.startsWith(RegExp(r'^\[\d'))).toList();

    final lItems = <LyricItem>[];

    for (final l in lines) {
      final closingBracketIdx = l.indexOf(']');
      final timeStr = l.substring(1, closingBracketIdx);

      var timeParts = timeStr.split(RegExp(r'[:.]'));

      for (final t in timeParts) {
        final matches = RegExp(r'[0-9]{2}').allMatches(t);
        if (matches.length != 1) {
          LogHandler.log('$t match count ${matches.length} -> invalid, skipping...');
          continue;
        }
        // LogHandler.log(
        //   'Matches for $t (${matches.length}): ${matches.map((e) => e.group(0)).join(', ')}',
        // );
      }

      final time = timeParts.map(int.parse);
      lItems.add(LyricItem(
        timestamp: time.elementAt(0).minutes + time.elementAt(1).seconds + (time.elementAt(2) * 10).ms,
        // timestamp: DateTime(0, 1, 1, 0, time.elementAt(0), time.elementAt(1), time.elementAt(2), 0),
        line: l.substring(closingBracketIdx + 1).trim(),
      ));
    }

    lItems.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Lyric(
      songId: songID,
      name: name,
      artist: artist,
      path: path.split(Globals.lyricPath).last,
      list: lItems,
    );
  }
}

class Lyric {
  final int songId;
  final String name, artist;
  final List<LyricItem> list;
  final String path;

  const Lyric({
    required this.songId,
    required this.name,
    required this.artist,
    required this.path,
    required this.list,
  });

  Lyric.from(Lyric other)
      : songId = other.songId,
        name = other.name,
        artist = other.artist,
        list = List.from(other.list),
        path = other.path;

  @override
  String toString() {
    return 'id: $songId\n'
        'name: $name\n'
        'artist: $artist\n'
        'path: $path\n'
        '${list.map((e) => '${e.timestamp.toLyricTimestamp()} - ${e.line}').join('\n')}';
  }
}

class LyricItem {
  final Duration timestamp;
  final String line;

  const LyricItem({required this.timestamp, required this.line});
}
