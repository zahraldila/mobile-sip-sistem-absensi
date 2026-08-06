import '../../services/wifi_service.dart';

abstract class WifiLocalDataSource {
  Future<bool> isConnected();
  Future<WifiInfo> getConnectedWifiInfo();
  Future<bool> isAllowedSsid(String ssid, List<String> allowedSsids);
}

class WifiLocalDataSourceImpl implements WifiLocalDataSource {
  final WifiService wifiService;

  WifiLocalDataSourceImpl({required this.wifiService});

  @override
  Future<bool> isConnected() async {
    return await wifiService.isWifiConnected();
  }

  @override
  Future<WifiInfo> getConnectedWifiInfo() async {
    return await wifiService.getConnectedWifiInfo();
  }

  @override
  Future<bool> isAllowedSsid(String ssid, List<String> allowedSsids) async {
    return await wifiService.isSsidAllowed(ssid, allowedSsids);
  }
}
