import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cleaning_task.dart';

abstract interface class CleaningTaskRepository {
  Future<List<CleaningTask>?> loadTodayTasks();

  Future<void> saveTodayTasks(List<CleaningTask> tasks);
}

class SharedPreferencesCleaningTaskRepository
    implements CleaningTaskRepository {
  const SharedPreferencesCleaningTaskRepository();

  static const _todayTasksKey = 'today_tasks_v1';

  @override
  Future<List<CleaningTask>?> loadTodayTasks() async {
    final preferences = await SharedPreferences.getInstance();
    final savedTasks = preferences.getString(_todayTasksKey);
    if (savedTasks == null) {
      return null;
    }

    final decoded = jsonDecode(savedTasks) as List<dynamic>;
    return decoded
        .map((item) => CleaningTask.fromJson(
              Map<String, Object?>.from(item as Map),
            ))
        .toList();
  }

  @override
  Future<void> saveTodayTasks(List<CleaningTask> tasks) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode([
      for (final task in tasks) task.toJson(),
    ]);
    await preferences.setString(_todayTasksKey, encoded);
  }
}
