import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../player/player_utils.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool ignoreShortFile = false;
  int time = 0;
  bool autoPlayNewSong = true;
  double delayBetweenSongs = 0.0;
  double gapBetweenSongs = 0.0;
  double volume = 0.5;

  final TextEditingController _timerController = TextEditingController();
  Duration _selectedDuration = Duration();
  AudioPlayerHandler audioPlayerHandler = AudioPlayerHandler();

   @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  void scheduleTimer() {
    Duration duration = _selectedDuration;
    audioPlayerHandler.startTimer(duration);
  }

  void cancelScheduledTimer() {
    audioPlayerHandler.cancelTimer();
  }

  late AudioPlayer audioPlayer = AudioPlayer();

  void updateAutoPlayNext() {
    AudioPlayerHandler().autoPlayNewSong = autoPlayNewSong;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text('Settings'),
        ),
        body: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            Text(
              'File Setting',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SwitchListTile(
              title: Text('Ignore short file'),
              value: ignoreShortFile,
              onChanged: (value) {
                setState(() {
                  ignoreShortFile = value;
                });
              },
            ),
            TextFormField(
              initialValue: time.toString(),
              onChanged: (value) {
                setState(() {
                  int minutes = int.tryParse(value) ?? 0;
                  _selectedDuration = Duration(minutes: minutes);
                });
              },
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Time',
              ),
            ),
            Text(
              'Player Setting',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SwitchListTile(
              title: Text('Auto Play New Song'),
              value: autoPlayNewSong,
              onChanged: (value) {
                setState(() {
                  autoPlayNewSong = value;
                  updateAutoPlayNext();
                });
              },
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'Delay Between Songs: ${delayBetweenSongs.toStringAsFixed(1)}'),
                Text('500.0'),
              ],
            ),
            Slider(
              value: delayBetweenSongs,
              min: 0.0,
              max: 500.0,
              onChanged: (value) {
                setState(() {
                  delayBetweenSongs = value;
                  Duration newDuration = Duration(milliseconds: value.toInt());
                  AudioPlayerHandler().updateDelayDuration(newDuration);
                });
                audioPlayer.setReleaseMode(ReleaseMode.release);
              },
              divisions: 10,
              label: delayBetweenSongs.toStringAsFixed(1),
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Volume: ${volume.toStringAsFixed(1)}'),
                Text('5.0'),
              ],
            ),
            Slider(
              value: volume,
              min: 0.0,
              max: 5.0,
              onChanged: (value) {
                setState(() {
                  volume = value;
                });
                audioPlayer.setVolume(volume);
              },
              divisions: 10,
              label: volume.toStringAsFixed(1),
            ),
          ],
        ),
      ),
    );
  }
}
