enum SubmissionStatus {
  pending,
  disetujui,
  ditolak,
  unknown,
}

extension SubmissionStatusX on SubmissionStatus {
  static SubmissionStatus fromString(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'pending') return SubmissionStatus.pending;
    if (normalized == 'disetujui') return SubmissionStatus.disetujui;
    if (normalized == 'ditolak') return SubmissionStatus.ditolak;
    return SubmissionStatus.unknown;
  }
}
