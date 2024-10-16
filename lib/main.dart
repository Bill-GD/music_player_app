import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:theme_provider/theme_provider.dart';

import 'globals/variables.dart';
import 'main_screen/main_screen.dart';
import 'player/player_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Globals.packageInfo = await PackageInfo.fromPlatform();
  Globals.audioHandler = (await initAudioHandler()) as AudioPlayerHandler;
  Globals.storagePath = (await getExternalStorageDirectory())?.path ?? '';
  await Config.loadConfig();

  runApp(const MusicPlayerApp());
}

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

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
          builder: (context) => MaterialApp(
            theme: ThemeProvider.themeOf(context).data,
            title: 'Music Hub',
            home: const MainScreen(),
            // setup route to use Navigator.pushNamed to wait page navigation (pause previous page until return)
            // routes: {
            //   '/music_downloader': (context) => const MusicDownloader(),
            // },
          ),
        ),
      ),
    );
  }
}
