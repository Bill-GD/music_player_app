import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../globals/log_handler.dart';
import '../globals/variables.dart';

class VersionDialog extends StatefulWidget {
  final bool dev;

  const VersionDialog({super.key, this.dev = false});

  @override
  State<VersionDialog> createState() => _VersionDialogState();
}

class _VersionDialogState extends State<VersionDialog> {
  final baseApiUrl = 'https://api.github.com/repos/Bill-GD/music_player_app';

  late final isStable = !widget.dev;
  bool loading = true;
  String tag = '';
  String body = '';

  @override
  void initState() {
    super.initState();
    getRelease();
  }

  Future<http.Response> apiQuery(String query) {
    LogHandler.log('Querying $query');
    return http.get(
      Uri.parse('$baseApiUrl$query'),
      headers: {'Authorization': 'Bearer ${Globals.githubToken}'},
    );
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
    setState(() => loading = false);
  }

  Future<String> getLatestDevTag() async {
    final res = await apiQuery('/git/refs/tags');

    final json = (jsonDecode(res.body) as List) //
        .map((e) => e['ref'] as String)
        .where((e) => e.contains('_dev_'))
        .toList();

    return json.last.split('/').last;
  }

  List<InlineSpan> getBody() {
    final List<InlineSpan> bodySpans = [];
    final List<String> bodyLines = body //
        .split(RegExp(r'(\r\n)|\n|(\n\n)'))
        .where((e) => !e.contains('**Full Changelog**'))
        .toList();
    while (bodyLines.isNotEmpty && bodyLines.last.trim().isEmpty) {
      bodyLines.removeLast();
    }

    for (final l in bodyLines) {
      int titleLevel = 0;
      String text = '';

      if (l.startsWith('#')) {
        final hashIndex = l.lastIndexOf('#');
        titleLevel = l.substring(0, hashIndex + 1).length;
        text = l.substring(hashIndex + 1).trim();
      } else {
        text = l.trim();
      }

      bodySpans.add(TextSpan(
        text: '$text\n',
        style: TextStyle(
          fontSize: titleLevel > 0 ? 24.0 - titleLevel : 16,
          fontWeight: titleLevel > 0 ? FontWeight.bold : null,
        ),
      ));
    }

    return bodySpans;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Latest ${isStable ? 'stable' : 'dev'} version\n$tag',
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
                text: TextSpan(children: getBody()),
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
