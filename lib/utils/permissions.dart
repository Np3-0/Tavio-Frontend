import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermission({required Permission permission}) async {
  final status = await permission.request();
  if (status == PermissionStatus.denied) {
    // Handle the case when the user denies the permission
    print('Permission denied: $permission');
  } else if (status == PermissionStatus.permanentlyDenied) {
    // Handle the case when the user permanently denies the permission
    print('Permission permanently denied: $permission');
  } else if (status == PermissionStatus.granted) {
    // Handle the case when the user grants the permission
    print('Permission granted: $permission');
  }
}

Future<Map<Permission, PermissionStatus>> requestAppPermissions() async {
  final List<Permission> permissions = <Permission>[
    Permission.location,
    Permission.microphone,
    Permission.camera,
    Permission.photos,
  ];

  final Map<Permission, PermissionStatus> statuses =
      await permissions.request();

  for (final MapEntry<Permission, PermissionStatus> entry in statuses.entries) {
    if (entry.value == PermissionStatus.denied) {
      print('Permission denied: ${entry.key}');
    } else if (entry.value == PermissionStatus.permanentlyDenied) {
      print('Permission permanently denied: ${entry.key}');
    } else if (entry.value == PermissionStatus.granted) {
      print('Permission granted: ${entry.key}');
    }
  }

  return statuses;
}