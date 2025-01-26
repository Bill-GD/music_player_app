import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../globals/utils.dart';
import '../handlers/log_handler.dart';

class FilePicker extends StatefulWidget {
  final Directory rootDirectory;

  /// LIst of allowed file extensions, example: ['mp3', 'lrc']
  final List<String> allowedExtensions;

  const FilePicker({super.key, required this.rootDirectory, required this.allowedExtensions});

  @override
  State<FilePicker> createState() => _FilePickerState();

  static Future<String?> open({
    required BuildContext context,
    required Directory rootDirectory,
    List<String> allowedExtensions = const [],
  }) async {
    return await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, _, __) => FilePicker(
          rootDirectory: rootDirectory,
          allowedExtensions: allowedExtensions,
        ),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, anim, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: const Offset(0, 0),
            ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(anim),
            child: child,
          );
        },
      ),
    );
  }

  static Future<void> _show({
    required BuildContext context,
    required Directory rootDirectory,
  }) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, _, __) => FilePicker(
          rootDirectory: rootDirectory,
          allowedExtensions: const [],
        ),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, anim, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: const Offset(0, 0),
            ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(anim),
            child: child,
          );
        },
      ),
    );
  }
}

class _FilePickerState extends State<FilePicker> {
  var fileEntities = <String>[], isDirectory = <bool>[], crumbs = <String>[];
  String currentRootPath = '';

  @override
  void initState() {
    super.initState();
    LogHandler.log('File picker: ${widget.rootDirectory}');
    getEntities(widget.rootDirectory);
    getCrumbs();
  }

  void getCrumbs() {
    final parts = [
      widget.rootDirectory.absolute.path,
      ...currentRootPath //
          .split(widget.rootDirectory.absolute.path)
          .last
          .split('/')
          .where((e) => e.isNotEmpty)
    ];
    LogHandler.log('Parts: $parts');

    crumbs.clear();
    for (final c in parts) {
      crumbs.add(c);
      crumbs.add(' > ');
    }
    crumbs.removeLast();
  }

  void getEntities(Directory root) {
    List<FileSystemEntity> entities;
    try {
      entities = root.listSync();
    } catch (e) {
      if (e is PathAccessException) {
        return showToast(context, 'Permission denied');
      }
      rethrow;
    }

    if (widget.allowedExtensions.isNotEmpty) {
      entities = entities //
          .where((e) => e is Directory || (e is File && widget.allowedExtensions.contains(e.path.split('.').last)))
          .toList();
    }

    fileEntities.clear();
    isDirectory.clear();

    currentRootPath = root.absolute.path;
    if (!currentRootPath.endsWith('/')) currentRootPath += '/';

    LogHandler.log('Getting file entities from $currentRootPath');

    for (final entity in entities) {
      fileEntities.add(entity.path.split(currentRootPath).last.split('/').last);
      isDirectory.add(entity is Directory);
    }
  }

  String getCrumbPath(int index) {
    return '${widget.rootDirectory.absolute.path}/'
        '${crumbs.sublist(1, index + 1).where((e) => !e.contains('>')).join('/')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('Storage'),
        leading: CloseButton(
          onPressed: Navigator.of(context).pop,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: RichText(
              textAlign: TextAlign.start,
              text: TextSpan(children: [
                for (var i = 0; i < crumbs.length; i++)
                  TextSpan(
                    text: crumbs[i],
                    style: i % 2 == 0 && i < crumbs.length - 1
                        ? TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            decorationThickness: 2,
                          )
                        : TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                    recognizer: i % 2 == 0 && i < crumbs.length - 1
                        ? (TapGestureRecognizer()
                          ..onTap = () {
                            getEntities(i == 0 ? widget.rootDirectory : Directory(getCrumbPath(i)));
                            getCrumbs();
                            setState(() {});
                          })
                        : null,
                  ),
              ]),
            ),
          ),
          Flexible(
            child: fileEntities.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_rounded, size: 70),
                        Text('Empty', style: TextStyle(fontSize: 24)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: fileEntities.length,
                    itemBuilder: (context, index) {
                      final entity = fileEntities[index];

                      return ListTile(
                        leading: Icon(isDirectory[index] ? Icons.folder : Icons.file_copy),
                        title: Text(entity),
                        onTap: () async {
                          if (isDirectory[index]) {
                            getEntities(Directory(currentRootPath + entity));
                            getCrumbs();
                            setState(() {});
                          } else {
                            // LogHandler.log('Selected file: $currentRootPath$entity');
                            Navigator.of(context).pop(currentRootPath + entity);
                          }
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
