import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final permissionsServiceProvider = Provider((ref) => PermissionsService());

class PermissionsService {
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> requestPhotoPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<PermissionStatus> checkCameraStatus() async {
    return await Permission.camera.status;
  }

  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  Future<Map<String, PermissionStatus>> requestAllRequiredPermissions() async {
    final permissions = {
      'camera': Permission.camera,
      'photos': Permission.photos,
      'storage': Permission.storage,
    };

    final result = <String, PermissionStatus>{};
    for (final entry in permissions.entries) {
      result[entry.key] = await entry.value.request();
    }
    return result;
  }
}
