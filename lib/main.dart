import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:theme_provider/theme_provider.dart';

import 'globals/variables.dart';
import 'main_screen/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  packageInfo = await PackageInfo.fromPlatform();
  runApp(const MusicPlayerApp());
}

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ThemeProvider.controllerOf(context).loadThemeFromDisk();
    return ThemeProvider(
      saveThemesOnChange: true,
      loadThemeOnInit: true,
      themes: [
        AppTheme(
          id: 'light_theme',
          description: 'Light theme',
          data: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.white,
              brightness: Brightness.light,
            ),
          ),
        ),
        AppTheme(
          id: 'dark_theme',
          description: 'Dark theme',
          data: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.black,
              brightness: Brightness.dark,
            ),
          ),
        ),
      ],
      child: ThemeConsumer(
        child: Builder(
          builder: (context) => const MaterialApp(
            title: 'Music Player',
            home: MainScreen(),
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
