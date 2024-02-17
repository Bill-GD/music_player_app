import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:music_player_app/globals/widgets.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../globals/functions.dart';

class MusicDownloader extends StatefulWidget {
  const MusicDownloader({super.key});

  @override
  State<MusicDownloader> createState() => _MusicDownloaderState();
}

class _MusicDownloaderState extends State<MusicDownloader> {
  final _yt = YoutubeExplode();
  late final TextEditingController _textEditingController;

  bool _isGettingVideo = false;
  int _received = 0, _total = 0;

  Video? _video;
  late String _channelName;
  late String _url;

  void getVideoData() async {
    if (_textEditingController.text.isNotEmpty) {
      setState(() {
        _isGettingVideo = true;
      });
      _url = _textEditingController.text;

      debugPrint('Getting video from url: $_url');

      _video = await _yt.videos.get(_url);
      _channelName = (await _yt.channels.get(_video!.channelId)).title;

      setState(() {
        _isGettingVideo = false;
      });
    }
  }

  void downloadYoutubeMP3() async {
    if (_video != null) {
      setState(() {
        _received = 0;
      });

      try {
        final manifest = await _yt.videos.streamsClient.getManifest(_url);
        final streamInfo = manifest.audioOnly.withHighestBitrate();
        _total = streamInfo.size.totalBytes;

        // Get the actual stream
        var stream = _yt.videos.streamsClient.get(streamInfo);

        // Open a file for writing.
        var file = File('/storage/emulated/0/Download/${_video!.title}.mp3');

        if (await file.exists()) {
          debugPrint('File with the same name already exists');
          _isGettingVideo = false;
          _total = 0;
          setState(() {});
          return;
        }
        debugPrint('Saving to: ${file.absolute}');
        var fileStream = file.openWrite();

        _isGettingVideo = false;
        setState(() {});

        // Pipe all the content of the stream into the file.
        await stream.map((s) {
          _received += s.length;
          setState(() {});
          return s;
        }).pipe(fileStream);

        await fileStream.flush();
        await fileStream.close();

        _yt.close();
        debugPrint('Finished downloading');
      } on Exception catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    _textEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text('YouTube Downloader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    title: const Text(
                      'Instruction',
                      textAlign: TextAlign.center,
                    ),
                    alignment: Alignment.center,
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Enter the video link into the text field.'),
                        Text('Wait for the app to fetch the video.'),
                        Text('Press the download button.'),
                        Text(
                          'Wait for the app to download the audio.',
                          textAlign: TextAlign.center,
                        ),
                      ],
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
      body: Container(
        margin: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: AppBar().preferredSize.height * 0.65,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _textEditingController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Enter YouTube link',
                        prefixIcon: const Icon(Icons.search_rounded),
                        contentPadding: const EdgeInsets.only(right: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: _isGettingVideo,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ElevatedButton(
                onPressed: () {
                  getVideoData();
                },
                style: ButtonStyle(
                  shape: MaterialStatePropertyAll<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                child: const Text('Get Video'),
              ),
            ),
            Visibility(
              visible: _video != null,
              child: _video != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Image.network(_video!.thumbnails.lowResUrl, fit: BoxFit.fitHeight),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text(_video!.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    )),
                                Text(_channelName),
                                Text(
                                  _video!.duration!.toMMSS(),
                                  style: const TextStyle(color: Colors.grey),
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            Visibility(
              visible: _video != null,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ButtonStyle(
                    shape: MaterialStatePropertyAll<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  child: const Text('Download Music'),
                ),
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
