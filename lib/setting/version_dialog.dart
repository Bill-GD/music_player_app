import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../globals/log_handler.dart';
import '../globals/variables.dart';

class VersionDialog extends StatefulWidget {
  final bool dev;
  final bool changelog;

  const VersionDialog({super.key, this.dev = false, this.changelog = false});

  @override
  State<VersionDialog> createState() => _VersionDialogState();
}

class _VersionDialogState extends State<VersionDialog> {
  final baseApiUrl = 'https://api.github.com/repos/Bill-GD/music_player_app';

  late final isStable = !widget.dev, getChangelog = widget.changelog;
  bool loading = true;
  String tag = '', body = '', changelog = ''; //, sha = '';

  @override
  void initState() {
    super.initState();
    if (getChangelog) {
      getChangelogContent();
    } else {
      getRelease();
    }
  }

  Future<void> getChangelogContent() async {
    final filename = isStable ? 'release_note.md' : 'dev_changes.md';
    final sha = await getSHA(isStable ? null : await getLatestTag());
    final res = await apiQuery('/contents/$filename?ref=$sha');
    final json = jsonDecode(res.body);

    if (json == null) throw Exception('Rate limited. Please come back later.');
    if (json is! Map) {
      LogHandler.log('JSON received is not a map', LogLevel.error);
      throw Exception(
        'Something is wrong when trying to get changelog. Please create an issue or consult the dev.',
      );
    }

    changelog = utf8.decode(base64Decode(
      (json['content'] as String).replaceAll('\n', ''),
    ));
    LogHandler.log('Checked for latest dev changelog: $tag');
    if (mounted) setState(() => loading = false);
  }

  Future<void> getRelease() async {
    final res = await apiQuery(isStable ? '/releases/latest' : '/releases/tags/${await getLatestDevTag()}');
    final json = jsonDecode(res.body);

    if (json == null) throw Exception('Rate limited. Please come back later.');
    if (json is! Map) {
      LogHandler.log('JSON received is not a map', LogLevel.error);
      throw Exception(
        'Something is wrong when trying to get version. Please create an issue or consult the dev.',
      );
    }

    tag = json['tag_name'] as String;
    body = json['body'] as String;

    LogHandler.log('Checked for latest ${isStable ? 'stable' : 'dev'} version: $tag');
    if (mounted) setState(() => loading = false);
  }

  Future<String> getSHA([String? selectedTag]) async {
    final res = await apiQuery('/git/refs/tags');
    final json = jsonDecode(res.body);

    if (json == null) throw Exception('Rate limited. Please come back later.');
    if (json is! List) {
      LogHandler.log('JSON received is not a list', LogLevel.error);
      throw Exception(
        'Something is wrong when trying to get SHA. Please create an issue or consult the dev.',
      );
    }

    final Map tagJson = json.firstWhere((e) => e['ref'] == 'refs/tags/${selectedTag ?? 'v${Globals.appVersion}'}');
    tag = selectedTag ?? 'v${Globals.appVersion}';
    // sha =
    return (tagJson['object']['sha'] as String).substring(0, 7);
  }

  Future<String> getLatestDevTag() async {
    final res = await apiQuery('/git/refs/tags');
    final json = jsonDecode(res.body);

    if (json == null) throw Exception('Rate limited. Please come back later.');
    if (json is! List) {
      LogHandler.log('JSON received is not a list', LogLevel.error);
      throw Exception(
        'Something is wrong when trying to get latest dev tag. Please create an issue or consult the dev.',
      );
    }

    final List<String> devTags = json //
        .map((e) => e['ref'] as String)
        .where((e) => e.contains('_dev_'))
        .toList();

    return devTags.last.split('/').last;
  }

  Future<String> getLatestTag() async {
    final res = await apiQuery('/git/refs/tags');
    final json = jsonDecode(res.body);

    if (json == null) throw Exception('Rate limited. Please come back later.');
    if (json is! List) {
      LogHandler.log('JSON received is not a list', LogLevel.error);
      throw Exception(
        'Something is wrong when trying to get latest tag. Please create an issue or consult the dev.',
      );
    }

    final List<String> tags = json //
        .map((e) => e['ref'] as String)
        .toList();

    return tags.last.split('/').last;
  }

  Future<http.Response> apiQuery(String query) {
    LogHandler.log('Querying $query');
    return http.get(
      Uri.parse('$baseApiUrl$query'),
      headers: {'Authorization': 'Bearer ${Globals.githubToken}'},
    );
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
          fontSize: titleLevel > 0 ? 24.0 - titleLevel : 16,
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
        '${getChangelog ? '${isStable ? 'C' : 'Dev c'}hangelog for' : 'Latest ${isStable ? 'stable' : 'dev'} version'}\n$tag',
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
                text: TextSpan(children: getContent(getChangelog ? changelog : body)),
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
