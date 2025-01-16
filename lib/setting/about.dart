import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../globals/extensions.dart';
import '../globals/functions.dart';
import '../globals/log_handler.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import 'version_dialog.dart';

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
                    onTap: () {
                      if (!isInternetConnected) return;

                      Navigator.of(context).push(RawDialogRoute(
                        transitionDuration: 300.ms,
                        barrierDismissible: true,
                        barrierLabel: '',
                        transitionBuilder: (_, anim1, __, child) {
                          return ScaleTransition(
                            scale: anim1.drive(CurveTween(curve: Curves.easeOutQuart)),
                            alignment: Alignment.center,
                            child: child,
                          );
                        },
                        pageBuilder: (context, __, ___) {
                          return const VersionDialog(changelog: true);
                        },
                      ));
                    },
                  ),
                  ListTile(
                    title: leadingText(context, 'Check latest', false, 16),
                    subtitle: const Text('Check for the latest stable version of the app'),
                    onTap: () {
                      if (!isInternetConnected) return;

                      Navigator.of(context).push(RawDialogRoute(
                        transitionDuration: 300.ms,
                        barrierDismissible: true,
                        barrierLabel: '',
                        transitionBuilder: (_, anim1, __, child) {
                          return ScaleTransition(
                            scale: anim1.drive(CurveTween(curve: Curves.easeOutQuart)),
                            alignment: Alignment.center,
                            child: child,
                          );
                        },
                        pageBuilder: (context, __, ___) {
                          return const VersionDialog();
                        },
                      ));
                    },
                  ),
                  ListTile(
                    title: leadingText(context, 'Dev changes', false, 16),
                    subtitle: const Text('Get the dev changes of this version'),
                    onTap: () {
                      if (!isInternetConnected) return;

                      Navigator.of(context).push(RawDialogRoute(
                        transitionDuration: 300.ms,
                        barrierDismissible: true,
                        barrierLabel: '',
                        transitionBuilder: (_, anim1, __, child) {
                          return ScaleTransition(
                            scale: anim1.drive(CurveTween(curve: Curves.easeOutQuart)),
                            alignment: Alignment.center,
                            child: child,
                          );
                        },
                        pageBuilder: (context, __, ___) {
                          return const VersionDialog(dev: true, changelog: true);
                        },
                      ));
                    },
                  ),
                  ListTile(
                    title: leadingText(context, 'Check pre-releases', false, 16),
                    subtitle: const Text('Check for the latest dev version of the app'),
                    onTap: () {
                      if (!isInternetConnected) return;

                      Navigator.of(context).push(RawDialogRoute(
                        transitionDuration: 300.ms,
                        barrierDismissible: true,
                        barrierLabel: '',
                        transitionBuilder: (_, anim1, __, child) {
                          return ScaleTransition(
                            scale: anim1.drive(CurveTween(curve: Curves.easeOutQuart)),
                            alignment: Alignment.center,
                            child: child,
                          );
                        },
                        pageBuilder: (context, __, ___) {
                          return const VersionDialog(dev: true);
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
          ],
        ),
      ),
    );
  }
}
