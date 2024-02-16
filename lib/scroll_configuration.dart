import 'package:flutter/material.dart';

ScrollConfiguration setOverscroll({required bool overscroll, required Widget child}) {
  return ScrollConfiguration(
    behavior: const ScrollBehavior().copyWith(overscroll: overscroll),
    child: child,
  );
}
