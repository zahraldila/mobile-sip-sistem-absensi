import '../../services/permission_service.dart';

class CheckLocationPermissionUseCase {
  final PermissionService permissionService;

  CheckLocationPermissionUseCase(this.permissionService);

  Future<bool> execute() async {
    return await permissionService.isLocationPermissionGranted();
  }
}
