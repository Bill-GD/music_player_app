import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' show Response;
import 'package:url_launcher/url_launcher.dart';

import '../globals/extensions.dart';
import '../globals/log_handler.dart';
import '../globals/utils.dart';

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
  String body = '', timeUploaded = '';

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
    timeUploaded = DateTime.parse(json['published_at'] as String).toDateString();
    return json['body'] as String;
  }

  Future<String> getNote() async {
    // final filename = widget.dev ? 'release_note.md' : 'dev_changes.md';
    const filename = 'dev_changes.md';

    LogHandler.log('Getting markdown of: t=${widget.tag}, sha=${widget.sha}');
    Response res = await apiQuery('/contents/$filename?ref=${widget.sha}');
    dynamic json = jsonDecode(res.body);

    if (json == null) throw Exception('Rate limited. Please come back later.');
    if (json is! Map) throw Exception('Something is wrong, JSON received is not a map.');

    if (json['content'] == null) {
      LogHandler.log('dev_changes.md not found, getting release instead');
      return getRelease();
    }

    final content = utf8.decode(base64Decode(
      (json['content'] as String).replaceAll('\n', ''),
    ));

    LogHandler.log('Getting time of commit (${widget.sha})');
    res = await apiQuery('/commits/${widget.sha}');
    json = jsonDecode(res.body);

    if (json == null) throw Exception('Rate limited. Please come back later.');
    if (json is! Map) throw Exception('Something is wrong, JSON received is not a map.');

    timeUploaded = DateTime.parse(json['commit']['committer']['date'] as String).toDateString();

    return content;
  }

  List<InlineSpan> getContent(String body) {
    final List<InlineSpan> bodySpans = [];
    final List<String> bodyLines = body
        .split(RegExp(r'(\r\n)|\n|(\n\n)'))
        .where(
          (e) => !e.contains(
            RegExp(
              r"(Full Changelog)|(What's Changed)|(/pull/)",
            ),
          ),
        )
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
          color: isCode //
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ));
    }

    return bodySpans;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AlertDialog(
        title: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: widget.tag,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              if (timeUploaded.isNotEmpty)
                TextSpan(
                  text: '\n($timeUploaded)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
            ],
          ),
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
        contentPadding: const EdgeInsets.only(left: 20, right: 20, top: 20),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () async {
              final uri = Uri.parse('https://github.com/Bill-GD/music_player_app/releases/tag/${widget.tag}');
              final canLaunch = await canLaunchUrl(uri);
              launchUrl(uri);
              if (canLaunch) {
                LogHandler.log('The system has found a handler, can launch URL');
              } else if (context.mounted) {
                LogHandler.log(
                  'URL launcher support query is not specified or can\'t launch URL, but opening regardless',
                );
              }
            },
            child: const Text('Get version'),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          side: BorderSide(color: Theme.of(context).colorScheme.onSurface),
        ),
        insetPadding: const EdgeInsets.only(top: 40, bottom: 16, left: 20, right: 20),
      ),
    );
  }
}
