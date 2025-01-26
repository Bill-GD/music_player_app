- Fixed not reducing second (by extension minute) when milli is not divisible by 100.
- Added warning log message.
- Added `image_path` to `album` and `music_track` table.
  Same for `Album` and `MusicTrack` classes.
- Extracted song options to their own class. Use with `showSongOptionsMenu`.
- Added cover image feature for songs.
  The player uses cover image and has a blurred version as background.
  Change cover image in song info screen.
- Changed empty directory icon in `FilePicker`.