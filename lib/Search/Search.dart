import 'package:flutter/material.dart';

class Song {
  final String title;
  final String artist;

  Song(this.title, this.artist);
}

class SearchPage extends StatefulWidget {
  @override
  _SearchPage createState() => _SearchPage();
}

class _SearchPage extends State<SearchPage> {
  List<Song> allSongs = [
    Song('Song 1', 'Artist 1'),
    Song('Song 2', 'Artist 2'),
    Song('Song 3', 'Artist 3'),
    // Thêm các bài hát khác vào đây
  ];

  List<Song> filteredSongs = [];

  @override
  void initState() {
    super.initState();
    filteredSongs = allSongs;
  }

  void searchSongs(String keyword) {
    setState(() {
      filteredSongs = allSongs
          .where((song) => song.title.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Song List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => searchSongs(value),
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredSongs.length,
              itemBuilder: (context, index) {
                final song = filteredSongs[index];
                return ListTile(
                  title: Text(song.title),
                  subtitle: Text(song.artist),
                  // Xử lý khi người dùng nhấp vào một bài hát
                  onTap: () {
                    // Thực hiện hành động khi người dùng nhấp vào bài hát
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}