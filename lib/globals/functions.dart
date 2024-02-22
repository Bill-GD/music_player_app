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
