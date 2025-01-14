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
  late final isStable = !widget.dev;
  bool loading = true;
  String tag = '';
  List<String> bodyLines = [];

  @override
  void initState() {
    super.initState();
    getRelease();
  }

  // TODO separate into get tags & get release (latest/by tag)
  void getRelease() {
    final url =
        'https://api.github.com/repos/Bill-GD/music_player_app/releases${isStable ? '/latest' : '?per_page=4&page=1'}';
    http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer ${Globals.githubToken}'},
    ).then((value) {
      final json = jsonDecode(value.body);
      if (json == null) throw Exception('Rate limited. Please come back later.');
      if (isStable && json is! Map) {
        LogHandler.log('JSON received is not a map', LogLevel.error);
        throw Exception(
          'Something is wrong when trying to get stable version. Please create an issue or consult the dev.',
        );
      }
      if (!isStable && json is! List) {
        LogHandler.log('JSON received is not a list', LogLevel.error);
        throw Exception(
          'Something is wrong when trying to get dev version. Please create an issue or consult the dev.',
        );
      }

      if (isStable) {
        tag = json['tag_name'] as String;
        bodyLines = (json['body'] as String).split(RegExp(r'(\r\n)|\n|(\n\n)'));
      } else {
        final latestDev = (json as List).firstWhere(
          (r) => (r['tag_name'] as String).contains('_dev_'),
        );
        tag = latestDev?['tag_name'] as String;
        bodyLines = (latestDev?['body'] as String).split(RegExp(r'(\r\n)|\n|(\n\n)'));
      }

      if (tag.isEmpty) throw Exception('Tag is empty. Please try again later.');
      if (bodyLines.isEmpty) {
        bodyLines = ['No description provided.'];
      } else {
        bodyLines.removeWhere((e) => e.contains('**Full Changelog**'));
        for (int i = bodyLines.length - 1; i >= 0; i--) {
          if (bodyLines[i].trim().isNotEmpty) break;
          bodyLines.removeAt(i);
        }
      }

      LogHandler.log('Checked for latest stable version: $tag');
      setState(() => loading = false);
    });
  }

  List<InlineSpan> getBody() {
    final List<InlineSpan> body = [];

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

      body.add(TextSpan(
        text: '$text\n',
        style: TextStyle(
          fontSize: titleLevel > 0 ? 24.0 - titleLevel : 16,
          fontWeight: titleLevel > 0 ? FontWeight.bold : null,
        ),
      ));
    }

    return body;
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
        // TextButton(
        //   onPressed: () {},
        //   child: const Text('Update'),
        // ),
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
