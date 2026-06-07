import 'package:flutter/material.dart';

import 'repositories/cleaning_task_repository.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

class CleanUpApp extends StatelessWidget {
  const CleanUpApp({
    this.taskRepository = const SharedPreferencesCleaningTaskRepository(),
    super.key,
  });

  final CleaningTaskRepository taskRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clean Up',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: MainShell(taskRepository: taskRepository),
    );
  }
}
