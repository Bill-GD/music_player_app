import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:theme_provider/theme_provider.dart';

import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../music_downloader/music_downloader.dart';

class ExtraMenu extends StatefulWidget {
  const ExtraMenu({super.key});

  @override
  State<ExtraMenu> createState() => _ExtraMenuState();
}

class _ExtraMenuState extends State<ExtraMenu> {
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
                      packageInfo.appName,
                      style: bottomSheetTitle.copyWith(fontSize: 24),
                    ),
                  ),
                  ListTile(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    leading: Icon(CupertinoIcons.gear_alt_fill, color: iconColor(context)),
                    title: const Text(
                      'Settings',
                      style: bottomSheetTitle,
                    ),
                    onTap: () {
                      debugPrint('To app settings page');
                    },
                  ),
                  listItemDivider(),
                  ListTile(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    leading: Icon(Icons.download_rounded, color: iconColor(context)),
                    title: const Text('Download Music', style: bottomSheetTitle),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MusicDownloader()),
                    ),
                  ),
                  listItemDivider(),
                  ListTile(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    leading: FaIcon(Icons.color_lens_rounded, color: iconColor(context)),
                    title: const Text('Change Theme', style: bottomSheetTitle),
                    onTap: () => ThemeProvider.controllerOf(context).nextTheme(),
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
                    'v${packageInfo.version}',
                    style: TextStyle(color: Colors.grey.withOpacity(0.5)),
                  ),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: packageInfo.appName,
                    applicationVersion: 'v${packageInfo.version}',
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

Divider listItemDivider() => const Divider(indent: 20, endIndent: 20);
