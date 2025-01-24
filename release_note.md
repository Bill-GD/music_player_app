## Features

- Added new sorting option: song ID.
- Added new widget error screen.
- Added confirmation before backing up data.
- Added a version list to the `About` page (includes dev builds).
  Can view the changelog (dev changes as well if available) of each version.
  For the dev build, only dev changes is available.
  Each version has a button to go to its release page.
- Added a popup when there's a new version available.

## Changes

- Date displays are now local time.
- Updated visual of message notification.
- No longer update song list automatically after downloading a song.
- Newly added lyric lines (from editor) will be added to the end of the song.
- Lyric editor highlights the whole line.
- If rewrite the lyrics with the editor. the timestamp will be kept.
- Improved the file picker UI when selecting a lyric file.
- Improved the description of `Append lyric` option.
- Improved the changelog's formatting.
- Improved the lyric scroller visual.
- Specifies 'No lyric' if the song has no lyric file attached.
- Updated internal code to newer version.

## Fixes

- Fixed not handling leftover songs correctly.
- Fixed can't delete songs (wrong file path).
- Fixed some YouTube URLs is considered invalid.
- Fixed music downloader not showing download progress bar.
- Fixed not able to save if cancelled changing individual lyric line.
- Fixed not able to increase minute or seconds when milliseconds is not divisible by 10.
- Abort checking for new version if internet is not connected.