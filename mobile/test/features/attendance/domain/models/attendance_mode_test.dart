import 'package:flutter_test/flutter_test.dart';
import 'package:sip_sistem_absensi_mobile/features/attendance/domain/models/attendance_mode.dart';

void main() {
  group('AttendanceMode', () {
    test('parses attendance mode values from backend payloads', () {
      expect(AttendanceMode.fromApiValue('wfo'), AttendanceMode.wfo);
      expect(AttendanceMode.fromApiValue('wfh'), AttendanceMode.wfh);
      expect(AttendanceMode.fromApiValue('wfc'), AttendanceMode.wfc);
      expect(AttendanceMode.fromApiValue('unknown'), AttendanceMode.wfo);
    });
  });
}
