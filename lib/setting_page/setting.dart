import 'package:dedent/dedent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../globals/variables.dart';
import '../globals/widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _timerController = TextEditingController();

  bool ignoreShortFile = Config.enableSongFiltering;
  int ignoreTimeLimit = Config.lengthLimitMilliseconds ~/ 1e3;
  bool autoPlay = Config.autoPlayNewSong;
  int delayBetween = Config.delayMilliseconds;
  double volume = Config.volume;

  @override
  void dispose() {
    _timerController.dispose();
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
                changes +=
                    delayBetween != Config.delayMilliseconds ? 'Delay between songs: $delayBetween ms\n' : '';
                changes += volume != Config.volume ? 'Volume: x$volume\n' : '';

                if (hasChanges) {
                  await showGeneralDialog(
                    context: context,
                    transitionDuration: 300.ms,
                    transitionBuilder: (_, anim1, __, child) {
                      return ScaleTransition(
                        scale: anim1.drive(CurveTween(curve: Curves.easeOutQuart)),
                        child: child,
                      );
                    },
                    barrierDismissible: true,
                    barrierLabel: '',
                    pageBuilder: (context, _, __) {
                      return AlertDialog(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        title: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Confirm Changes',
                            textAlign: TextAlign.center,
                            style: bottomSheetTitle.copyWith(fontSize: 24),
                          ),
                        ),
                        alignment: Alignment.center,
                        contentPadding: const EdgeInsets.only(left: 10, right: 10, top: 40),
                        content: Text(
                          changes,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        actionsAlignment: MainAxisAlignment.spaceAround,
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('NO'),
                          ),
                          TextButton(
                            onPressed: () {
                              needsUpdate = true;
                              Config.enableSongFiltering = ignoreShortFile;
                              Config.lengthLimitMilliseconds = ignoreTimeLimit * 1000;
                              Config.autoPlayNewSong = autoPlay;
                              Config.delayMilliseconds = delayBetween;
                              Config.volume = volume;
                              Globals.audioHandler.setVolume(Config.volume);
                              Config.saveConfig();
                              Navigator.of(context).pop();
                            },
                            child: const Text('YES'),
                          ),
                        ],
                      );
                    },
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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            Container(
              margin: const EdgeInsets.only(top: 20, bottom: 10),
              child: const Text(
                'File Settings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            SwitchListTile(
              title: Row(
                children: [
                  leadingText(context, 'Song Filter', false, 16),
                  getSettingOptionInfo(
                    context,
                    'Ignore short files',
                    dedent('''
                    Ignore all .mp3 files that are short enough.
                    If turned off, the app will get all mp3 files in Downloads folder, regardless of length.

                    If you changed this, you should refresh the song list to update.
                    All songs that were filtered will have their data deleted.
                    '''),
                  ),
                ],
              ),
              value: ignoreShortFile,
              onChanged: (value) => setState(() => ignoreShortFile = value),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                children: [
                  leadingText(context, 'Time (in seconds)', false, 16),
                  getSettingOptionInfo(
                    context,
                    'Time limit to filter',
                    dedent('''
                    The app will ignore all .mp3 files that are shorter than this time in seconds.
                    If song filter is disabled, this option is ignored.

                    If you changed this, you should refresh the song list to update.
                    All songs that were filtered will have their data deleted.
                    '''),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 100, right: 16),
                      child: TextField(
                        enabled: ignoreShortFile,
                        controller: _timerController..text = ignoreTimeLimit.toString(),
                        onChanged: (value) => ignoreTimeLimit = value.isNotEmpty ? int.parse(value) : 0,
                        keyboardType: TextInputType.number,
                        decoration: textFieldDecoration(
                          context,
                          fillColor: Theme.of(context).colorScheme.background,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 40, bottom: 10),
              child: const Text(
                'Player Setting',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            SwitchListTile(
              title: Row(
                children: [
                  leadingText(context, 'Auto play new song', false, 16),
                  getSettingOptionInfo(
                    context,
                    'New song will auto start',
                    dedent('''
                    When a new song is chosen or skipped to, the player will automatically start playing music.
                    If turned off, you have to start playing manually.
                    '''),
                  ),
                ],
              ),
              value: autoPlay,
              onChanged: (value) {
                setState(() => autoPlay = value);
              },
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                children: [
                  leadingText(context, 'Delay between songs:', false, 16),
                  getSettingOptionInfo(
                    context,
                    'Short delay when skipping song',
                    dedent('''
                    When playing a playlist and the song is finished, the player will change song after a delay.
                    The delay is in milliseconds, from 0 to 500.
                    '''),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('0'),
                  Text('500'),
                ],
              ),
            ),
            Slider(
              value: delayBetween.toDouble(),
              min: 0.0,
              max: 500.0,
              label: delayBetween.toString(),
              onChanged: (value) => setState(() => delayBetween = value.toInt()),
              divisions: 10,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                children: [
                  leadingText(context, 'Volume:', false, 16),
                  getSettingOptionInfo(
                    context,
                    'Changing base volume',
                    dedent('''
                    Changing the base volume of the player.
                    You should not set it too high unless the volume output is too low.

                    The normal volume is 1, which is 1 time the normal volume.
                    The range is from 0.5 to 5.
                    '''),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('0.5'),
                  Text('5'),
                ],
              ),
            ),
            Slider(
              value: volume,
              min: 0.5,
              max: 5.0,
              label: volume.toString(),
              onChanged: (value) => setState(() => volume = value),
              divisions: 9,
            ),
          ],
        ),
      ),
    );
  }
}

Widget getSettingOptionInfo(BuildContext context, String title, String content) => GestureDetector(
      onTap: () async {
        await showOptionInfo(context, title, content);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(
          Icons.help_rounded,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );

Future<void> showOptionInfo(BuildContext context, String title, String content) async {
  await showGeneralDialog(
    context: context,
    transitionDuration: 300.ms,
    transitionBuilder: (_, anim1, __, child) {
      return ScaleTransition(
        scale: anim1.drive(CurveTween(curve: Curves.easeOutQuart)),
        child: child,
      );
    },
    barrierDismissible: true,
    barrierLabel: '',
    pageBuilder: (context, _, __) {
      return AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: bottomSheetTitle.copyWith(fontSize: 24),
        ),
        alignment: Alignment.center,
        contentPadding: const EdgeInsets.only(left: 10, right: 10, top: 40),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            content,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceAround,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
