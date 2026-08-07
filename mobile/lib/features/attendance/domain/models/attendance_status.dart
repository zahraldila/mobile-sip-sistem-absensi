enum AttendanceStatus {
  checkedIn,
  checkedOut,
  pending,
  rejected,
  approved;

  String get displayName {
    switch (this) {
      case AttendanceStatus.checkedIn:
        return 'Sudah Check In';
      case AttendanceStatus.checkedOut:
        return 'Sudah Check Out';
      case AttendanceStatus.pending:
        return 'Menunggu';
      case AttendanceStatus.rejected:
        return 'Ditolak';
      case AttendanceStatus.approved:
        return 'Disetujui';
    }
  }
}
