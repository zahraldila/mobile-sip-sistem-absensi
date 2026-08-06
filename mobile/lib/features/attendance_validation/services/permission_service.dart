import 'package:permission_handler/permission_handler.dart';

abstract class PermissionService {
  Future<bool> isLocationPermissionGranted();
  Future<bool> isLocationPermissionPermanentlyDenied();
  Future<PermissionStatus> requestLocationPermission();
  Future<bool> openAppSettingsPage();
}

class PermissionServiceImpl implements PermissionService {
  @override
  Future<bool> isLocationPermissionGranted() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted;
  }

  @override
  Future<bool> isLocationPermissionPermanentlyDenied() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isPermanentlyDenied;
  }

  @override
  Future<PermissionStatus> requestLocationPermission() async {
    return await Permission.locationWhenInUse.request();
  }

  @override
  Future<bool> openAppSettingsPage() async {
    return await openAppSettings();
  }
}
