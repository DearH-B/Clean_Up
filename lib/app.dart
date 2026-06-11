import 'package:flutter/material.dart';

import 'repositories/product_data_repository.dart';
import 'repositories/product_catalog_repository.dart';
import 'repositories/product_submission_repository.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

class CleanUpApp extends StatelessWidget {
  const CleanUpApp({
    this.dataRepository = const ProductDataRepository(),
    this.catalogRepository = const RemoteFirstProductCatalogRepository(),
    this.submissionRepository = const RemoteProductSubmissionRepository(),
    super.key,
  });

  final ProductDataRepository dataRepository;
  final ProductCatalogRepository catalogRepository;
  final ProductSubmissionRepository submissionRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clean Up',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: MainShell(
        dataRepository: dataRepository,
        catalogRepository: catalogRepository,
        submissionRepository: submissionRepository,
      ),
    );
  }
}
