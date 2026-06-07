import 'package:flutter/material.dart';

import 'history_screen.dart';
import 'community_screen.dart';
import '../repositories/cleaning_task_repository.dart';
import 'today_screen.dart';
import 'zones_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    required this.taskRepository,
    super.key,
  });

  final CleaningTaskRepository taskRepository;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      TodayScreen(taskRepository: widget.taskRepository),
      const ZonesScreen(),
      const HistoryScreen(),
      const CommunityScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        child: screens[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: '오늘',
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
