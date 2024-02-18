import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';

Future<Map<String, dynamic>> getSongData(String urlText) async {
  const String clientId = 'client_id=8BBZpqUP1KSN4W6YB64xog2PX4Dw98b1';

  String url = urlText.split('?').first;
  String author = url.split('/').elementAt(3);

  Map? trackData;

  debugPrint('Searching for $author');
  Response responseAuthor = await get(
    Uri.parse('https://api-v2.soundcloud.com/search/users?q=$author&$clientId'),
  );

  Map<String, dynamic> jsonDataAuthor = jsonDecode(responseAuthor.body);
  var resultAuthor = (jsonDataAuthor['collection'] as List).where(
    (element) => element['permalink'] == author,
  );

  String? authorId = resultAuthor.isNotEmpty ? '${resultAuthor.first['id']}' : null;
  String? authorUsername = resultAuthor.isNotEmpty ? '${resultAuthor.first['username']}' : null;
  String? trackCount = resultAuthor.isNotEmpty ? '${resultAuthor.first['track_count'] * 2}' : null;

  debugPrint('Searching for track ${url.split('/').elementAt(4)}');
  Response responseTracks = await get(
    Uri.parse('https://api-v2.soundcloud.com/users/$authorId/tracks?$clientId&limit=$trackCount'),
  );

  Map<String, dynamic> jsonDataTracks = jsonDecode(responseTracks.body);
  var resultTracks = (jsonDataTracks['collection'] as List).where(
    (element) => element['permalink_url'] == url,
  );
  trackData = resultTracks.isNotEmpty ? resultTracks.first : null;

  String songTitle = trackData?['title'];
  String trackStreamUrl = trackData?['media']['transcodings'][1]['url'];
  Duration duration = Duration(milliseconds: trackData?['media']['transcodings'][1]['duration']);
  String? artworkUrl = trackData?['artwork_url'];

  debugPrint('Getting song media url');
  Response responseTrack = await get(Uri.parse('$trackStreamUrl?$clientId'));

  String trackUrl = jsonDecode(responseTrack.body)['url'];

  debugPrint(trackUrl);
  debugPrint(songTitle);

  return {
    'trackUrl': trackUrl,
    'artworkUrl': artworkUrl,
    'songTitle': songTitle,
    'authorUsername': authorUsername,
    'duration': duration,
  };
}
