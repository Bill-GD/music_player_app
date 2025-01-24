import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../globals/extensions.dart';
import '../globals/functions.dart';
import '../globals/log_handler.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import 'version_list.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late StreamSubscription<List<ConnectivityResult>> connectStream;
  bool isInternetConnected = false;

  @override
  void initState() {
    super.initState();
    connectStream = Connectivity().onConnectivityChanged.listen((newResults) {
      checkInternetConnection(newResults).then((val) {
        setState(() => isInternetConnected = val);
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
        body: Column(
          children: [
            Visibility(
              visible: !isInternetConnected,
              child: Container(
                width: double.infinity,
                color: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: const Text(
                  'No Internet Connection',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                children: [
                  ListTile(
                    title: leadingText(context, 'Current version', false, 16),
                    subtitle: const Text(Globals.appVersion),
                  ),
                  ListTile(
                    title: leadingText(context, 'Version list', false, 16),
                    subtitle: const Text('View the list of versions of this app'),
                    onTap: () {
                      if (!isInternetConnected) return;

                      Navigator.of(context).push(PageRouteBuilder(
                        transitionDuration: 300.ms,
                        barrierDismissible: true,
                        barrierLabel: '',
                        transitionsBuilder: (_, anim1, __, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(-1, 0),
                              end: const Offset(0, 0),
                            ).animate(anim1),
                            child: child,
                          );
                        },
                        pageBuilder: (context, __, ___) {
                          return const VersionList();
                        },
                      ));
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
                    title: leadingText(context, 'Get releases', false, 16),
                    subtitle: const Text('Get the releases of this app'),
                    onTap: () async {
                      final uri = Uri.parse('https://github.com/Bill-GD/music_player_app/releases');
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
                  ),
                  ListTile(
                    title: leadingText(context, 'GitHub Repo', false, 16),
                    subtitle: const Text('Open GitHub repository of this app'),
                    onTap: () async {
                      final uri = Uri.parse('https://github.com/Bill-GD/music_player_app');
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
