## Features

- Added lyric viewer to the right of the player image.
  Current line is highlighted, others are dimmed.
  Auto scroll when playing the timestamp is reached.
  Can be scrolled freely and will auto scroll after a short delay.
- Added feature that allow adding lyric to song: select file & edit
- Added feature that allow reordering album songs
- Added popup message when there's an app error
- Added app version checking feature
- Added scroll bar to playlist sheet

## Changes

- Improved visual of a lot of things
- Can now play song after recovering playlist without opening the player
- No longer autoplay song after loading saved playlist and opening the player
- No longer shuffle when turning shuffle off
- Changed playlist icon: glass -> list
- More detailed app version info in-app
- Moved backup, app version display (& related interactions) into `Settings`

## Fixes

- Fixed SoundCloud downloader. It's now re-enabled
- Fixed error that only load the first song of saved playlist regardless of what was last played
- Fixed error that causes saved playlist songs to be duplicated
- Fixed not updating the play/pause button when media player is paused
- Fixed not updating the playlist when skipping to previous song
- Fixed internet connection checking
- Fixed playlist sheet not updating properly when song is changed
- and more minor fixes