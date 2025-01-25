import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../globals/extensions.dart';
import '../globals/music_track.dart';
import '../globals/variables.dart';
import '../globals/widgets.dart';
import '../handlers/log_handler.dart';
import '../handlers/lyric_handler.dart';
import '../player/player_utils.dart';
import '../widgets/action_dialog.dart';
import 'timestamp_editor.dart';
import 'type_lyric.dart';

class LyricEditor extends StatefulWidget {
  final int songID;

  const LyricEditor({super.key, required this.songID});

  @override
  State<LyricEditor> createState() => _LyricEditorState();
}

class _LyricEditorState extends State<LyricEditor> with SingleTickerProviderStateMixin {
  late final AnimationController animController;
  late final MusicTrack song;
  late final Lyric lyric;

  final lineEditController = TextEditingController();
  final List<StreamSubscription> subs = [];
  var timestampList = <Duration>[];
  int lineCount = 0, editingIndex = -1, currentLine = 0;
  Duration currentDuration = Duration.zero;

  bool hasChanged = false, isEditing = false;

  void updateList() {
    timestampList = lyric.list.map((e) => e.timestamp).toList();
    lineCount = lyric.list.length;
  }

  void addLyricItems(List<String> lines) {
    Duration dur = const Duration(minutes: 59, seconds: 59, milliseconds: 900);
    List<(String, Duration)> lyricItems = [];
    for (int i = lines.length - 1; i >= 0; i--) {
      lyricItems.insert(0, (lines[i], dur));
      dur -= 100.milliseconds;
    }
    for (final (line, time) in lyricItems) {
      addNewLyricItem(line, time);
    }
  }

  void addNewLyricItem([String line = '', Duration? time]) {
    lyric.list.add(LyricItem(
      timestamp: time ?? (lyric.list.isNotEmpty ? lyric.list.last.timestamp + 5.seconds : 0.ms),
      line: line.trim(),
    ));
  }

