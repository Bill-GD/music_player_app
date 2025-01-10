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