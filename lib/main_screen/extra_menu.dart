import 'package:flutter/material.dart';

class ExtraMenu extends StatelessWidget {
  const ExtraMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: const [
          DrawerHeader(
            child: Text('Menu'),
          ),
        ],
      ),
    );
  }
}
