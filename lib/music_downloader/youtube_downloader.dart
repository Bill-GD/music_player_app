import 'dart:io';

import 'package:flutter/material.dart';

import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../globals/functions.dart';
import '../globals/log_handler.dart';
import '../globals/widgets.dart';

Future<Map<String, dynamic>?> getYouTubeVideoData(BuildContext context, String urlText) async {
  try {
    final yt = YoutubeExplode();

    Video video;
    StreamManifest manifest;
    AudioOnlyStreamInfo streamInfo;
    int totalSize;

    video = await yt.videos.get(urlText);
    manifest = await yt.videos.streamsClient.getManifest(urlText);
    streamInfo = manifest.audioOnly.withHighestBitrate();
    totalSize = streamInfo.size.totalBytes;

    return {
      'totalSize': totalSize,
      'thumbnailUrl': video.thumbnails.lowResUrl,
      'title': video.title,
      'author': video.author,
      'duration': video.duration ?? 0.ms,
    };
  } on Exception catch (e) {
    if (context.mounted) {
      switch (e.runtimeType) {
        case VideoUnavailableException:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video not available')),
          );
          break;
        default:
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(content: Text('Got an error while getting video')),
          // );
          showErrorPopup(context, e.toString());
          break;
      }
    }
    return null;
  }
}

Future<void> downloadYoutubeMP3(
    BuildContext context, String url, String videoTitle, void Function(int, int) onReceiveProgress) async {
  final yt = YoutubeExplode();
  final dio = Dio();
  final file = File('/storage/emulated/0/Download/${sanitizeFilePath(videoTitle)}.mp3');

  if (file.existsSync() && file.lengthSync() > 0) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File with the same name already exists')),
      );
    }
    return;
  }
  try {
    final manifest = await yt.videos.streamsClient.getManifest(url);
    final streamInfo = manifest.audioOnly.withHighestBitrate();

    LogHandler.log('Saving to: ${file.absolute.path}');

    await dio.download(
      streamInfo.url.toString(),
      file.absolute.path,
      onReceiveProgress: onReceiveProgress,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finished downloading')),
      );
    }
  } on Exception catch (e) {
    LogHandler.log(e.toString());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An Error occurred while downloading')),
      );
    }
  }
}
