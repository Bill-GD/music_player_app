import 'package:flutter/material.dart';

import '../globals/log_handler.dart';

class WidgetErrorScreen extends StatelessWidget {
  final FlutterErrorDetails e;
  final textStyle = const TextStyle(
    fontSize: 24,
    color: Colors.red,
    decoration: TextDecoration.none,
  );

  const WidgetErrorScreen({super.key, required this.e});

  @override
  Widget build(BuildContext context) {
    LogHandler.log(e.exception.toString(), LogLevel.error);
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left_rounded, size: 40),
          onPressed: Navigator.of(context).pop,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Text('${e.exception}', style: textStyle),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(e.stack.toString(), style: textStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
