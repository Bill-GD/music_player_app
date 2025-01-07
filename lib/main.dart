import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:theme_provider/theme_provider.dart';

import 'globals/database_handler.dart';
import 'globals/log_handler.dart';
import 'globals/variables.dart';
import 'globals/widgets.dart';
import 'main_screen/main_screen.dart';
import 'player/player_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final packageInfo = await PackageInfo.fromPlatform();
  Globals.appName = packageInfo.appName;
  Globals.appVersion = packageInfo.version;
  Globals.appBuildNum = packageInfo.buildNumber;

  Globals.storagePath = (await getExternalStorageDirectory())?.parent.path ?? '';

  Globals.logPath = '${Globals.storagePath}/files/log.txt';
  Globals.jsonPath = '${Globals.storagePath}/files/tracks.json';
  Globals.dbPath = '${Globals.storagePath}/database/database.db';
  Globals.backupPath = '/storage/emulated/0/Android/music_hub_backup.json';

  LogHandler.init();

  Globals.audioHandler = (await initAudioHandler()) as AudioPlayerHandler;
  await Config.loadConfig();
  await DatabaseHandler.init();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  PlatformDispatcher.instance.onError = (e, s) {
    LogHandler.log(e.toString(), LogLevel.error);
    final curContext = navigatorKey.currentContext;
    if (curContext == null) return false;

    showPopupMessage(
      curContext,
      title: e.toString(),
      content: s.toString(),
      centerContent: false,
      horizontalPadding: 16,
    );
    return true;
  };

  runApp(MusicPlayerApp(navKey: navigatorKey));
}

class MusicPlayerApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navKey;

  const MusicPlayerApp({super.key, required this.navKey});

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      saveThemesOnChange: true,
      loadThemeOnInit: true,
      defaultThemeId: '${SchedulerBinding.instance.platformDispatcher.platformBrightness.name}_theme',
      themes: [
        AppTheme(
          id: 'light_theme',
          description: 'Light theme',
          data: ThemeData(
            useMaterial3: true,
            fontFamily: 'Nunito',
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.white,
              brightness: Brightness.light,
            ).copyWith(background: Colors.white),
          ),
        ),
        AppTheme(
          id: 'dark_theme',
          description: 'Dark theme',
          data: ThemeData(
            useMaterial3: true,
            fontFamily: 'Nunito',
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.grey,
              brightness: Brightness.dark,
            ),
          ),
        ),
      ],
      child: ThemeConsumer(
        child: Builder(
          builder: (context) {
            return MaterialApp(
              navigatorKey: navKey,
              theme: ThemeProvider.themeOf(context).data,
              title: 'Music Hub',
              home: const MainScreen(),
              // setup route to use Navigator.pushNamed to wait page navigation (pause previous page until return)
              // routes: {
              //   '/music_downloader': (context) => const MusicDownloader(),
              // },
            );
          },
        ),
      ),
    );
  }
}
