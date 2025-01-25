import 'package:flutter/material.dart';

import '../handlers/log_handler.dart';

class WidgetErrorScreen extends StatelessWidget {
  final FlutterErrorDetails e;

  const WidgetErrorScreen({super.key, required this.e});

  @override
  Widget build(BuildContext context) {
    LogHandler.log(e.exception.toString(), LogLevel.error);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Internal UI Error'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left_rounded, size: 40),
          onPressed: Navigator.of(context).pop,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${e.exception}',
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            e.stack.toString(),
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
