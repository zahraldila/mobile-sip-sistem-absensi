import 'dart:async';

class WifiInfo {
  final bool isConnected;
  final String? ssid;
  final String? bssid;
  final String? ipAddress;

  const WifiInfo({
    required this.isConnected,
    this.ssid,
    this.bssid,
    this.ipAddress,
  });

  const WifiInfo.disconnected()
      : isConnected = false,
        ssid = null,
        bssid = null,
        ipAddress = null;

  factory WifiInfo.connected({
    required String ssid,
    String? bssid,
    String? ipAddress,
  }) {
    return WifiInfo(
      isConnected: true,
      ssid: ssid,
      bssid: bssid ?? '00:14:22:01:23:45',
      ipAddress: ipAddress ?? '192.168.1.100',
    );
  }
}

abstract class WifiService {
  Future<bool> isWifiConnected();
  Future<WifiInfo> getConnectedWifiInfo();
  Future<bool> isSsidAllowed(String currentSsid, List<String> allowedSsids);
}

class WifiServiceImpl implements WifiService {
  final String? overrideSsid;
  final String? overrideBssid;
  final bool? overrideConnected;

  WifiServiceImpl({
    this.overrideSsid,
    this.overrideBssid,
    this.overrideConnected,
  });

  @override
  Future<bool> isWifiConnected() async {
    if (overrideConnected != null) return overrideConnected!;
    final info = await getConnectedWifiInfo();
    return info.isConnected;
  }

  @override
  Future<WifiInfo> getConnectedWifiInfo() async {
    if (overrideConnected == false) {
      return const WifiInfo.disconnected();
    }

    // Default development/office simulated connected Wi-Fi
    // Ready for plugin injection (e.g., NetworkInfo().getWifiName())
    final ssid = overrideSsid ?? 'SIP-Office-WiFi';
    final bssid = overrideBssid ?? '00:14:22:01:23:45';

    return WifiInfo.connected(
      ssid: ssid,
      bssid: bssid,
      ipAddress: '192.168.10.45',
    );
  }

  @override
  Future<bool> isSsidAllowed(
    String currentSsid,
    List<String> allowedSsids,
  ) async {
    final cleanCurrent = currentSsid.replaceAll('"', '').trim().toLowerCase();
    return allowedSsids.any((allowed) =>
        allowed.replaceAll('"', '').trim().toLowerCase() == cleanCurrent);
  }
}
