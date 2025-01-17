import 'dart:convert';

import 'package:flutter/material.dart';

import '../globals/functions.dart';
import '../globals/log_handler.dart';

class VersionDialog extends StatefulWidget {
  final String tag;
  final String sha;
  final bool dev;

  const VersionDialog({super.key, required this.tag, required this.sha, this.dev = false});

  @override
  State<VersionDialog> createState() => _VersionDialogState();
}

class _VersionDialogState extends State<VersionDialog> {
  bool loading = true;
  String body = '';

  @override
  void initState() {
    super.initState();
    LogHandler.log('Getting changelog of: ${widget.tag}');
    getChangelog();
  }

  Future<void> getChangelog() async {
    try {
      body = widget.tag.contains('_dev_')
          ? await getRelease()
          : widget.dev
              ? await getNote()
              : await getRelease();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      rethrow;
    }
    if (mounted) setState(() => loading = false);
  }

  Future<String> getRelease() async {
    final res = await apiQuery('/releases/tags/${widget.tag}');
    final json = jsonDecode(res.body);

    if (json == null) throw Exception('Rate limited. Please come back later.');
    if (json is! Map) throw Exception('Something is wrong, JSON received is not a map.');

    LogHandler.log('Got release of: t=${widget.tag}, sha=${widget.sha}');
    return json['body'] as String;
  }

  Future<String> getNote() async {
    // final filename = widget.dev ? 'release_note.md' : 'dev_changes.md';
    const filename = 'dev_changes.md';
    final res = await apiQuery('/contents/$filename?ref=${widget.sha}');
    final json = jsonDecode(res.body);

    if (json == null) throw Exception('Rate limited. Please come back later.');
    if (json is! Map) throw Exception('Something is wrong, JSON received is not a map.');

    if (json['content'] == null) return getRelease();

    LogHandler.log('Got markdown of: t=${widget.tag}, sha=${widget.sha}');
    return utf8.decode(base64Decode(
      (json['content'] as String).replaceAll('\n', ''),
    ));
  }

  List<InlineSpan> getContent(String body) {
    final List<InlineSpan> bodySpans = [];
    final List<String> bodyLines = body //
        .split(RegExp(r'(\r\n)|\n|(\n\n)'))
        .where((e) => !e.contains('**Full Changelog**'))
        .map((e) => '$e\n')
        .toList();
    while (bodyLines.isNotEmpty && bodyLines.last.trim().isEmpty) {
      bodyLines.removeLast();
    }
    bodyLines[bodyLines.length - 1] = bodyLines.last.trim();

    for (int i = 0; i < bodyLines.length; i++) {
      if (!bodyLines[i].contains('`')) continue;
      final split = bodyLines[i].split('`'), idx = i;

      bodyLines[i] = split.first;
      for (int j = 1; j < split.length; j++) {
        bodyLines.insert(
          idx + j,
          '${j % 2 != 0 ? '`' : ''}${split[j]}',
        );
        i++;
      }
    }

    for (final l in bodyLines) {
      int titleLevel = 0;
      String text = '';
      bool isCode = false;

      if (l.startsWith('#')) {
        final hashIndex = l.lastIndexOf('#');
        titleLevel = l.substring(0, hashIndex + 1).length;
        text = l.substring(hashIndex + 1);
      } else if (l.startsWith('`')) {
        isCode = true;
        text = l.substring(1);
      } else {
        text = l;
      }

      bodySpans.add(TextSpan(
        text: text,
        style: TextStyle(
          fontSize: titleLevel > 0
              ? 24.0 - titleLevel
              : isCode
                  ? 14
                  : 16,
          fontWeight: titleLevel > 0 ? FontWeight.bold : null,
          fontFamily: isCode ? 'monospace' : null,
          color: isCode ? Theme.of(context).colorScheme.onSurface : null,
        ),
      ));
    }

    return bodySpans;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.tag,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
      titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
      content: loading
          ? const Column(
              mainAxisSize: MainAxisSize.min,
              children: [CircularProgressIndicator()],
            )
          : SingleChildScrollView(
              child: RichText(
                text: TextSpan(children: getContent(body)),
              ),
            ),
      contentPadding: const EdgeInsets.only(left: 20, right: 20, top: 15),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('OK'),
        ),
      ],
      actionsPadding: const EdgeInsets.only(top: 16, bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        side: BorderSide(color: Theme.of(context).colorScheme.onSurface),
      ),
      insetPadding: const EdgeInsets.only(top: 40, bottom: 16, left: 20, right: 20),
    );
  }
}
