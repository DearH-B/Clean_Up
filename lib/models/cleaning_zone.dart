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
}
