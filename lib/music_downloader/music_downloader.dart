import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:music_player_app/music_downloader/soundcloud_downloader.dart';
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

  bool _isFromSoundCloud = false;
  bool _isGettingVideo = false, _isInternetConnected = true, _gotVideoData = false, _isDownloading = false;
  int _received = 0, _total = 0;

  String? _errorText;

  late String _videoTitle;
  late String _channelName;
  late String _url;
  late String? _thumbnailUrl;
  late Duration _videoDuration;

  void _checkInternetConnection([ConnectivityResult? result]) async {
    final connectivityResult = result ?? await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.ethernet ||
        connectivityResult == ConnectivityResult.vpn) {
      _isInternetConnected = true;
    } else if (connectivityResult == ConnectivityResult.none) {
      _isInternetConnected = false;
    }
    setState(() {});
  }

  void _validateInput(String text) {
    _errorText = null;
    if (text.isEmpty) {
      _errorText = null;
    } else if (!RegExp(
                r'^(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})(?:\S+)?$')
            .hasMatch(text) &&
        !RegExp(r'^(?:https?:\/\/)?(?:www\.)?(?:soundcloud\.com)\/([a-zA-Z0-9_-]*)\/([a-zA-Z0-9_-])(?:\S+)?$')
            .hasMatch(text)) {
      _errorText = 'Invalid URL';
    }
    setState(() {});
  }

  Future<void> _getVideoData() async {
    setState(() {
      _isGettingVideo = true;
      _total = 0;
    });

    if (_textEditingController.text.contains('soundcloud')) {
      _isFromSoundCloud = true;
      final scSongData = await getSongData(_textEditingController.text);
      _url = scSongData['trackUrl'];
      _thumbnailUrl = scSongData['artworkUrl'];
      _videoTitle = scSongData['songTitle'];
      _channelName = scSongData['authorUsername'];
      _videoDuration = scSongData['duration'];
    } else {
      _url = _textEditingController.text;

      Video video = await _yt.videos.get(_url);

      _videoTitle = video.title;
      _thumbnailUrl = video.thumbnails.lowResUrl;
      _videoDuration = video.duration!;
      _channelName = video.author;
    }

    setState(() {
      _gotVideoData = true;
      _isGettingVideo = false;
    });
  }

  Future<void> _downloadYoutubeMP3() async {
    if (_isFromSoundCloud) {
      await _downloadSoundCloudMP3();
      return;
    }

    final file = File('/storage/emulated/0/Download/$_videoTitle.mp3');

    if (file.existsSync() && file.lengthSync() > 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File with the same name already exists')),
        );
      }
      return;
    }

    try {
      final manifest = await _yt.videos.streamsClient.getManifest(_url);
      final streamInfo = manifest.audioOnly.withHighestBitrate();
      _total = streamInfo.size.totalBytes;

      // Get the actual stream
      var stream = _yt.videos.streamsClient.get(streamInfo);

      debugPrint('Saving to: ${file.absolute}');
      var fileStream = file.openWrite();

      setState(() {
        _received = 0;
        _isDownloading = true;
      });

      await stream.map((s) {
        _received += s.length;
        setState(() {});
        return s;
      }).pipe(fileStream);

      await fileStream.flush();
      await fileStream.close();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Finished downloading')),
        );
      }
      setState(() {
        _isDownloading = false;
      });
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _downloadSoundCloudMP3() async {
    final dio = Dio();
    final file = File('/storage/emulated/0/Download/$_videoTitle.mp3');

    if (file.existsSync() && file.lengthSync() > 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File with the same name already exists')),
        );
      }
      return;
    }

    setState(() {
      _received = 0;
      _isDownloading = true;
    });

    debugPrint('Saving to: ${file.absolute.path}');
    await dio.download(
      _url,
      file.absolute.path,
      onReceiveProgress: (count, total) {
        setState(() {
          _received = count;
          _total = total;
        });
      },
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finished downloading')),
      );
    }
    setState(() => _isDownloading = false);
  }

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
    Connectivity().onConnectivityChanged.listen((newResult) {
      _checkInternetConnection(newResult);
    });
    _textEditingController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    _yt.close();
    _textEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            if (_isDownloading) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('App is downloading music, please wait')),
              );
            }
            Navigator.of(context).pop();
          },
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
                        Text(
                          'Enter YouTube or SoundCloud link into the text field.',
                          textAlign: TextAlign.center,
                        ),
                        Text('Wait for the app to fetch the data.'),
                        Text('Press the download button.'),
                        Text(
                          'Wait for the app to download the music.',
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
                // link input
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: AppBar().preferredSize.height * 1.3,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              enabled: _isInternetConnected || _isDownloading,
                              controller: _textEditingController,
                              onChanged: _validateInput,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText: 'Enter YouTube or SoundCloud link',
                                labelText: 'Music Link',
                                errorText: _errorText,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
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
                        onPressed:
                            _textEditingController.text.isNotEmpty && !_isDownloading && _errorText == null
                                ? () async {
                                    FocusManager.instance.primaryFocus?.unfocus();
                                    await _getVideoData();
                                  }
                                : null,
                        style: ButtonStyle(
                          shape: MaterialStatePropertyAll<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                        child: const Text('Get Music'),
                      ),
                    ),
                  ],
                ),
                // video info
                if (!_gotVideoData)
                  const SizedBox.shrink()
                else
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _thumbnailUrl == null
                                ? Container(
                                    margin: EdgeInsets.zero,
                                    decoration: BoxDecoration(border: Border.all()),
                                    child: const Icon(Icons.music_note_rounded),
                                  )
                                : Image.network(_thumbnailUrl!, fit: BoxFit.fitHeight),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Text(
                                      _videoTitle,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(_channelName),
                                    Text(
                                      _videoDuration.toMMSS(),
                                      style: const TextStyle(color: Colors.grey),
                                    )
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _isDownloading ? null : () async => await _downloadYoutubeMP3(),
                        style: ButtonStyle(
                          shape: MaterialStatePropertyAll<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                        child: const Text('Download Music'),
                      ),
                    ],
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: LinearProgressIndicator(
                            value: clampDouble(_received / _total, 0, 1),
                            minHeight: 30,
                            semanticsLabel: '${getSizeString(_received)} / ${getSizeString(_total)}',
                          ),
                        ),
                        Text(
                          '${(_received * 100 / _total).toStringAsPrecision(3)}% (${getSizeString(_received)} / ${getSizeString(_total)})',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
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
