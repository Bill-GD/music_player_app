import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../globals/functions.dart';
import '../globals/log_handler.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';

class VersionCheck extends StatefulWidget {
  const VersionCheck({super.key});

  @override
  State<VersionCheck> createState() => _VersionCheckState();
}

class _VersionCheckState extends State<VersionCheck> {
  late StreamSubscription<List<ConnectivityResult>> connectStream;
  bool isInternetConnected = false;

  @override
  void initState() {
    super.initState();
    connectStream = Connectivity().onConnectivityChanged.listen((newResults) {
      checkInternetConnection(newResults).then((val) {
        isInternetConnected = val;
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    connectStream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'About',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
        ),
        body: ListView(
          children: [
            ListTile(
              title: leadingText(context, 'Current version', false, 16),
              subtitle: const Text(Globals.appVersion),
            ),
            ListTile(
              title: leadingText(context, 'Check latest', false, 16),
              subtitle: const Text('Check for the latest stable version of the app'),
              onTap: () {
                if (!isInternetConnected) {
                  showToast(context, 'No internet connection');
                  return;
                }
                http.get(
                  Uri.parse('https://api.github.com/repos/Bill-GD/music_player_app/releases/latest'),
                  headers: {'Authorization': 'Bearer ${Globals.githubToken}'},
                ).then((value) {
                  final json = jsonDecode(value.body);
                  if (json == null) throw Exception('Rate limited. Please come back later.');
                  if (json is! Map) {
                    LogHandler.log('JSON received is not a map', LogLevel.error);
                    throw Exception(
                      'Something is wrong when trying to get stable version. Please create an issue or consult the dev.',
                    );
                  }

                  final tag = json['tag_name'] as String;
                  showToast(context, tag);
                  LogHandler.log('Checked for latest stable version: $tag');
                });
              },
            ),
            ListTile(
              title: leadingText(context, 'Check pre-releases', false, 16),
              subtitle: const Text('Check for the latest dev version of the app'),
              onTap: () {
                if (!isInternetConnected) {
                  showToast(context, 'No internet connection');
                  return;
                }
                http.get(
                  Uri.parse('https://api.github.com/repos/Bill-GD/music_player_app/releases?per_page=4&page=1'),
                  headers: {'Authorization': 'Bearer ${Globals.githubToken}'},
                ).then((value) {
                  final json = jsonDecode(value.body);
                  if (json == null) throw Exception('Rate limited. Please come back later.');
                  if (json is! List) {
                    LogHandler.log('JSON received is not a list', LogLevel.error);
                    throw Exception(
                      'Something is wrong when trying to get dev version. Please create an issue or consult the dev.',
                    );
                  }

                  final latestDev = (json).firstWhere(
                    (r) => (r['tag_name'] as String).contains('_dev_'),
                  );
                  final tag = latestDev?['tag_name'] as String;
                  showToast(context, tag);
                  LogHandler.log('Checked for latest dev version: $tag');
                });
              },
            ),
            ListTile(
              title: leadingText(context, 'Licenses', false, 16),
              subtitle: const Text('View open-source licenses'),
              onTap: () {
                showLicensePage(
                  context: context,
                  applicationName: Globals.appName,
                  applicationVersion: 'v${Globals.appVersion}${isDev ? '' : ' - stable'}',
                );
              },
            ),
            ListTile(
              title: leadingText(context, 'GitHub Repo', false, 16),
              subtitle: const Text('Open GitHub repository of this app'),
              onTap: () async {
                const url = 'https://github.com/Bill-GD/music_player_app';
                final canLaunch = await canLaunchUrl(Uri.parse(url));
                LogHandler.log('Can launch URL: $canLaunch');
                if (canLaunch) launchUrl(Uri.parse(url));
              },
            ),
          ],
        ),
      ),
    );
  }
}
