import '../../services/wifi_service.dart';

class CheckWifiStatusUseCase {
  final WifiService wifiService;

  CheckWifiStatusUseCase(this.wifiService);

  Future<WifiInfo> execute() async {
    return await wifiService.getConnectedWifiInfo();
  }
}
