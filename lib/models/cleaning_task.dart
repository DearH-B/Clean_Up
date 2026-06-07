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
