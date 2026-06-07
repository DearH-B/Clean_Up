class CleaningZone {
  const CleaningZone({
    required this.id,
    required this.name,
    required this.description,
    required this.taskCount,
    required this.completedTaskCount,
  });

  final String id;
  final String name;
  final String description;
  final int taskCount;
  final int completedTaskCount;

  double get progress {
    if (taskCount == 0) {
      return 0;
    }

    return completedTaskCount / taskCount;
  }

  factory CleaningZone.fromJson(Map<String, Object?> json) {
    return CleaningZone(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      taskCount: json['taskCount'] as int,
      completedTaskCount: json['completedTaskCount'] as int,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'taskCount': taskCount,
      'completedTaskCount': completedTaskCount,
    };
  }

  CleaningZone copyWith({
    String? id,
    String? name,
    String? description,
    int? taskCount,
    int? completedTaskCount,
  }) {
    return CleaningZone(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      taskCount: taskCount ?? this.taskCount,
      completedTaskCount: completedTaskCount ?? this.completedTaskCount,
    );
  }
}
