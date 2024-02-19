extension DurationExtension on Duration {
  /// Converts duration to MM:SS format
  String toMMSS() => toString().split('.').first.padLeft(8, '0').substring(3);
}

String getTimeString(int milliseconds) {
  int timeInSeconds = milliseconds ~/ 1000;
  return Duration(seconds: timeInSeconds).toMMSS();
}

String sanitizeFilePath(String path) {
  return path.replaceAll(RegExp(r'[\\|?*<":>+\[\]\/]'), '').replaceAll("'", '');
}
