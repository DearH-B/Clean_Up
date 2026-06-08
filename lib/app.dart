import 'package:flutter/material.dart';

import 'repositories/cleaning_task_repository.dart';
import 'repositories/cleaning_data_repository.dart';
import 'repositories/product_catalog_repository.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

class CleanUpApp extends StatelessWidget {
  const CleanUpApp({
    this.taskRepository = const SharedPreferencesCleaningTaskRepository(),
    this.dataRepository = const CleaningDataRepository(),
    this.catalogRepository = const RemoteFirstProductCatalogRepository(),
    super.key,
  });

  final CleaningTaskRepository taskRepository;
  final CleaningDataRepository dataRepository;
  final ProductCatalogRepository catalogRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clean Up',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: MainShell(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
        catalogRepository: catalogRepository,
      ),
    );
  }
}
