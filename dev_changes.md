## Dev 1

- No longer shuffle when turning off
- Added error popup
- Fixed saving playlist twice when using shuffle playback
- Better popup messages paddings
- Improved some log messages
- No longer set audio on launch, after recovering playlist. Added a flag to allow setting song of same ID as a
  workaround
- Added scrolling to popup messages
- No longer autoplay song before setting new song, after recovering playlist
- Added `LyricHandler` class to handle LRC files

## Dev 2

- Changed playlist icon: glass -> list
- Added listener of player's `playingStream`
- Added dev release GitHub Actions
- Show dev build in-app (uses `isDev` flag)

## Dev 3

- Can now play song after recovering playlist without opening the player
- Fixing actions tag creation
- Fixed setting `animController` multiple times
- Fixed song count in log is always 0
- Fixed message dialog doesn't use app's font
- Fixed not passing version when creating database
- Replaced some `showGeneralDialog` calls with `dialogWithActions` calls
- Fixed setting the correct current song after recovering playlist

## Dev 4

- Fixed alert dialog action text inconsistencies
- Fixed re-assigning `playlistScrollController`
- Moved APKs building to after version processing
- Extracted all extensions to separate file
- Updated README
- Re-aligned dialog actions
- Improved log dialog text (uses `RichText`), separate each entry with an empty line.
  Separated time and message into different lines. Error messages are red.
- `dialogWithActions` accepts either `String` or `RichText`, throws if both are null
- Added error icon to error messages

## Dev 5

- Fixed playlist sheet not scrolling to current song
- Fixed skipping to previous song doesn't update saved playlist correctly
- Fixed checking for internet connection
- Improved app version info in-app. Uses environment & pubspec version. Removed `package_info_plus` dependency
- Extracted main screen's drawer to separate file
- Improved setting page
- Added page for theme setting
- Fixed wrong/outdated SoundCloud client ID -> re-enabled SoundCloud downloader
- Fixed trying to parse special log message lines (from exceptions)
- Moved version string, licenses and GitHub link to `Settings` page
- Added checking for app update feature

## Dev 6

- Updated Flutter to 3.22.0, Dart to 3.4.0 (was for `file_picker` but has changed and too lazy to revert)
- Fixed dev version checking not considering latest release is not pre-release
- Will show rate limited error if response is null
- Uses authenticated requests for GitHub API
- No longer delay between songs if skipped manually
- Songs in album can now be reordered
- Playlist sheet is now a `StatefulWidget`, opened with `CupertinoModalPopupRoute`
- Fixed playlist sheet not updating properly when song is changed
- Logs wrong type of version check response
- Logs finished loading app
- Updated song list shuffle icon
- Improved visual of player, playlist sheet
- Added page indicator for use with `TabBarView`
- Moved backup to `Settings` page
- Added LRC file selection
- Improved `LyricHandler` parser
- Shows lyric for song if available, can scroll or auto scroll, current line is highlighted and centered
- Lyric timestamp is now `Duration`
- Fixed auto scrolling is not animated
- Allow detaching lyric from song
- Added outline to popup dialog & bottom sheet
