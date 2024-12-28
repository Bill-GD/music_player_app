import 'dart:io';

import 'package:flutter/cupertino.dart';

import 'functions.dart';
import 'variables.dart';

enum LogLevel { info, error }

class LogHandler {
  static final _logFile = File(Globals.logPath);

  static void init() {
    if (!_logFile.existsSync()) _logFile.createSync(recursive: true);
    _logFile.writeAsStringSync('');
    log('Log init');
  }

  static void log(String content, [LogLevel level = LogLevel.info]) {
    final prefix = level.name[0].toUpperCase();
    _logFile.writeAsStringSync(
      '[${_time()}] [$prefix] $content\n',
      mode: FileMode.append,
    );
    debugPrint('[${_time()}] [$prefix] $content');
  }

  static String _time() {
    final dt = DateTime.now();
    return '${dt.year}-${dt.month.padIntLeft(2, '0')}-${dt.day.padIntLeft(2, '0')} '
        '${dt.hour.padIntLeft(2, '0')}:${dt.minute.padIntLeft(2, '0')}:${dt.second.padIntLeft(2, '0')}.${dt.millisecond.padIntLeft(3, '0')}';
  }
}
