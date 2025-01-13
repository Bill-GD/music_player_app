import 'package:flutter/material.dart';

import '../globals/extensions.dart';
import '../globals/log_handler.dart';
import '../widgets/hold_gesture.dart';

class TimestampEditor extends StatefulWidget {
  final (int, int, int) timestamp;

  const TimestampEditor({super.key, required this.timestamp});

  @override
  State<TimestampEditor> createState() => _TimestampEditorState();
}

class _TimestampEditorState extends State<TimestampEditor> {
  late List<int> edit = [widget.timestamp.$1, widget.timestamp.$2, widget.timestamp.$3];

  void upTime(int index) {
    switch (index) {
      case 0:
        edit[0] = (edit[0] + 1) % 60;
        break;
      case 1:
        if (edit[1] == 59) upTime(0);
        edit[1] = (edit[1] + 1) % 60;
        break;
      case 2:
        if (edit[2] == 900) upTime(1);
        edit[2] = (edit[2] + 100) % 1000;
        break;
    }
  }

  void downTime(int index) {
    switch (index) {
      case 0:
        edit[0] = (edit[0] - 1) % 60;
        break;
      case 1:
        if (edit[1] == 0) downTime(0);
        edit[1] = (edit[1] - 1) % 60;
        break;
      case 2:
        if (edit[2] == 0) downTime(1);
        edit[2] = (edit[2] - 100) % 1000;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Edit timestamp',
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
      titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Current: '),
          Text(
            Duration(
              minutes: widget.timestamp.$1,
              seconds: widget.timestamp.$2,
              milliseconds: widget.timestamp.$3,
            ).toLyricTimestamp(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  HoldingGesture(
                    callback: () {
                      upTime(0);
                      setState(() {});
                    },
                    child: const Icon(
                      Icons.arrow_drop_up_rounded,
                      size: 40,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                    child: Text(edit[0].padIntLeft(2, '0')),
                  ),
                  HoldingGesture(
                    callback: () {
                      downTime(0);
                      setState(() {});
                    },
                    child: const Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 40,
                    ),
                  ),
                ],
              ),
              const Text(':'),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  HoldingGesture(
                    callback: () {
                      upTime(1);
                      setState(() {});
                    },
                    child: const Icon(
                      Icons.arrow_drop_up_rounded,
                      size: 40,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                    child: Text(edit[1].padIntLeft(2, '0')),
                  ),
                  HoldingGesture(
                    callback: () {
                      downTime(1);
                      setState(() {});
                    },
                    child: const Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 40,
                    ),
                  ),
                ],
              ),
              const Text('.'),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  HoldingGesture(
                    callback: () {
                      upTime(2);
                      setState(() {});
                    },
                    child: const Icon(
                      Icons.arrow_drop_up_rounded,
                      size: 40,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                    child: Text((edit[2] ~/ 10).padIntLeft(2, '0')),
                  ),
                  HoldingGesture(
                    callback: () {
                      downTime(2);
                      setState(() {});
                    },
                    child: const Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
      contentTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 18),
      contentPadding: const EdgeInsets.only(left: 20, right: 20, top: 15),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('Save'),
          onPressed: () {
            LogHandler.log('Edited timestamp: ${widget.timestamp} -> $edit');
            Navigator.of(context).pop(edit);
          },
        ),
      ],
      actionsPadding: const EdgeInsets.only(top: 16, bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        side: BorderSide(color: Theme.of(context).colorScheme.onSurface),
      ),
      insetPadding: const EdgeInsets.only(top: 40, bottom: 16),
    );
  }
}
