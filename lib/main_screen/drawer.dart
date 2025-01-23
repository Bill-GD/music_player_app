import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../music_downloader/music_downloader.dart';
import '../setting/setting.dart';
import '../widgets/file_picker.dart';

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
                    onTap: () {
                      Navigator.of(context).push<bool>(
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
                  listItemDivider(),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    leading: FaIcon(Icons.developer_mode_rounded, color: iconColor(context)),
                    title: const Text('Log', style: bottomSheetTitle),
                    onTap: () {
                      FilePicker.open(
                        context: context,
                        rootDirectory: Directory(Globals.lyricPath),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
