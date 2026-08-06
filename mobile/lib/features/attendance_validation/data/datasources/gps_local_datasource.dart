import '../../services/gps_service.dart';

abstract class GpsLocalDataSource {
  Future<bool> isGpsEnabled();
  Future<DevicePosition> getCurrentPosition({Duration? timeout});
  Future<DevicePosition?> getLastKnownPosition();
}

class GpsLocalDataSourceImpl implements GpsLocalDataSource {
  final GpsService gpsService;

  GpsLocalDataSourceImpl({required this.gpsService});

  @override
  Future<bool> isGpsEnabled() async {
    return await gpsService.isLocationServiceEnabled();
  }

  @override
  Future<DevicePosition> getCurrentPosition({Duration? timeout}) async {
    return await gpsService.getCurrentPosition(
      timeLimit: timeout ?? const Duration(seconds: 10),
    );
  }

  @override
  Future<DevicePosition?> getLastKnownPosition() async {
    return await gpsService.getLastKnownPosition();
  }
}
