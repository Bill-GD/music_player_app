import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../globals/extensions.dart';
import '../globals/functions.dart' as g;
import '../globals/functions.dart';
import '../globals/widgets.dart';
import 'soundcloud_downloader.dart';
import 'youtube_downloader.dart';

class MusicDownloader extends StatefulWidget {
  const MusicDownloader({super.key});

  @override
  State<MusicDownloader> createState() => MusicDownloaderState();
}

class MusicDownloaderState extends State<MusicDownloader> {
  final ytExplode = YoutubeExplode();
  late final TextEditingController textEditingController;

  Map<String, dynamic>? metadata;

  bool isFromSoundCloud = false;
  bool isGettingData = false, isInternetConnected = false, isDownloading = false, hasDownloaded = false;
  int received = 0, total = 0;

  String? errorText;

  late StreamSubscription<List<ConnectivityResult>> connectStream;

  void validateInput(String text) {
    errorText = null;
    if (text.isEmpty) {
      errorText = null;
    } else if (RegExp(r'^(?:https://)?on\.soundcloud\.com(?:\S+)?$').hasMatch(text)) {
      errorText = 'Please use full URL, SoundCloud API is weird';
    } else if (!RegExp(r'^(?:https?://)?(?:www\.)?(?:youtube\.com/watch\?v=|youtu\.be/)([a-zA-Z0-9-]{11})(?:\S+)?$')
            .hasMatch(text) &&
        !RegExp(r'^(?:https://)?(m\.)?soundcloud\.com/([a-zA-Z0-9-]*)/([a-zA-Z0-9-])(?:\S+)?$').hasMatch(text)) {
      errorText = 'Invalid URL';
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // checkInternetConnection().then((val) => isInternetConnected = val);
    connectStream = Connectivity().onConnectivityChanged.listen((newResults) {
      checkInternetConnection(newResults).then((val) {
        isInternetConnected = val;
        setState(() {});
      });
    });
    textEditingController = TextEditingController();
  }

  @override
  void dispose() {
    connectStream.cancel();
    ytExplode.close();
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () {
              if (isDownloading) {
                return g.showToast(context, 'App is downloading music, please wait');
              }
              Navigator.of(context).pop(hasDownloaded);
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
                showPopupMessage(
                  context,
                  title: 'Instruction',
                  content: g.dedent('''
                        Enter YouTube or SoundCloud link into the text field.
                        Press the get data button.
                        Wait for the app to fetch the data.
                        Press the download button.
                        Wait for the app to download the music.
                        '''),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // no connectivity
            Visibility(
              visible: !isInternetConnected,
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
                        enabled: isInternetConnected || isDownloading,
                        controller: textEditingController,
                        onChanged: validateInput,
                        decoration: textFieldDecoration(
                          context,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          fillColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
                          hintText: 'Enter YouTube or SoundCloud link',
                          labelText: 'Music Link',
                          errorText: errorText,
                          suffixIcon: isGettingData
                              ? Container(
                                  width: 20,
                                  height: 20,
                                  margin: const EdgeInsets.only(right: 20),
                                  child: Center(
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 3,
                                    ).animate(
                                      effects: const [FadeEffect()],
                                      onComplete: (_) {},
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
                          onPressed: textEditingController.text.isNotEmpty &&
                                  !isDownloading &&
                                  errorText == null &&
                                  isInternetConnected
                              ? () async {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  isFromSoundCloud = textEditingController.text.contains('soundcloud.com');
                                  setState(() {
                                    isGettingData = true;
                                    metadata = null;
                                  });
                                  if (isFromSoundCloud) {
                                    metadata = await getSoundCloudSongData(context, textEditingController.text);
                                    // errorText = 'SoundCloud API is currently disabled/inaccessible';
                                  } else {
                                    metadata = await getYouTubeVideoData(context, textEditingController.text);
                                  }
                                  setState(() => isGettingData = false);
                                }
                              : null,
                          style: textButtonStyle(context),
                          child: const Text('Get Music Data'),
                        ),
                      ),
                    ],
                  ),
                  if (metadata == null)
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
                                  margin: isFromSoundCloud
                                      ? const EdgeInsets.only(left: 60, right: 30)
                                      : const EdgeInsets.only(left: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: metadata!['thumbnailUrl'] == null
                                      ? BoxDecoration(
                                          border: Border.all(
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                        )
                                      : null,
                                  child: metadata!['thumbnailUrl'] == null
                                      ? Icon(
                                          Icons.music_note_rounded,
                                          color: Theme.of(context).colorScheme.primary,
                                        )
                                      : Image.network(metadata!['thumbnailUrl'], fit: BoxFit.fitHeight),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        Text(
                                          metadata!['title'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(metadata!['author']),
                                        Text(
                                          (metadata!['duration'] as Duration).toStringNoMilliseconds(),
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
                            onPressed: isDownloading
                                ? null
                                : () async {
                                    setState(() {
                                      isDownloading = true;
                                      hasDownloaded = true;
                                    });
                                    isFromSoundCloud
                                        ? await downloadSoundCloudMP3(
                                            context,
                                            metadata!['trackUrl'],
                                            metadata!['title'],
                                            (received, total) {
                                              setState(() {
                                                received = received;
                                                total = total;
                                              });
                                            },
                                          )
                                        : await downloadYoutubeMP3(
                                            context,
                                            textEditingController.text,
                                            metadata!['title'],
                                            (received, total) {
                                              setState(() {
                                                received = received;
                                                total = total;
                                              });
                                            },
                                          );
                                    setState(() => isDownloading = false);
                                  },
                            style: textButtonStyle(context),
                            child: const Text('Download Music'),
                          ),
                        ],
                      ),
                    ),
                  // download progress
                  if (total == 0)
                    const SizedBox.shrink()
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            duration: NumDurationExtensions(100).ms,
                            curve: Curves.easeOut,
                            tween: Tween<double>(
                              begin: 0,
                              end: clampDouble(received / total, 0, 1),
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
                            '${(received * 100 / total).toStringAsPrecision(3)}% (${getSizeString(received)} / ${getSizeString(total)})',
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
