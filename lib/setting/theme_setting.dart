import 'package:flutter/material.dart';
import 'package:theme_provider/theme_provider.dart';

import '../globals/widgets.dart';

class ThemeSetting extends StatefulWidget {
  const ThemeSetting({super.key});

  @override
  State<ThemeSetting> createState() => _ThemeSettingState();
}

class _ThemeSettingState extends State<ThemeSetting> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Theme settings',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
        ),
        body: ListView(
          children: [
            SwitchListTile(
              title: leadingText(context, 'Dark mode', false, 16),
              // subtitle: const Text('Backup data on app launch. May be undesirable in certain situations.'),
              value: ThemeProvider.themeOf(context).id.contains('dark'),
              onChanged: (_) => ThemeProvider.controllerOf(context).nextTheme(),
            ),
          ],
        ),
      ),
    );
  }
}
