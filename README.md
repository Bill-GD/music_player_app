<img src="assets/images/icon.png" alt="logo" width="150">

# **Music Hub**

![GitHub Release](https://img.shields.io/github/v/release/Bill-GD/music_player_app?include_prereleases&style=plastic)
![GitHub repo size](https://img.shields.io/github/repo-size/Bill-GD/music_player_app?style=plastic)
![GitHub repo size](https://img.shields.io/github/languages/code-size/Bill-GD/music_player_app?style=plastic)

### What is this and why was this made?

A simple, lightweight music player made for Android using Flutter.\
There are 3 main reasons I built this:

- The built-in music app that I was using is somewhat bloated (account, ads, online search...).
- That app doesn't have some features that I personally want.
- I want to try to build one and learn the basics of Flutter in the process.

### How to use?

You can go to the [release](https://github.com/Bill-GD/music_player_app/releases/latest) section and download the APK
file
that is suitable for your Android device.
If you aren't sure, download the main APK file instead (should be similar to `music_hub_1_4_8.apk
`).
After downloading, install it and you can start using it.

This player only handle `.mp3` files in the `Download` folder.
If you have any song in there, it will automatically show up.

### Main features

- Song management
    - List mp3 files from Download, ignore those under 30s (configurable)
    - Download music from YouTube and SoundCloud using URL (has some limitations)
    - Change song info, cover image, lyrics or delete song
- Player
    - Play songs with simple controls (seek, play/pause, shuffle, repeat, minimize)
    - Playlist (created from selected song list) with modifiable song order
- Organization
    - Add songs into artists and albums
    - Manage songs in albums
    - Sort songs by: name, most played, add time
- and more...