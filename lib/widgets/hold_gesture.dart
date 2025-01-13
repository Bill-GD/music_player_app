import 'dart:async';

import 'package:flutter/material.dart';

import '../globals/extensions.dart';

class HoldingGesture extends StatefulWidget {
  final VoidCallback callback;
  final Widget? child;

  const HoldingGesture({
    super.key,
    required this.callback,
    this.child,
  });

  @override
  State<HoldingGesture> createState() => _HoldingGestureState();
}

class _HoldingGestureState extends State<HoldingGesture> {
  Timer? timer;
  bool isHolding = false;

  void holdStart() {
    if (isHolding) return;

    isHolding = true;
    widget.callback();

    timer ??= Timer.periodic(
      100.ms,
      (_) {
        if (isHolding) widget.callback();
      },
    );
  }

  void holdEnd() {
    isHolding = false;
    timer?.cancel();
    timer = null;
  }

  @override
  void dispose() {
    holdEnd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTapDown: (_) => holdStart(),
      onTapUp: (_) => holdEnd(),
      onTapCancel: holdEnd,
      child: widget.child,
    );
  }
}
