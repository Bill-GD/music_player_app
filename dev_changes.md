- Reworked backup feature: has multiple backups (number is configurable), can restore from any backup.
- Added `BackupHandler` to interact with the backup files.
- Reorganized file & code structure.
  Exclusively used functions/widgets is included with its users.
- Changed `dialogWithActions` to `ActionDialog` class with stateless and stateful version.
- Can now save config in setting screen without closing the screen. 
- Setting screen only allow saving config if the values are actually changed.
- Swapped color of active & inactive in breadcrumb.
- Fixed mini player tries to display song with unknown ID.