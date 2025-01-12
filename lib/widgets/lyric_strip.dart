import 'package:flutter/material.dart';

class LyricStrip extends StatefulWidget {
  const LyricStrip({super.key});

  @override
  State<LyricStrip> createState() => _LyricStripState();
}

class _LyricStripState extends State<LyricStrip> {
  @override
  Widget build(BuildContext context) {
    return const Text(
      'Lyrics',
      style: TextStyle(
        color: Colors.white54,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
