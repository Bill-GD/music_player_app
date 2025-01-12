import 'dart:io';

import 'extensions.dart';
import 'variables.dart';

class LyricHandler {
  static late final String _dirPath;

  static void init() {
    _dirPath = Directory('${Globals.storagePath}/files').absolute.path;
  }

  static void addLyric(Lyric lyric) {
    const appName = 'Music Hub';
    const version = Globals.appVersion;

    final lrcFile = File('$_dirPath/${lyric.songId}.lrc');
    if (!lrcFile.existsSync()) lrcFile.createSync(recursive: true);

    lrcFile.writeAsStringSync('');

    lrcFile.writeAsStringSync('[ti: ${lyric.name}]\n', mode: FileMode.append);
    lrcFile.writeAsStringSync('[ar: ${lyric.artist}]\n', mode: FileMode.append);
    lrcFile.writeAsStringSync('[al: ${lyric.album}]\n', mode: FileMode.append);

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

  static Lyric? getLyric(int songID, {String? path}) {
    final lrcFile = File(path ?? '$_dirPath/$songID.lrc');
    if (!lrcFile.existsSync()) return null;

    var lines = lrcFile.readAsLinesSync();

    final name = _getMetadata(lines, '[ti:') ?? '';
    final artist = _getMetadata(lines, '[ar:') ?? '';
    final album = _getMetadata(lines, '[al:') ?? '';

    lines = lines.where((e) => e.trim().isNotEmpty && e.startsWith(RegExp(r'^\[\d'))).toList();

    final lItems = <LyricItem>[];

    for (final l in lines) {
      final closingBracketIdx = l.indexOf(']');

      final time = l.substring(1, closingBracketIdx).split(RegExp(r'[:.]')).map(int.parse);
      lItems.add(LyricItem(
        timestamp: DateTime(0, 1, 1, 0, time.elementAt(0), time.elementAt(1), time.elementAt(2), 0),
        line: l.substring(closingBracketIdx + 1).trim(),
      ));
    }

    lItems.sort((a, b) => a.timestamp.compareTo(b.timestamp));

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
    return 'id: $songId\n'
        'name: $name\n'
        'artist: $artist\n'
        'album: $album\n'
        '${list.map((e) => '${e.timestamp.toLyricTimestamp()} - ${e.line}').join('\n')}';
  }
}

class LyricItem {
  final DateTime timestamp;
  final String line;

  const LyricItem({required this.timestamp, required this.line});
}
