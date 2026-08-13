import 'dart:async';
import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  Completer<String>? _activeScan;
  Timer? _scanTimeout;

  /// Mengecek apakah device memiliki sensor NFC dan sedang aktif
  Future<bool> isNfcAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      return false;
    }
  }

  /// Memulai sesi scan NFC.
  /// Mengembalikan UID berformat String (contoh: "04:A1:B2:C3").
  ///
  /// Satu sesi dibatasi waktu agar UI tidak menunggu selamanya ketika kartu
  /// tidak ditempelkan. Hanya satu sesi scan yang boleh aktif pada satu waktu.
  Future<String> scanCard({Duration timeout = const Duration(seconds: 30)}) async {
    if (!await isNfcAvailable()) {
      throw const NfcScanException('NFC tidak tersedia atau belum diaktifkan.');
    }

    if (_activeScan != null && !_activeScan!.isCompleted) {
      throw const NfcScanException('Pemindaian NFC sedang berlangsung.');
    }

    final completer = Completer<String>();
    _activeScan = completer;
    _scanTimeout = Timer(timeout, () {
      _completeError(const NfcScanException('Waktu tap kartu habis.'));
      stopScan();
    });

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final uidBytes = _extractUid(tag);

            if (uidBytes.isNotEmpty) {
              final uidHex = uidBytes
                  .map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase())
                  .join(':');
              _complete(uidHex);
            } else {
              _completeError(const NfcScanException('UID kartu NFC tidak dapat dibaca.'));
            }
          } catch (_) {
            _completeError(const NfcScanException('Terjadi kesalahan saat membaca kartu NFC.'));
          } finally {
            stopScan();
          }
        },
      );
    } catch (_) {
      _completeError(const NfcScanException('Gagal memulai pemindaian NFC.'));
    }

    return completer.future;
  }

  List<int> _extractUid(NfcTag tag) {
    // UID tag Android biasanya tersedia pada salah satu teknologi ini.
    for (final key in const [
      'nfca',
      'mifareclassic',
      'mifareultralight',
      'nfcb',
      'nfcf',
      'nfcv',
    ]) {
      final technology = tag.data[key];
      if (technology is Map) {
        final identifier = technology['identifier'];
        if (identifier is List) {
          final bytes = identifier.whereType<num>().map((byte) => byte.toInt()).toList();
          if (bytes.isNotEmpty) return bytes;
        }
      }
    }
    return const [];
  }

  void _complete(String uid) {
    _scanTimeout?.cancel();
    if (_activeScan != null && !_activeScan!.isCompleted) _activeScan!.complete(uid);
  }

  void _completeError(Object error) {
    _scanTimeout?.cancel();
    if (_activeScan != null && !_activeScan!.isCompleted) _activeScan!.completeError(error);
  }

  /// Menghentikan paksa sesi scan NFC (misalnya saat user menutup halaman sebelum nge-tap)
  void stopScan() {
    _scanTimeout?.cancel();
    try {
      NfcManager.instance.stopSession();
    } catch (e) {
      // Abaikan error jika session memang sudah mati
    }
  }
}

class NfcScanException implements Exception {
  const NfcScanException(this.message);

  final String message;

  @override
  String toString() => message;
}
