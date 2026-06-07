class CleaningTask {
  const CleaningTask({
    required this.id,
    required this.title,
    required this.zoneName,
    required this.estimatedMinutes,
    required this.isDone,
    this.isRecurring = false,
    this.postponedLabel,
  });

  final String id;
  final String title;
  final String zoneName;
  final int estimatedMinutes;
  final bool isDone;
  final bool isRecurring;
  final String? postponedLabel;

  bool get isPostponed => postponedLabel != null;

  factory CleaningTask.fromJson(Map<String, Object?> json) {
    return CleaningTask(
      id: json['id'] as String,
      title: json['title'] as String,
      zoneName: json['zoneName'] as String,
      estimatedMinutes: json['estimatedMinutes'] as int,
      isDone: json['isDone'] as bool,
      isRecurring: json['isRecurring'] as bool? ?? false,
      postponedLabel: json['postponedLabel'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'zoneName': zoneName,
      'estimatedMinutes': estimatedMinutes,
      'isDone': isDone,
      'isRecurring': isRecurring,
      'postponedLabel': postponedLabel,
    };
  }

  CleaningTask copyWith({
    bool? isDone,
    String? postponedLabel,
    bool clearPostponed = false,
  }) {
    return CleaningTask(
      id: id,
      title: title,
      zoneName: zoneName,
      estimatedMinutes: estimatedMinutes,
      isDone: isDone ?? this.isDone,
      isRecurring: isRecurring,
      postponedLabel:
          clearPostponed ? null : postponedLabel ?? this.postponedLabel,
    );
  }
}
