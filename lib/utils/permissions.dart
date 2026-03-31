import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermission({required Permission permission}) async {
  final status = await permission.request();
  switch (status) {
    case PermissionStatus.denied:
      print('User denied: $permission');
    case PermissionStatus.permanentlyDenied:
      print('User permanently denied: $permission');
    case PermissionStatus.granted:
      print('User granted: $permission');
    default:
      break;
  }
}

Future<Map<Permission, PermissionStatus>> requestAppPermissions() async {
  final permissions = [
    Permission.location,
    Permission.microphone,
    Permission.camera,
    Permission.photos,
  ];

  final statuses = await permissions.request();

  for (final entry in statuses.entries) {
    switch (entry.value) {
      case PermissionStatus.denied:
        print('Denied: ${entry.key}');
      case PermissionStatus.permanentlyDenied:
        print('Permanently denied: ${entry.key}');
      case PermissionStatus.granted:
        print('Granted: ${entry.key}');
      default:
        break;
    }
  }

  return statuses;
}