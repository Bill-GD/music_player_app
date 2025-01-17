import 'functions.dart';

extension DurationExtension on Duration {
  String toStringNoMilliseconds() {
    final inString = toString().split('.').first.padLeft(8, '0');
    return inHours > 0 ? inString : inString.substring(3);
  }
}

extension NumberDurationExtensions on num {
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

const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

extension DateString on DateTime {
  String toDateString() {
    final local = toLocal();
    // return '$_formatDay ${_monthNames[month - 1]} $year, ${hour.padIntLeft(2, '0')}:${minute.padIntLeft(2, '0')}:${second.padIntLeft(2, '0')}';
    return '${_formatDay(local.day)} ${_monthNames[month - 1]} $year, ${local.hour.padIntLeft(2, '0')}:${local.minute.padIntLeft(2, '0')}:${local.second.padIntLeft(2, '0')}';
  }

  String _formatDay(int day) {
    switch (day) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }
}

extension LyricTimestamp on Duration {
  DateTime get _dt => DateTime.fromMillisecondsSinceEpoch(inMilliseconds);

  String toLyricTimestamp() {
    return '${_dt.minute.padIntLeft(2, '0')}:${_dt.second.padIntLeft(2, '0')}.${(_dt.millisecond ~/ 10).padIntLeft(2, '0')}';
  }

  String toMMSS() {
    return '${_dt.minute.padIntLeft(2, '0')}:${_dt.second.padIntLeft(2, '0')}';
  }
}

extension DoublePrecision on double {
  double precision(int places) => double.parse(toStringAsPrecision(places));
}
