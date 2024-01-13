import 'dart:convert';

class MusicTrack {
  String absolutePath;
  String? trackName, artist;
  bool? isFavorite;
  int? timeListened;

  MusicTrack(
    this.absolutePath, {
    this.trackName,
    this.artist = 'Unknown',
    this.isFavorite = false,
    this.timeListened = 0,
  }) {
    trackName ??= absolutePath.split(RegExp('/')).last.split('.').first;
  }

  MusicTrack.fromJson(Map json)
      : absolutePath = json['absolutePath'],
        trackName = json['trackName'] ?? json['absolutePath'].split(RegExp('/')).last.split('.').first,
        artist = json['artist'] ?? 'Unknown',
        isFavorite = json['isFavorite'],
        timeListened = json['timeListened'];

  MusicTrack.fromJsonString(String jsonString) : this.fromJson(json.decode(jsonString));

  Map<String, dynamic> toJson() => {
        'absolutePath': absolutePath,
        'trackName': trackName,
        'artist': artist,
        'isFavorite': isFavorite,
        'timeListened': timeListened
      };

  bool compareTrackPath(MusicTrack other) => absolutePath == other.absolutePath;
  bool comparePath(String otherPath) => absolutePath == otherPath;
}
