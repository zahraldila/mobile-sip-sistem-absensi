import '../../services/gps_service.dart';

class CheckGpsStatusUseCase {
  final GpsService gpsService;

  CheckGpsStatusUseCase(this.gpsService);

  Future<bool> execute() async {
    return await gpsService.isLocationServiceEnabled();
  }
}
