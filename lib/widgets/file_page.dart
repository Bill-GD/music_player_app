import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../globals/extensions.dart';
import '../globals/log_handler.dart';

class FilePage extends StatefulWidget {
  final Directory rootDirectory;

  const FilePage({super.key, required this.rootDirectory});

  @override
  State<FilePage> createState() => _FilePageState();

  static Future<String?> open({
    required BuildContext context,
    required Directory rootDirectory,
  }) async {
    return await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, _, __) => FilePage(rootDirectory: rootDirectory),
        transitionDuration: 300.ms,
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
        pageBuilder: (context, _, __) => FilePage(rootDirectory: rootDirectory),
        transitionDuration: 300.ms,
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

class _FilePageState extends State<FilePage> {
  var fileEntities = <String>[], isDirectory = <bool>[], crumbs = <String>[];
  String currentRootPath = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getEntities(widget.rootDirectory);
  }

  void getEntities(Directory root) {
    List<FileSystemEntity> entities;
    try {
      entities = root.listSync();
    } catch (e) {
      // showToast(context, 'Permission denied');
      root = root.parent;
      entities = root.listSync();
      rethrow;
    }

    fileEntities.clear();
    isDirectory.clear();

    currentRootPath = root.absolute.path;

    LogHandler.log('Getting file entities from $currentRootPath');

    for (final entity in entities) {
      fileEntities.add(entity.path.split(currentRootPath).last.split('/').last);
      isDirectory.add(entity is Directory);
    }
    // LogHandler.log('Entities: $fileEntities');

    getCrumbs();
    setState(() => isLoading = false);
  }

  void getCrumbs() {
    final parts = currentRootPath //
        .split(widget.rootDirectory.absolute.path)
        .last
        .split('/')
        .where((e) => e.isNotEmpty)
        .toList()
      ..insert(0, '/');
    LogHandler.log('Parts: $parts');

    crumbs.clear();
    for (final c in parts) {
      crumbs.add(c);
      crumbs.add(' > ');
    }
    crumbs.removeLast();
  }

  String getCrumbPath(int index) {
    return widget.rootDirectory.absolute.path + crumbs.sublist(1, index + 1).where((e) => !e.contains('>')).join('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Storage'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
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
                    style: i % 2 == 0
                        ? TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          )
                        : null,
                    recognizer: i % 2 == 0
                        ? (TapGestureRecognizer()
                          ..onTap = () {
                            setState(() => isLoading = true);
                            getEntities(i == 0 ? widget.rootDirectory : Directory(getCrumbPath(i)));
                          })
                        : null,
                  ),
              ]),
            ),
          ),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Flexible(
                  child: ListView.builder(
                    itemCount: fileEntities.length,
                    itemBuilder: (context, index) {
                      final entity = fileEntities[index];

                      return ListTile(
                        leading: Icon(isDirectory[index] ? Icons.folder : Icons.file_copy),
                        title: Text(entity),
                        onTap: () async {
                          if (isDirectory[index]) {
                            setState(() => isLoading = true);
                            getEntities(Directory('$currentRootPath/$entity'));
                          } else {
                            LogHandler.log('Selected file: ${'$currentRootPath/$entity'}');
                            // Navigator.of(context).pop(entity);
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
