import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class StoragePermissionPage extends StatelessWidget {
  const StoragePermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Storage Permission'),
        centerTitle: true,
      ),
      body: const Padding(
        padding: EdgeInsets.only(left: 20, top: 100),
        child: Text(
          'Music Hub requires permission to access the device storage to get the music tracks.\n\nMusic Hub will only access the Download folder.',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      bottomNavigationBar: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton(
            onPressed: () {
              debugPrint('Storage permission denied, exiting app');
              SystemNavigator.pop();
            },
            child: const Text('Refuse'),
          ),
          TextButton(
            onPressed: () async {
              PermissionStatus status = await Permission.manageExternalStorage.request();
              if (status.isPermanentlyDenied) {
                debugPrint('Opening app settings to request permission');
                await openAppSettings();
              }
              if (status.isDenied) {
                debugPrint('Storage permission denied, exiting app');
                SystemNavigator.pop();
              }
              if (status.isGranted && context.mounted) {
                Navigator.pop(context);
              }
            },
            style: const ButtonStyle(
              backgroundColor: MaterialStatePropertyAll(Colors.blue),
            ),
            child: const Text(
              'Accept',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
