import 'package:flutter/material.dart';

import '../repositories/product_data_repository.dart';
import '../repositories/product_catalog_repository.dart';
import '../repositories/product_submission_repository.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'zones_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    required this.dataRepository,
    required this.catalogRepository,
    required this.submissionRepository,
    super.key,
  });

  final ProductDataRepository dataRepository;
  final ProductCatalogRepository catalogRepository;
  final ProductSubmissionRepository submissionRepository;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  int _homeVersion = 0;
  int _historyVersion = 0;
  int _productsVersion = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        key: ValueKey(_homeVersion),
        dataRepository: widget.dataRepository,
        catalogRepository: widget.catalogRepository,
        submissionRepository: widget.submissionRepository,
        onOpenProducts: () {
          setState(() {
            _selectedIndex = 1;
          });
        },
      ),
      ZonesScreen(
        key: ValueKey(_productsVersion),
        dataRepository: widget.dataRepository,
        catalogRepository: widget.catalogRepository,
      ),
      HistoryScreen(
        key: ValueKey(_historyVersion),
        dataRepository: widget.dataRepository,
      ),
      SettingsScreen(
        dataRepository: widget.dataRepository,
        onDataChanged: () {
          setState(() {
            _homeVersion++;
            _productsVersion++;
            _historyVersion++;
          });
        },
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
            if (index == 0) {
              _homeVersion++;
            }
            if (index == 2) {
              _historyVersion++;
            }
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: '내 제품',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: '기록',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}
