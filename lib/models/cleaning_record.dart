class CleaningRecord {
  const CleaningRecord({
    required this.id,
    required this.title,
    required this.zoneName,
    required this.completedAt,
    required this.minutes,
  });

  final String id;
  final String title;
  final String zoneName;
  final DateTime completedAt;
  final int minutes;
}
