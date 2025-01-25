import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../globals/extensions.dart';
import '../globals/globals.dart';
import '../globals/widgets.dart';
import '../music_downloader/music_downloader.dart';
import '../setting/setting.dart';
import '../widgets/action_dialog.dart';

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
                            return const SettingsScreen();
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
                  _listItemDivider(),
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
                  _listItemDivider(),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    leading: FaIcon(Icons.logo_dev, color: iconColor(context)),
                    title: const Text('Log', style: bottomSheetTitle),
                    onTap: () {
                      _showLogPopup(context, title: 'Application log');
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

Divider _listItemDivider() => const Divider(indent: 20, endIndent: 20);

Future<void> _showLogPopup(
  BuildContext context, {
  required String title,
}) async {
  final logLines = File(Globals.logPath).readAsLinesSync();
  final contentLines = <String>[];

  for (final line in logLines) {
    if (line.isEmpty || !line.contains(']')) continue;

    final isError = line.contains('[E]');
    final time = line.substring(0, line.indexOf(']') + 1).trim();
    final content = line.substring(line.indexOf(']') + 5).trim();
    // final content = line;
    contentLines.add('t$time\n');
    contentLines.add('${isError ? 'e' : 'i'} - $content\n');
    contentLines.add(' \n');
  }
  contentLines.removeLast();
  contentLines.last = contentLines.last.substring(0, contentLines.last.length - 1);

  await ActionDialog.static<void>(
    context,
    title: title,
    titleFontSize: 28,
    widgetContent: RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
        children: [
          for (var line in contentLines)
            TextSpan(
              text: line.substring(1),
              style: TextStyle(
                color: line.startsWith('e')
                    ? Theme.of(context).colorScheme.error
                    : line.startsWith('t')
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
        ],
      ),
    ),
    contentFontSize: 16,
    centerContent: false,
    horizontalPadding: 24,
    time: 300.ms,
    allowScroll: true,
    actions: [
      TextButton(
        onPressed: Navigator.of(context).pop,
        child: const Text('OK'),
      ),
    ],
  );
}
