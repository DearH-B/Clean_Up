class CareRecord {
  const CareRecord({
    required this.id,
    required this.title,
    required this.spaceName,
    required this.completedAt,
    required this.minutes,
    this.productId,
  });

  final String id;
  final String title;
  final String spaceName;
  final DateTime completedAt;
  final int minutes;
  final String? productId;

  factory CareRecord.fromJson(Map<String, Object?> json) {
    return CareRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      spaceName:
          json['spaceName'] as String? ?? json['zoneName'] as String? ?? '',
      completedAt: DateTime.parse(json['completedAt'] as String),
      minutes: json['minutes'] as int,
      productId: json['productId'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'spaceName': spaceName,
      'completedAt': completedAt.toIso8601String(),
      'minutes': minutes,
      'productId': productId,
    };
  }
}
