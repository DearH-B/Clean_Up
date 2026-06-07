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

  factory CleaningRecord.fromJson(Map<String, Object?> json) {
    return CleaningRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      zoneName: json['zoneName'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      minutes: json['minutes'] as int,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'zoneName': zoneName,
      'completedAt': completedAt.toIso8601String(),
      'minutes': minutes,
    };
  }
}
