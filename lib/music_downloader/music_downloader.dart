import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dedent/dedent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../globals/functions.dart';
import '../globals/widgets.dart';
import 'soundcloud_downloader.dart';
import 'youtube_downloader.dart';

class MusicDownloader extends StatefulWidget {
  const MusicDownloader({super.key});

  @override
  State<MusicDownloader> createState() => _MusicDownloaderState();
}

class _MusicDownloaderState extends State<MusicDownloader> {
  final _yt = YoutubeExplode();
  late final TextEditingController _textEditingController;

  Map<String, dynamic>? _metadata;

  bool _isFromSoundCloud = false;
  bool _isGettingData = false, _isInternetConnected = true, _isDownloading = false, _hasDownloaded = false;
  int _received = 0, _total = 0;

  String? _errorText;

  late StreamSubscription<ConnectivityResult> connectStream;

  void _checkInternetConnection([ConnectivityResult? result]) async {
    final connectivityResult = result ?? await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.ethernet) {
      _isInternetConnected = true;
    } else if (connectivityResult == ConnectivityResult.none) {
      _isInternetConnected = false;
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _validateInput(String text) {
    _errorText = null;
    if (text.isEmpty) {
      _errorText = null;
    } else if (RegExp(r'^(?:https:\/\/)?(?:on\.soundcloud\.com)(?:\S+)?$').hasMatch(text)) {
      _errorText = 'Please use full URL, SoundCloud API is weird';
    } else if (!RegExp(
                r'^(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})(?:\S+)?$')
            .hasMatch(text) &&
        !RegExp(r'^(?:https:\/\/)?(m\.)?(?:soundcloud\.com)\/([a-zA-Z0-9_-]*)\/([a-zA-Z0-9_-])(?:\S+)?$')
            .hasMatch(text)) {
      _errorText = 'Invalid URL';
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
    connectStream = Connectivity().onConnectivityChanged.listen((newResult) {
      _checkInternetConnection(newResult);
    });
    _textEditingController = TextEditingController();
  }

  @override
  void dispose() {
    connectStream.cancel();
    super.dispose();
    _yt.close();
    _textEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () {
              if (_isDownloading) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('App is downloading music, please wait')),
                );
                return;
              }
              Navigator.of(context).pop(_hasDownloaded);
            },
          ),
          centerTitle: true,
          title: const Text(
            'Music Downloader',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_rounded),
              onPressed: () {
                showGeneralDialog(
                  context: context,
                  transitionDuration: 300.ms,
                  transitionBuilder: (_, anim1, __, child) {
                    return ScaleTransition(
                      scale: anim1.drive(CurveTween(curve: Curves.easeOutQuart)),
                      alignment: Alignment.topRight,
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
                        'Instruction',
                        textAlign: TextAlign.center,
                        style: bottomSheetTitle.copyWith(fontSize: 24),
                      ),
                      alignment: Alignment.center,
                      contentPadding: const EdgeInsets.only(left: 10, right: 10, top: 30),
                      content: Text(
                        dedent('''
                        Enter YouTube or SoundCloud link into the text field.
                        Press the get data button.
                        Wait for the app to fetch the data.
                        Press the download button.
                        Wait for the app to download the music.
                        '''),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
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
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // no connectivity
            Visibility(
              visible: !_isInternetConnected,
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
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // link input
                      TextField(
                        enabled: _isInternetConnected || _isDownloading,
                        controller: _textEditingController,
                        onChanged: _validateInput,
                        decoration: textFieldDecoration(
                          context,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          fillColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
                          hintText: 'Enter YouTube or SoundCloud link',
                          labelText: 'Music Link',
                          errorText: _errorText,
                          suffixIcon: _isGettingData
                              ? Container(
                                  width: 20,
                                  height: 20,
                                  margin: const EdgeInsets.only(right: 20),
                                  child: Center(
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 3,
                                    ).animate(
                                      effects: const [FadeEffect()],
                                      onComplete: (controller) {},
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      // get data button
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ElevatedButton(
                          onPressed: _textEditingController.text.isNotEmpty &&
                                  !_isDownloading &&
                                  _errorText == null
                              ? () async {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  _isFromSoundCloud = _textEditingController.text.contains('soundcloud.com');
                                  setState(() {
                                    _isGettingData = true;
                                    _metadata = null;
                                  });
                                  _metadata = _isFromSoundCloud
                                      ? await getSoundCloudSongData(context, _textEditingController.text)
                                      : await getYouTubeVideoData(context, _textEditingController.text);
                                  setState(() => _isGettingData = false);
                                }
                              : null,
                          style: textButtonStyle(context),
                          child: const Text('Get Music Data'),
                        ),
                      ),
                    ],
                  ),
                  if (_metadata == null)
                    const SizedBox.shrink()
                  else
                    Animate(
                      effects: const [FadeEffect()],
                      child: Column(
                        children: [
                          // video info
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  margin: _isFromSoundCloud
                                      ? const EdgeInsets.only(left: 60, right: 30)
                                      : const EdgeInsets.only(left: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: _metadata!['thumbnailUrl'] == null
                                      ? BoxDecoration(
                                          border: Border.all(
                                            color: Theme.of(context).colorScheme.onBackground,
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                        )
                                      : null,
                                  child: _metadata!['thumbnailUrl'] == null
                                      ? Icon(
                                          Icons.music_note_rounded,
                                          color: Theme.of(context).colorScheme.primary,
                                        )
                                      : Image.network(_metadata!['thumbnailUrl'], fit: BoxFit.fitHeight),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        Text(
                                          _metadata!['title'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(_metadata!['author']),
                                        Text(
                                          (_metadata!['duration'] as Duration).toStringNoMilliseconds(),
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          // download button
                          ElevatedButton(
                            onPressed: _isDownloading
                                ? null
                                : () async {
                                    setState(() {
                                      _isDownloading = true;
                                      _hasDownloaded = true;
                                    });
                                    _isFromSoundCloud
                                        ? await downloadSoundCloudMP3(
                                            context,
                                            _metadata!['trackUrl'],
                                            _metadata!['title'],
                                            (received, total) {
                                              setState(() {
                                                _received = received;
                                                _total = total;
                                              });
                                            },
                                          )
                                        : await downloadYoutubeMP3(
                                            context,
                                            _textEditingController.text,
                                            _metadata!['title'],
                                            (received, total) {
                                              setState(() {
                                                _received = received;
                                                _total = total;
                                              });
                                            },
                                          );
                                    setState(() => _isDownloading = false);
                                  },
                            style: textButtonStyle(context),
                            child: const Text('Download Music'),
                          ),
                        ],
                      ),
                    ),
                  // download progress
                  if (_total == 0)
                    const SizedBox.shrink()
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            duration: 100.ms,
                            curve: Curves.easeOut,
                            tween: Tween<double>(
                              begin: 0,
                              end: clampDouble(_received / _total, 0, 1),
                            ),
                            builder: (context, value, child) => ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: LinearProgressIndicator(
                                value: value,
                                minHeight: 30,
                              ),
                            ),
                          ),
                          Text(
                            '${(_received * 100 / _total).toStringAsPrecision(3)}% (${getSizeString(_received)} / ${getSizeString(_total)})',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
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

String getSizeString(int bytes) {
  if (bytes <= 0) return '0 B';
  final postfix = ['B', 'KB', 'MB'];

  String result = '';

  for (int i = 0; i < postfix.length; i++) {
    num expo = pow(1000, i), nextExpo = pow(1000, i + 1);
    if (bytes >= expo && bytes < nextExpo) {
      result = '${(bytes / expo).toStringAsPrecision(3)} ${postfix[i]}';
      break;
    }
  }
  return result;
}
