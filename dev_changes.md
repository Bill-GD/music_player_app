- Fixed not reducing second (by extension minute) when milli is not divisible by 100.
- Added warning log message.
- Added `image_path` to `album` and `music_track` table.
  Same for `Album` and `MusicTrack` classes.
- Extracted song options to their own class. Use with `showSongOptionsMenu`.