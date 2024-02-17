import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class StoragePermissionDialog extends StatelessWidget {
  const StoragePermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      title: const Center(child: Text('Storage Permission')),
      content: const Text(
        'Allow Music Hub to access storage?\nMusic Hub will only access the Download folder.',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.spaceAround,
      actions: [
        TextButton(
          child: const Text('No'),
          onPressed: () {
            debugPrint('Storage permission denied, exiting app');
            SystemNavigator.pop();
          },
        ),
        TextButton(
          child: const Text('Yes'),
          onPressed: () => Permission.manageExternalStorage.request().then(
            (status) async {
              if (status.isPermanentlyDenied) {
                debugPrint('Opening app settings to request permission');
                await openAppSettings();
              }
              if (status.isGranted && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ),
      ],
    );
  }
}
