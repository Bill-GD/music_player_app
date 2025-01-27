import 'dart:io';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../globals/utils.dart';
import '../handlers/log_handler.dart';

class FilePicker extends StatefulWidget {
  /// LIst of allowed file extensions, example: ['mp3', 'lrc']
  final List<String> allowedExtensions;
  final Directory rootDirectory;
  final bool showImage;

  const FilePicker._internal({
    required this.rootDirectory,
    required this.allowedExtensions,
    required this.showImage,
  });

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
        pageBuilder: (context, _, __) => FilePicker._internal(
          rootDirectory: rootDirectory,
          allowedExtensions: allowedExtensions,
          showImage: false,
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

  static Future<String?> image({
    required BuildContext context,
    required Directory rootDirectory,
  }) async {
    return await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, _, __) => FilePicker._internal(
          rootDirectory: rootDirectory,
          allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
          showImage: true,
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
  int depth = 0;

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
      entities = root //
          .listSync()
          .where(((e) => !e.path.split('/').last.startsWith('.trashed')))
          .toList();
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

    // sort directories first, while also sort by name
    entities.sort((a, b) {
      if (a is Directory && b is File) return -1;
      if (a is File && b is Directory) return 1;
      if (widget.showImage && a is File && b is File) return b.statSync().changed.compareTo(a.statSync().changed);
      return a.path.compareTo(b.path);
    });

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

  void popHandler() {
    if (depth == 0) return;
    getEntities(Directory(getCrumbPath(depth--)));
    getCrumbs();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: depth == 0,
      onPopInvoked: (didPop) => popHandler(),
      child: Scaffold(
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
                      style: i < crumbs.length - 1
                          ? TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
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
                              depth = i ~/ 2;
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
                          Icon(Icons.folder_off_rounded, size: 70),
                          Text('Empty', style: TextStyle(fontSize: 24)),
                        ],
                      ),
                    )
                  : Scrollbar(
                      interactive: true,
                      thumbVisibility: true,
                      radius: const Radius.circular(16),
                      thickness: min(fileEntities.length ~/ 3, 8).toDouble(),
                      child: contentView(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  BoxScrollView contentView() {
    return widget.showImage
        ? GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            padding: const EdgeInsets.all(8),
            itemCount: fileEntities.length,
            itemBuilder: (context, index) {
              final entity = fileEntities[index];

              return GestureDetector(
                onTap: () => pickFileCallback(index),
                child: isDirectory[index]
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.folder_rounded, size: 70),
                          Text(entity),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(currentRootPath + entity),
                          fit: BoxFit.cover,
                        ),
                      ),
              );
            },
          )
        : ListView.builder(
            itemCount: fileEntities.length,
            itemBuilder: (context, index) {
              final entity = fileEntities[index];

              return ListTile(
                leading: Icon(isDirectory[index] ? Icons.folder_rounded : Icons.file_copy),
                title: Text(entity),
                onTap: () => pickFileCallback(index),
              );
            },
          );
  }

  void pickFileCallback(int index) {
    if (isDirectory[index]) {
      getEntities(Directory(currentRootPath + fileEntities[index]));
      depth++;
      getCrumbs();
      setState(() {});
    } else {
      // LogHandler.log('Selected file: $currentRootPath$entity');
      Navigator.of(context).pop(currentRootPath + fileEntities[index]);
    }
  }
}
