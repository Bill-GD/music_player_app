import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../globals/extensions.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../main_screen/backup.dart';
import 'about.dart';
import 'theme_setting.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool ignoreShortFile = Config.enableSongFiltering;
  int ignoreTimeLimit = Config.lengthLimitMilliseconds ~/ 1e3;
  bool autoPlay = Config.autoPlayNewSong;
  int delayBetween = Config.delayMilliseconds;
  bool autoBackup = Config.backupOnLaunch;
  double volume = Config.volume;

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
            'Settings',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.check_rounded, size: 30),
              onPressed: () async {
                bool needsUpdate = false, hasChanges = false;
                FocusManager.instance.primaryFocus?.unfocus();

                hasChanges = (ignoreShortFile != Config.enableSongFiltering ||
                    ignoreTimeLimit != Config.lengthLimitMilliseconds ~/ 1e3 ||
                    autoPlay != Config.autoPlayNewSong ||
                    autoBackup != Config.backupOnLaunch ||
                    delayBetween != Config.delayMilliseconds ||
                    volume != Config.volume);

                String changes = 'Confirm the following changes?\n\n';

                changes += ignoreShortFile != Config.enableSongFiltering
                    ? ignoreShortFile
                        ? 'Enable song filtering\n'
                        : 'Disable song filtering\n'
                    : '';

                changes += ignoreShortFile && ignoreTimeLimit != Config.lengthLimitMilliseconds ~/ 1e3
                    ? 'Filter file shorter than: $ignoreTimeLimit s\n'
                    : '';

                changes += autoPlay != Config.autoPlayNewSong
                    ? autoPlay
                        ? 'Enable auto play\n'
                        : 'Disable auto play\n'
                    : '';

                changes += autoBackup != Config.backupOnLaunch
                    ? autoBackup
                        ? 'Enable auto backup\n'
                        : 'Disable auto backup\n'
                    : '';
                changes += delayBetween != Config.delayMilliseconds ? 'Delay between songs: $delayBetween ms\n' : '';
                changes += volume != Config.volume ? 'Volume: x$volume\n' : '';

                if (hasChanges) {
                  await dialogWithActions(
                    context,
                    title: 'Confirm changes',
                    titleFontSize: 24,
                    textContent: changes,
                    contentFontSize: 16,
                    time: 300.ms,
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () async {
                          needsUpdate = true;
                          Config.enableSongFiltering = ignoreShortFile;
                          Config.lengthLimitMilliseconds = ignoreTimeLimit * 1000;
                          Config.autoPlayNewSong = autoPlay;
                          Config.delayMilliseconds = delayBetween;
                          Config.backupOnLaunch = autoBackup;
                          Config.volume = volume;
                          Globals.audioHandler.setVolume(Config.volume);
                          await Config.saveConfig();
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: const Text('Yes'),
                      ),
                    ],
                  );
                }
                if ((needsUpdate || !hasChanges) && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Text(
                'APP SETTINGS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            SwitchListTile(
              title: leadingText(context, 'Backup data on launch', false, 16),
              subtitle: const Text('Backup data on app launch. May be undesirable in certain situations.'),
              value: autoBackup,
              onChanged: (value) {
                setState(() => autoBackup = value);
              },
            ),
            ListTile(
              title: leadingText(context, 'Theme', false, 16),
              subtitle: const Text('Customize the app\'s theme'),
              trailing: const Icon(CupertinoIcons.right_chevron),
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const ThemeSetting(),
                    transitionsBuilder: (context, anim, _, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(-1, 0),
                          end: const Offset(0, 0),
                        ).animate(anim.drive(CurveTween(curve: Curves.decelerate))),
                        child: child,
                      );
                    },
                  ),
                );
              },
            ),
            ListTile(
              title: leadingText(context, 'Backup', false, 16),
              subtitle: const Text('Save and restore app data'),
              trailing: const Icon(CupertinoIcons.right_chevron),
              onTap: () {
                Navigator.of(context).push(
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
            ListTile(
              title: leadingText(context, 'Version', false, 16),
              subtitle: const Text(Globals.appVersion),
              trailing: const Icon(CupertinoIcons.right_chevron),
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const AboutPage(),
                    transitionsBuilder: (context, anim, _, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(-1, 0),
                          end: const Offset(0, 0),
                        ).animate(anim.drive(CurveTween(curve: Curves.decelerate))),
                        child: child,
                      );
                    },
                  ),
                );
              },
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Text(
                'FILE SETTINGS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            SwitchListTile(
              title: leadingText(context, 'Song Filter', false, 16),
              subtitle: const Text('Ignore short files'),
              value: ignoreShortFile,
              onChanged: (value) => setState(() => ignoreShortFile = value),
            ),
            Visibility(
              visible: ignoreShortFile,
              child: Column(
                children: [
                  ListTile(
                    title: leadingText(context, 'Time', false, 16),
                    subtitle: Text('Hide files shorter than $ignoreTimeLimit seconds'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text('0 sec'),
                        Expanded(
                          child: Slider(
                            value: ignoreTimeLimit.toDouble(),
                            min: 0,
                            max: 300,
                            onChanged: (value) {
                              if (!ignoreShortFile) return;
                              setState(() => ignoreTimeLimit = value.toInt());
                            },
                            divisions: 30,
                          ),
                        ),
                        const Text('5 mins'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Text(
                'PLAYER SETTINGS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            SwitchListTile(
              title: leadingText(context, 'Auto play new song', false, 16),
              subtitle: const Text('Starts playing when choosing a new song'),
              value: autoPlay,
              onChanged: (value) {
                setState(() => autoPlay = value);
              },
            ),
            Column(
              children: [
                ListTile(
                  title: leadingText(context, 'Delay between songs', false, 16),
                  subtitle: Text('Short delay of $delayBetween ms when skipping song'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text('0'),
                      Expanded(
                        child: Slider(
                          value: delayBetween.toDouble(),
                          min: 0.0,
                          max: 500.0,
                          onChanged: (value) => setState(() => delayBetween = value.toInt()),
                        ),
                      ),
                      const Text('500'),
                    ],
                  ),
                ),
              ],
            ),
            ListTile(
              title: leadingText(context, 'Volume', false, 16),
              subtitle: Text('Change the player\'s base volume (${(volume * 100).toInt()}%)'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('0%'),
                  Expanded(
                    child: Slider(
                      value: volume,
                      min: 0,
                      max: 1,
                      onChanged: (value) => setState(() => volume = value),
                      divisions: 100,
                    ),
                  ),
                  const Text('100%'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
