import 'package:flutter/material.dart';

import 'history_screen.dart';
import 'community_screen.dart';
import '../repositories/cleaning_data_repository.dart';
import '../repositories/cleaning_task_repository.dart';
import 'today_screen.dart';
import 'zones_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    required this.taskRepository,
    required this.dataRepository,
    super.key,
  });

  final CleaningTaskRepository taskRepository;
  final CleaningDataRepository dataRepository;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  int _historyVersion = 0;
  late final Widget _todayScreen;
  late final Widget _zonesScreen;
  late final Widget _communityScreen;

  @override
  void initState() {
    super.initState();
    _todayScreen = TodayScreen(
      taskRepository: widget.taskRepository,
      dataRepository: widget.dataRepository,
    );
    _zonesScreen = ZonesScreen(dataRepository: widget.dataRepository);
    _communityScreen = CommunityScreen(dataRepository: widget.dataRepository);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _todayScreen,
      _zonesScreen,
      HistoryScreen(
        key: ValueKey(_historyVersion),
        dataRepository: widget.dataRepository,
      ),
      _communityScreen,
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
            label: '지금 청소',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_work_outlined),
            selectedIcon: Icon(Icons.home_work),
            label: '구역',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: '기록',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: '자랑',
          ),
        ],
      ),
    );
  }
}
