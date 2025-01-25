import 'package:flutter/material.dart';

import '../globals/extensions.dart';
import '../globals/log_handler.dart';
import '../globals/utils.dart';
import '../globals/variables.dart';
import 'version_dialog.dart';

class VersionList extends StatefulWidget {
  const VersionList({super.key});

  @override
  State<VersionList> createState() => _VersionListState();
}

class _VersionListState extends State<VersionList> {
  List<String> tags = [], shas = [];
  int versionCount = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    getAllTags().then((value) {
      value = value.reversed.toList();
      tags = value.map((e) => e.$1).toList();
      shas = value.map((e) => e.$2).toList();
      versionCount = tags.length;
      if (context.mounted) {
        LogHandler.log('Got $versionCount tags');
        setState(() => loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Version list',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final res = (await getAllTags()).reversed.toList();
          tags = res.map((e) => e.$1).toList();
          shas = res.map((e) => e.$2).toList();
          versionCount = tags.length;
          if (context.mounted) {
            LogHandler.log('Got $versionCount tags');
            setState(() {});
          }
          if (context.mounted) setState(() {});
        },
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: versionCount,
                itemBuilder: (context, index) {
                  bool isDevBuild = tags[index].contains('_dev_');
                  return ListTile(
                    leading: tags[index] == 'v${Globals.appVersion}' //
                        ? const Icon(Icons.arrow_right_rounded)
                        : const Text(''),
                    title: Text(
                      tags[index],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text('${shas[index]} - ${isDevBuild ? 'dev' : 'stable'}'),
                    visualDensity: const VisualDensity(vertical: 3, horizontal: 4),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isDevBuild)
                          IconButton(
                            icon: const Icon(Icons.file_present_rounded),
                            onPressed: () {
                              Navigator.of(context).push(RawDialogRoute(
                                transitionDuration: 300.ms,
                                barrierDismissible: true,
                                barrierLabel: '',
                                transitionBuilder: (_, anim1, __, child) {
                                  return ScaleTransition(
                                    scale: anim1.drive(CurveTween(curve: Curves.easeOutQuart)),
                                    alignment: Alignment.center,
                                    child: child,
                                  );
                                },
                                pageBuilder: (context, __, ___) {
                                  return VersionDialog(
                                    tag: tags[index],
                                    sha: shas[index],
                                  );
                                },
                              ));
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.logo_dev_rounded),
                          onPressed: () {
                            Navigator.of(context).push(RawDialogRoute(
                              transitionDuration: 300.ms,
                              barrierDismissible: true,
                              barrierLabel: '',
                              transitionBuilder: (_, anim1, __, child) {
                                return ScaleTransition(
                                  scale: anim1.drive(CurveTween(curve: Curves.easeOutQuart)),
                                  alignment: Alignment.center,
                                  child: child,
                                );
                              },
                              pageBuilder: (context, __, ___) {
                                return VersionDialog(
                                  tag: tags[index],
                                  sha: shas[index],
                                  dev: true,
                                );
                              },
                            ));
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
