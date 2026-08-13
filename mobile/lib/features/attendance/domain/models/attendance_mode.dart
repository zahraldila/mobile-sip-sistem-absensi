enum AttendanceMode {
  wfo,
  wfh,
  wfc;

  static AttendanceMode fromApiValue(String? value) {
    if (value == null) return AttendanceMode.wfo;
    switch (value.toLowerCase().trim()) {
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

  String get fullName {
    switch (this) {
      case AttendanceMode.wfo:
        return 'Work From Office (WFO)';
      case AttendanceMode.wfh:
        return 'Work From Home (WFH)';
      case AttendanceMode.wfc:
        return 'Work From Client (WFC)';
    }
  }
}

