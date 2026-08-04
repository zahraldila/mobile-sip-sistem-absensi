enum AttendanceMode {
  wfo,
  wfh,
  wfc;

  static AttendanceMode fromApiValue(String? value) {
    switch (value?.toLowerCase()) {
      case 'wfh':
        return AttendanceMode.wfh;
      case 'wfc':
        return AttendanceMode.wfc;
      case 'wfo':
      default:
        return AttendanceMode.wfo;
    }
  }

  String get displayName {
    switch (this) {
      case AttendanceMode.wfo:
        return 'WFO';
      case AttendanceMode.wfh:
        return 'WFH';
      case AttendanceMode.wfc:
        return 'WFC';
    }
  }
}