  int findCurrentLine() {
    for (int i = lineCount - 1; i >= 0; i--) {
      if (Globals.audioHandler.player.position.inMilliseconds >= timestampList[i].inMilliseconds) {
        return i;
      }
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    animController = AnimationController(duration: 300.ms, reverseDuration: 300.ms, vsync: this);
    Globals.audioHandler.playing ? animController.forward(from: 0) : animController.reverse(from: 1);
    currentLine = findCurrentLine();

    song = Globals.allSongs.firstWhere((e) => e.id == widget.songID);
    lyric = LyricHandler.getLyric(song.id, Globals.lyricPath + song.lyricPath) ??
        Lyric(
          songId: song.id,
          name: song.name,
          artist: song.artist,
          path: '${song.name}.lrc',
          list: [],
        );
    updateList();

    subs.add(Globals.audioHandler.player.positionStream.listen((current) {
      currentDuration = current;
      final newLine = findCurrentLine();
      if (newLine != currentLine) currentLine = newLine;
      setState(() {});
    }));

    subs.add(Globals.audioHandler.onPlayingChange.listen((playing) {
      if (playing) {
        animController.forward(from: 0);
      } else {
        animController.reverse(from: 1);
      }
    }));

    LogHandler.log('Editing lyric for ${song.id}');
    debugPrint('Lyric info \n$lyric');
    setState(() {});
  }

  @override
  void dispose() {
    lineEditController.dispose();
    animController.dispose();
    for (final sub in subs) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () {
              if (!hasChanged) return Navigator.of(context).pop();

              ActionDialog.static<bool>(
                context,
                title: 'Discard changes',
                titleFontSize: 18,
                textContent: 'Are you sure you want to discard changes?',
                contentFontSize: 14,
                time: 300.ms,
                actions: [
                  TextButton(
                    child: const Text('No'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  TextButton(
                    child: const Text('Yes'),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ).then(
                (value) {
                  if (value != true) return;
                  LogHandler.log('Discarded lyric changes');
                  Navigator.of(context).pop();
                },
              );
            },
          ),
          title: const Text(
            'Lyric Editor',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.save_rounded),
              onPressed: hasChanged
                  ? () {
                      ActionDialog.static<bool>(
                        context,
                        title: 'Save changes',
                        titleFontSize: 18,
                        textContent: 'Are you sure you want to save changes?',
                        contentFontSize: 14,
                        time: 300.ms,
                        actions: [
                          TextButton(
                            child: const Text('No'),
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                          TextButton(
                            child: const Text('Yes'),
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                        ],
                      ).then((value) {
                        if (value != true) return;
                        if (song.lyricPath != lyric.path) {
                          song.lyricPath = lyric.path;
                          song.update();
                        }
                        LyricHandler.addLyric(lyric);
                        Globals.lyricChangedController.add(null);
                        setState(() => hasChanged = false);
                        // Navigator.of(context).pop();
                      });
                    }
                  : null,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.add_rounded, color: iconColor(context)),
                  label: Text('Add', style: TextStyle(color: iconColor(context))),
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.surface),
                    side: WidgetStatePropertyAll(BorderSide(color: Theme.of(context).colorScheme.surface)),
                  ),
                  onPressed: () {
                    addNewLyricItem();
                    updateList();
                    setState(() => hasChanged = true);
                  },
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.edit, color: iconColor(context), size: 20),
                  label: Text('Type', style: TextStyle(color: iconColor(context))),
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.surface),
                    side: WidgetStatePropertyAll(BorderSide(color: Theme.of(context).colorScheme.surface)),
                  ),
                  onPressed: () {
                    Navigator.push<String>(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) {
                          return TypeLyric(
                            lines: Config.appendLyric
                                ? []
                                : lyric.list.map((e) {
                                    String line = e.line;
                                    if (line.isEmpty) line = ' ';
                                    return line;
                                  }).toList(),
                            // : File(Globals.lyricPath + lyric.path).readAsLinesSync(),
                          );
                        },
                        transitionsBuilder: (context, anim1, _, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, -1),
                              end: const Offset(0, 0),
                            ).animate(anim1.drive(CurveTween(curve: Curves.decelerate))),
                            child: child,
                          );
                        },
                      ),
                    ).then((value) {
                      if (value == null) return;
                      final lines = value //
                          .split('\n')
                          .where((e) => e.isNotEmpty)
                          .toList();

                      if (!Config.appendLyric) {
                        final count = min(lines.length, lyric.list.length);
                        final isShorten = count < lyric.list.length;

                        for (int i = 0; i < count; i++) {
                          lyric.list[i] = LyricItem(
                            timestamp: lyric.list[i].timestamp,
                            line: lines[i],
                          );
                        }
                        lines.removeRange(0, count);
                        if (isShorten) {
                          lyric.list.removeRange(count, lyric.list.length);
                        }
                      }
                      addLyricItems(lines);
                      // for (final line in lines) {
                      //   addNewLyricItem(line);
                      // }

                      updateList();
                      setState(() => hasChanged = true);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        body: ListView.builder(
          itemCount: lineCount,
          itemBuilder: (context, index) {
            final item = lyric.list[index];

            if (isEditing && index == editingIndex) {
              return ListTile(
                tileColor: index == currentLine //
                    ? Theme.of(context).colorScheme.inverseSurface.withOpacity(0.1)
                    : null,
                leading: Text(item.timestamp.toLyricTimestamp()),
                title: TextField(
                  controller: lineEditController,
                  maxLines: null,
                  autofocus: true,
                  decoration: textFieldDecoration(
                    context,
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.check_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        isEditing = false;
                        if (!hasChanged) hasChanged = item.line != lineEditController.text;
                        if (hasChanged) {
                          lyric.list[index] = LyricItem(
                            timestamp: item.timestamp,
                            line: lineEditController.text,
                          );
                        }
                        setState(() {});
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.only(left: 10, top: 5, bottom: 5),
                  ),
                ),
              );
            }

            return ListTile(
              tileColor: index == currentLine //
                  ? Theme.of(context).colorScheme.inverseSurface.withOpacity(0.1)
                  : null,
              contentPadding: const EdgeInsets.only(left: 16, right: 0),
              leading: GestureDetector(
                onTap: () {
                  if (isEditing) return;
                  final parts = item.timestamp
                      .toLyricTimestamp() //
                      .split(RegExp(r'[:.]'))
                      .map(int.parse)
                      .toList();
                  final timestamp = (parts[0], parts[1], parts[2] * 10);

                  Navigator.push<List<int>>(
                    context,
                    DialogRoute(
                      context: context,
                      builder: (context) => TimestampEditor(timestamp: timestamp),
                    ),
                  ).then((value) {
                    if (value == null) return;
                    hasChanged = timestamp != (value[0], value[1], value[2]);
                    if (!hasChanged) return;

                    lyric.list[index] = LyricItem(
                      timestamp: Duration(minutes: value[0], seconds: value[1], milliseconds: value[2]),
                      line: item.line,
                    );
                    updateList();
                    setState(() {});
                  });
                },
                child: Text(item.timestamp.toLyricTimestamp()),
              ),
              title: GestureDetector(
                onTap: () {
                  if (isEditing) return;
                  isEditing = true;
                  editingIndex = index;
                  lineEditController.text = item.line;
                  setState(() {});
                },
                child: Text(item.line),
              ),
              trailing: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.clock, size: 20),
                    onPressed: () {
                      lyric.list[index] = LyricItem(
                        timestamp: currentDuration,
                        line: item.line,
                      );
                      updateList();
                      setState(() => hasChanged = true);
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_forever_rounded,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    onPressed: () {
                      ActionDialog.static<bool>(
                        context,
                        title: 'Delete lyric line',
                        titleFontSize: 16,
                        textContent: 'Are you sure you want to delete this lyric line?',
                        contentFontSize: 14,
                        time: 150.ms,
                        actions: [
                          TextButton(
                            child: const Text('No'),
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                          TextButton(
                            child: const Text('Yes'),
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                        ],
                      ).then((value) {
                        if (value != true) return;
                        lyric.list.removeAt(index);
                        updateList();
                        setState(() => hasChanged = true);
                      });
                    },
                  ),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: Visibility(
          visible: Globals.showMinimizedPlayer,
          child: Container(
            margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 5,
                  offset: Offset(0, 5),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      leading: Padding(
                        padding: const EdgeInsets.only(left: 14),
                        child: Icon(
                          Icons.music_note_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        currentDuration.toLyricTimestamp(),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        '${currentDuration.inMilliseconds} ms',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Globals.audioHandler.seek(currentDuration - 5.seconds),
                  icon: Icon(
                    Icons.replay_5_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      value: getCurrentDuration() / getTotalDuration(),
                    ),
                    IconButton(
                      onPressed: () {
                        if (Globals.setDuplicate) {
                          Globals.audioHandler.setPlayerSong(Globals.currentSongID);
                        } else {
                          Globals.audioHandler.playing ? Globals.audioHandler.pause() : Globals.audioHandler.play();
                        }
                        setState(() {});
                      },
                      icon: AnimatedIcon(
                        icon: AnimatedIcons.play_pause,
                        progress: Tween<double>(begin: 0.0, end: 1.0).animate(animController),
                        color: Theme.of(context).colorScheme.primary,
                        size: 30,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Globals.audioHandler.seek(currentDuration + 5.seconds),
                  icon: Icon(
                    Icons.forward_5_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
