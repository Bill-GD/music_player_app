import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../globals/config.dart';
import '../globals/extensions.dart';
import '../globals/globals.dart';
import '../globals/widgets.dart';
import '../widgets/action_dialog.dart';
import 'about.dart';
import 'backup.dart';
import 'theme_setting.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool hasChanges = false;

  bool autoBackup = Config.backupOnLaunch;
  bool ignoreShortFile = Config.enableSongFiltering;
  int ignoreTimeLimit = Config.lengthLimitMilliseconds ~/ 1e3;
  bool autoPlay = Config.autoPlayNewSong;
  int delayBetween = Config.delayMilliseconds;
  bool appendLyric = Config.appendLyric;
  double volume = Config.volume;
  int backupCount = Config.backupCount;

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
              icon: const Icon(Icons.save_rounded),
              onPressed: hasChanges
                  ? () async {
                      FocusManager.instance.primaryFocus?.unfocus();

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

                      changes += appendLyric != Config.appendLyric
                          ? appendLyric
                              ? 'Enable append lyric\n'
                              : 'Disable append lyric\n'
                          : '';

                      changes += autoBackup != Config.backupOnLaunch
                          ? autoBackup
                              ? 'Enable auto backup\n'
                              : 'Disable auto backup\n'
                          : '';
                      changes +=
                          delayBetween != Config.delayMilliseconds ? 'Delay between songs: $delayBetween ms\n' : '';
                      changes += volume != Config.volume ? 'Volume: x$volume\n' : '';
                      changes += backupCount != Config.backupCount ? 'Backup count: $backupCount\n' : '';

                      if (changes.endsWith('\n')) changes = changes.substring(0, changes.length - 1);

                      if (hasChanges) {
                        final needsUpdate = await ActionDialog.static<bool>(
                          context,
                          title: 'Confirm changes',
                          titleFontSize: 24,
                          textContent: changes,
                          contentFontSize: 16,
                          time: 300.ms,
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Config.backupOnLaunch = autoBackup;
                                Config.enableSongFiltering = ignoreShortFile;
                                Config.lengthLimitMilliseconds = ignoreTimeLimit * 1000;
                                Config.autoPlayNewSong = autoPlay;
                                Config.delayMilliseconds = delayBetween;
                                Config.appendLyric = appendLyric;
                                Config.volume = volume;
                                Globals.audioHandler.setVolume(Config.volume);
                                Config.backupCount = backupCount;
                                await Config.saveConfig();
                                if (context.mounted) Navigator.of(context).pop(true);
                              },
                              child: const Text('Yes'),
                            ),
                          ],
                        );

                        if (needsUpdate == true) setState(() => hasChanges = false);
                      }
                    }
                  : null,
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
                hasChanges = value != Config.backupOnLaunch;
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
            Column(
              children: [
                ListTile(
                  title: leadingText(context, 'Backup count', false, 16),
                  subtitle: Text('Number of backups to keep: $backupCount'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text('5'),
                      Expanded(
                        child: Slider(
                          value: backupCount.toDouble(),
                          min: 5,
                          max: 15,
                          onChanged: (value) {
                            hasChanges = value.toInt() != Config.backupCount;
                            setState(() => backupCount = value.toInt());
                          },
                        ),
                      ),
                      const Text('15'),
                    ],
                  ),
                ),
              ],
            ),
            ListTile(
              title: leadingText(context, 'Version', false, 16),
              subtitle: const Text(Globals.appVersion),
              trailing: const Icon(CupertinoIcons.right_chevron),
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const AboutScreen(),
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
              onChanged: (value) {
                hasChanges = value != Config.enableSongFiltering;
                setState(() => ignoreShortFile = value);
              },
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
                              hasChanges = value.toInt() != Config.lengthLimitMilliseconds ~/ 1e3;
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
                hasChanges = value != Config.autoPlayNewSong;
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
                          onChanged: (value) {
                            hasChanges = value.toInt() != Config.delayMilliseconds;
                            setState(() => delayBetween = value.toInt());
                          },
                        ),
                      ),
                      const Text('500'),
                    ],
                  ),
                ),
              ],
            ),
            SwitchListTile(
              title: leadingText(context, 'Append lyric', false, 16),
              subtitle: const Text('Only add lines instead of free lyric editing'),
              value: appendLyric,
              onChanged: (value) {
                hasChanges = value != Config.appendLyric;
                setState(() => appendLyric = value);
              },
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
                      onChanged: (value) {
                        hasChanges = value != Config.volume;
                        setState(() => volume = value);
                      },
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
