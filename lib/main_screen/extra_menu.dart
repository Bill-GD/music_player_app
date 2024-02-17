import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: DrawerHeader(
              decoration: BoxDecoration(
                border: BorderDirectional(
                  bottom: BorderSide(color: Colors.grey[400]!),
                ),
              ),
              child: Text(
                'Menu',
                style: bottomSheetTitle.copyWith(fontSize: 35),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // const Divider(
          //   height: 1,
          //   thickness: 1,
          // ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListTile(
              leading: const Icon(CupertinoIcons.gear_alt_fill),
              title: const Text(
                'Settings',
                style: bottomSheetTitle,
              ),
              onTap: () {
                debugPrint('To app settings page');
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListTile(
              leading: const Icon(Icons.download_rounded),
              title: const Text('Download Music', style: bottomSheetTitle),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MusicDownloader()),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: GestureDetector(
                  child: Text(
                    '${packageInfo.appName} v${packageInfo.version}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: packageInfo.appName,
                    applicationVersion: packageInfo.version,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
