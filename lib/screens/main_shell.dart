import 'package:flutter/material.dart';

import '../repositories/product_data_repository.dart';
import '../repositories/product_catalog_repository.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'zones_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    required this.dataRepository,
    required this.catalogRepository,
    super.key,
  });

  final ProductDataRepository dataRepository;
  final ProductCatalogRepository catalogRepository;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  int _historyVersion = 0;
  late final Widget _homeScreen;
  late final Widget _productsScreen;

  @override
  void initState() {
    super.initState();
    _homeScreen = HomeScreen(
      dataRepository: widget.dataRepository,
      catalogRepository: widget.catalogRepository,
      onOpenProducts: () {
        setState(() {
          _selectedIndex = 1;
        });
      },
    );
    _productsScreen = ZonesScreen(
      dataRepository: widget.dataRepository,
      catalogRepository: widget.catalogRepository,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _homeScreen,
      _productsScreen,
      HistoryScreen(
        key: ValueKey(_historyVersion),
        dataRepository: widget.dataRepository,
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
        ],
      ),
    );
  }
}
