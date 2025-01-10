import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../globals/extensions.dart';
import '../globals/log_handler.dart';
import '../globals/music_track.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../music_downloader/music_downloader.dart';
import '../setting/setting.dart';
import 'backup.dart';

class MainDrawer extends StatefulWidget {
  const MainDrawer({super.key});

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 15, bottom: 10, top: 5),
                    title: Text(
                      Globals.appName,
                      style: bottomSheetTitle.copyWith(fontSize: 24),
                    ),
                  ),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    leading: FaIcon(FontAwesomeIcons.gear, color: iconColor(context)),
                    title: const Text(
                      'Settings',
                      style: bottomSheetTitle,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) {
                            return const SettingsPage();
                          },
                          transitionsBuilder: (context, anim1, _, child) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(-1, 0),
                                end: const Offset(0, 0),
                              ).animate(anim1.drive(CurveTween(curve: Curves.decelerate))),
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                  ),
                  listItemDivider(),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    leading: Icon(Icons.download_rounded, color: iconColor(context)),
                    title: const Text('Download Music', style: bottomSheetTitle),
                    onTap: () async {
                      final hasChanged = await Navigator.of(context).push<bool>(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) {
                            return const MusicDownloader();
                          },
                          transitionsBuilder: (context, anim1, _, child) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(-1, 0),
                                end: const Offset(0, 0),
                              ).animate(anim1.drive(CurveTween(curve: Curves.decelerate))),
                              child: child,
                            );
                          },
                        ),
                      );
                      if (hasChanged == true) {
                        await updateMusicData();
                        sortAllSongs();
                        // updateChildren();
                      }
                    },
                  ),
                  listItemDivider(),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    leading: FaIcon(Icons.file_copy, color: iconColor(context)),
                    title: const Text('Backup', style: bottomSheetTitle),
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const BackupScreen(),
                          transitionsBuilder: (context, anim1, _, child) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(-1, 0),
                                end: const Offset(0, 0),
                              ).animate(anim1.drive(CurveTween(curve: Curves.decelerate))),
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                  ),
                  listItemDivider(),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    leading: FaIcon(Icons.logo_dev, color: iconColor(context)),
                    title: const Text('Log', style: bottomSheetTitle),
                    onTap: () {
                      showLogPopup(context, title: 'Application log');
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 4),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: GestureDetector(
                  child: Text(
                    // 'v${Globals.appVersion}${isDev ? '_dev' : ''}',
                    'v${Globals.appVersion}',
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.5),
                    ),
                  ),
                  onTap: () => showGeneralDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: '',
                    transitionDuration: 300.ms,
                    transitionBuilder: (_, anim1, __, child) {
                      return ScaleTransition(
                        scale: anim1.drive(CurveTween(curve: Curves.easeOutQuart)),
                        alignment: Alignment.bottomLeft,
                        child: child,
                      );
                    },
                    pageBuilder: (context, _, __) {
                      return AboutDialog(
                        applicationName: Globals.appName,
                        applicationVersion: 'v${Globals.appVersion}${isDev ? '' : ' - stable'}',
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              const url = 'https://github.com/Bill-GD/music_player_app';
                              final canLaunch = await canLaunchUrl(Uri.parse(url));
                              LogHandler.log('Can launch URL: $canLaunch');
                              if (canLaunch) launchUrl(Uri.parse(url));
                            },
                            icon: const Icon(Icons.code_rounded),
                            label: const Text('GitHub repo'),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
