extension DurationExtension on Duration {
  String toStringNoMilliseconds() {
    final inString = toString().split('.').first.padLeft(8, '0');
    return inHours > 0 ? inString : inString.substring(3);
  }
}

String getTimeString(int milliseconds) {
  return Duration(milliseconds: milliseconds).toStringNoMilliseconds();
}

String sanitizeFilePath(String path) {
  return path.replaceAll(RegExp(r'[\\|?*<":>+\[\]\/]'), '').replaceAll("'", '');
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

/// [start] and [end] are inclusive
List<int> range(int start, int end) {
  return List<int>.generate(end - start + 1, (i) => i + start);
}

extension NumDurationExtensions on num {
  Duration get microseconds => Duration(microseconds: round());

  Duration get ms => (this * 1000).microseconds;

  Duration get milliseconds => (this * 1000).microseconds;

  Duration get seconds => (this * 1000 * 1000).microseconds;

  Duration get minutes => (this * 1000 * 1000 * 60).microseconds;

  Duration get hours => (this * 1000 * 1000 * 60 * 60).microseconds;

  Duration get days => (this * 1000 * 1000 * 60 * 60 * 24).microseconds;
}

extension PadInt on int {
  String padIntLeft(int count, [String padding = ' ']) {
    return toString().padLeft(count, padding);
  }
}

extension WhereOrNull<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (final i in range(0, length - 1)) {
      if (test(elementAt(i))) return elementAt(i);
    }
    return null;
  }

  Iterable<R> mapIndexed<R>(R Function(int index, E element) test) {
    int index = 0;
    return map((e) => test(index++, e));
  }
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
