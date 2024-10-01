import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../globals/functions.dart';
import '../globals/widgets.dart';

Future<Map<String, dynamic>?> getSoundCloudSongData(BuildContext context, String urlText) async {
  if (!urlText.contains('https://')) {
    urlText = 'https://$urlText';
  }
  const String clientId = 'client_id=8BBZpqUP1KSN4W6YB64xog2PX4Dw98b1';

  String url = urlText.split('?').first;
  String author = url.split('/').elementAt(3);

  Map? trackData;

  debugPrint('Searching for author: $author');
  http.Response responseAuthor = await http.get(
    Uri.parse('https://api-v2.soundcloud.com/search/users?q=$author&$clientId'),
  );

  Map<String, dynamic> jsonDataAuthor = jsonDecode(responseAuthor.body);
  var resultAuthor = (jsonDataAuthor['collection'] as List).where(
    (element) => element['permalink'] == author,
  );

  // can't find author
  if (resultAuthor.isEmpty) {
    debugPrint('Couldn\'t find author: $author');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn\'t find author: $author')),
      );
    }
    return null;
  }

  String authorId = '${resultAuthor.first['id']}';
  String authorUsername = '${resultAuthor.first['username']}';
  String trackCount = '${resultAuthor.first['track_count'] * 2}';

  debugPrint('Author: $authorUsername (id:$authorId) has $trackCount songs');

  debugPrint('Searching for track: ${url.split('/').elementAt(4)}');
  http.Response responseTracks = await http.get(
    Uri.parse('https://api-v2.soundcloud.com/users/$authorId/tracks?$clientId&limit=$trackCount'),
  );

  Map<String, dynamic> jsonDataTracks = jsonDecode(responseTracks.body);
  var resultTracks = (jsonDataTracks['collection'] as List).where(
    (element) => element['permalink'] == url.split('/').elementAt(4),
  );
  trackData = resultTracks.isNotEmpty ? resultTracks.first : null;

  // can't find song
  if (trackData == null) {
    debugPrint('Couldn\'t find song: ${url.split('/').elementAt(4)}');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn\'t find song: ${url.split('/').elementAt(4)}')),
      );
    }
    return null;
  }

  String songTitle = trackData['title'];
  String trackStreamUrl = trackData['media']['transcodings'][1]['url'];
  Duration duration = Duration(milliseconds: trackData['media']['transcodings'][1]['duration']);
  String? artworkUrl = trackData['artwork_url'];

  debugPrint('Found track stream url: $trackStreamUrl');
  debugPrint('Getting song media url');
  http.Response responseTrack = await http.get(Uri.parse('$trackStreamUrl?$clientId'));

  String trackUrl = jsonDecode(responseTrack.body)['url'];

  // debugPrint(trackUrl);
  // debugPrint(songTitle);

  return {
    'trackUrl': trackUrl,
    'thumbnailUrl': artworkUrl,
    'title': songTitle,
    'author': authorUsername,
    'duration': duration,
  };
}

Future<void> downloadSoundCloudMP3(
  BuildContext context,
  String url,
  String videoTitle,
  void Function(int, int) onReceiveProgress,
) async {
  final dio = Dio();
  final file = File('/storage/emulated/0/Download/${sanitizeFilePath(videoTitle)}.mp3');

  if (file.existsSync() && file.lengthSync() > 0) {
    debugPrint('File with the same name already exists');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File with the same name already exists')),
      );
    }
    return;
  }
  try {
    debugPrint('Saving to: ${file.absolute.path}');
    await dio.download(
      url,
      file.absolute.path,
      onReceiveProgress: onReceiveProgress,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finished downloading')),
      );
    }
  } on Exception catch (e) {
    debugPrint(e.toString());
    if (context.mounted) {
      showErrorPopup(context, e.toString());
    }
  }
}
