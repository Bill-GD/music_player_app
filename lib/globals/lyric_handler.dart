import 'dart:io';

import 'functions.dart';
import 'variables.dart';

class LyricHandler {
  static late final String _dirPath;

  static void init() {
    _dirPath = Directory('${Globals.storagePath}/files').absolute.path;
  }

  static void addLyric(Lyric lyric) {
    const appName = 'Music Hub';
    final version = Globals.appVersion;

    final lrcFile = File('$_dirPath/${lyric.songId}.lrc');
    if (!lrcFile.existsSync()) lrcFile.createSync(recursive: true);

    lrcFile.writeAsStringSync('');

    lrcFile.writeAsStringSync('[ti: ${lyric.name}]\n', mode: FileMode.append);
    lrcFile.writeAsStringSync('[ar: ${lyric.artist}]\n', mode: FileMode.append);
    lrcFile.writeAsStringSync('[al: ${lyric.album}]\n\n', mode: FileMode.append);

    lrcFile.writeAsStringSync('[re: $appName]\n', mode: FileMode.append);
    lrcFile.writeAsStringSync('[ve: $version]\n\n', mode: FileMode.append);

    for (final l in lyric.list) {
      lrcFile.writeAsStringSync('[${l.timestamp.toLyricTimestamp()}] ${l.line}\n', mode: FileMode.append);
    }
  }

  static Lyric? getLyric(int songID) {
    final lrcFile = File('$_dirPath/$songID.lrc');
    if (!lrcFile.existsSync()) return null;

    var lines = lrcFile.readAsLinesSync();

    final name = lines //
        .firstWhere((e) => e.startsWith('[ti'))
        .substring(4)
        .replaceAll(']', '')
        .trim();
    final artist = lines //
        .firstWhere((e) => e.startsWith('[ar'))
        .substring(4)
        .replaceAll(']', '')
        .trim();
    final album = lines //
        .firstWhere((e) => e.startsWith('[al'))
        .substring(4)
        .replaceAll(']', '')
        .trim();

    lines = lines.getRange(7, lines.length).where((e) => e.isNotEmpty).toList();

    final lItems = <LyricItem>[];

    for (final l in lines) {
      final closingBracketIdx = l.indexOf(']');

      final time = l.substring(1, closingBracketIdx).split(RegExp(r'[:.]')).map(int.parse);
      lItems.add(LyricItem(
        timestamp: DateTime(0, 1, 1, 0, time.elementAt(0), time.elementAt(1), time.elementAt(2), 0),
        line: l.substring(closingBracketIdx + 1).trim(),
      ));
    }

    return Lyric(
      songId: songID,
      name: name,
      artist: artist,
      album: album,
      list: lItems,
    );
  }
}

class Lyric {
  final int songId;
  final String name, artist, album;
  final List<LyricItem> list;

  const Lyric({
    required this.songId,
    required this.name,
    required this.artist,
    required this.album,
    this.list = const <LyricItem>[],
  });

  @override
  String toString() {
    return 'id: $songId\nname: $name\nartist: $artist\nalbum: $album\n${list.map((e) => '${e.timestamp.toLyricTimestamp()} - ${e.line}').join('\n')}';
  }
}

class LyricItem {
  final DateTime timestamp;
  final String line;

  const LyricItem({required this.timestamp, required this.line});
}
