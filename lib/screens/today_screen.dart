import 'dart:async';

import 'package:flutter/material.dart';

import '../data/mock_cleaning_data.dart';
import '../data/mock_zone_items.dart';
import '../models/cleaning_record.dart';
import '../models/cleaning_task.dart';
import '../repositories/cleaning_data_repository.dart';
import '../repositories/cleaning_task_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/fairy_image.dart';
import '../widgets/task_tile.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({
    required this.taskRepository,
    required this.dataRepository,
    super.key,
  });

  final CleaningTaskRepository taskRepository;
  final CleaningDataRepository dataRepository;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late List<CleaningTask> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = todayTasks.toList();
    unawaited(_loadInitialTasks());
  }

  @override
  Widget build(BuildContext context) {
    final activeTasks = _tasks.where((task) => !task.isPostponed).toList();
    final postponedTasks = _tasks.where((task) => task.isPostponed).toList();
    final completedCount = activeTasks.where((task) => task.isDone).length;
    final remainingMinutes = activeTasks
        .where((task) => !task.isDone)
        .fold<int>(0, (sum, task) => sum + task.estimatedMinutes);
    final fairyState = _fairyState(completedCount, activeTasks.length);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Text('오늘', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          '오늘 필요한 청소만 가볍게 담아보세요.',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 18),
        Container(
          height: 196,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.pinkSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -4,
                bottom: -20,
                child: FairyImage(
                  size: 174,
                  assetPath: fairyState.assetPath,
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FairyLabel(),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 220,
                        child: Text(
                          fairyState.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 225,
                        child: Text(fairyState.message),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 190,
                        child: LinearProgressIndicator(
                          value: activeTasks.isEmpty
                              ? 0
                              : completedCount / activeTasks.length,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                '오늘 할 일',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton.icon(
              onPressed: _showAddTaskSheet,
              icon: const Icon(Icons.add, size: 19),
              label: const Text('할 일 추가'),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            activeTasks.isEmpty
                ? '아직 할 일이 없어요.'
                : '$completedCount/${activeTasks.length} 완료 · 남은 시간 약 $remainingMinutes분',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        for (final task in activeTasks) ...[
          TaskTile(
            task: task,
            onToggle: () => _toggleTask(task),
            onDelete: () => _deleteTask(task),
            onPostpone: () => _showPostponeSheet(task),
          ),
          const SizedBox(height: 10),
        ],
        if (postponedTasks.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('미룬 할 일', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '오늘 진행률에는 포함되지 않아요.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          for (final task in postponedTasks) ...[
            TaskTile(
              task: task,
              onToggle: () {},
              onDelete: () => _deleteTask(task),
              onRestore: () => _restoreTask(task),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }

  void _toggleTask(CleaningTask task) {
    final index = _tasks.indexWhere((candidate) => candidate.id == task.id);
    if (index == -1) {
      return;
    }

    setState(() {
      _tasks[index] = task.copyWith(isDone: !task.isDone);
    });
    unawaited(_saveTasks());

    if (!task.isDone) {
      unawaited(_completeLinkedZoneItem(task));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _completionSnack(_tasks.where((item) => item.isDone).length)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showAddTaskSheet() async {
    final task = await showModalBottomSheet<CleaningTask>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _AddTaskSheet(),
    );

    if (task == null || !mounted) {
      return;
    }

    setState(() {
      _tasks.add(task);
    });
    unawaited(_saveTasks());
  }

  Future<void> _showPostponeSheet(CleaningTask task) async {
    final label = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${task.title} 미루기',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('언제로 옮길까요? 오늘 진행률에서는 제외돼요.'),
              const SizedBox(height: 14),
              for (final option in ['내일로 미룸', '3일 뒤로 미룸', '다음 주로 미룸'])
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: Text(option),
                  onTap: () => Navigator.of(context).pop(option),
                ),
            ],
          ),
        ),
      ),
    );

    if (label == null || !mounted) {
      return;
    }

    final index = _tasks.indexWhere((candidate) => candidate.id == task.id);
    setState(() {
      _tasks[index] = task.copyWith(postponedLabel: label);
    });
    unawaited(_saveTasks());
  }

  void _restoreTask(CleaningTask task) {
    final index = _tasks.indexWhere((candidate) => candidate.id == task.id);
    setState(() {
      _tasks[index] = task.copyWith(clearPostponed: true);
    });
    unawaited(_saveTasks());
  }

  void _deleteTask(CleaningTask task) {
    final removedIndex =
        _tasks.indexWhere((candidate) => candidate.id == task.id);
    if (removedIndex == -1) {
      return;
    }

    setState(() {
      _tasks.removeAt(removedIndex);
    });
    unawaited(_saveTasks());

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text("'${task.title}'을 오늘 할 일에서 지웠어요."),
          action: SnackBarAction(
            label: '되돌리기',
            onPressed: () {
              if (!mounted ||
                  _tasks.any((candidate) => candidate.id == task.id)) {
                return;
              }

              setState(() {
                final restoreIndex = removedIndex.clamp(0, _tasks.length);
                _tasks.insert(restoreIndex, task);
              });
              unawaited(_saveTasks());
            },
          ),
        ),
      );
  }

  Future<void> _loadInitialTasks() async {
    final savedTasks = await widget.taskRepository.loadTodayTasks();
    final savedItems = await widget.dataRepository.loadZoneItems();
    var tasks = savedTasks ?? todayTasks.toList();
    var changed = false;

    final items = savedItems ?? mockZoneItems;
    if (items.isNotEmpty) {
      final now = DateTime.now();
      for (final item in items.where((item) => item.isDue(now))) {
        final taskId = _scheduledTaskId(item.id);
        if (tasks.any((task) => task.id == taskId)) {
          continue;
        }

        tasks = [
          ...tasks,
          CleaningTask(
            id: taskId,
            title: '${item.name} 정기 청소',
            zoneName: item.name,
            estimatedMinutes: item.estimatedMinutes,
            isDone: false,
            isRecurring: true,
          ),
        ];
        changed = true;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _tasks = tasks;
    });
    if (changed) {
      unawaited(_saveTasks());
    }
  }

  Future<void> _saveTasks() {
    return widget.taskRepository.saveTodayTasks(_tasks);
  }

  Future<void> _completeLinkedZoneItem(CleaningTask task) async {
    final itemId = _zoneItemIdFromTask(task);
    if (itemId == null) {
      return;
    }

    final items = await widget.dataRepository.loadZoneItems();
    if (items == null) {
      return;
    }

    final index = items.indexWhere((item) => item.id == itemId);
    if (index == -1) {
      return;
    }

    final now = DateTime.now();
    final item = items[index];
    final updatedItem = item.copyWith(
      lastCleanedAt: now,
      nextDueAt: now.add(Duration(days: item.recurrenceDays)),
    );
    items[index] = updatedItem;
    await widget.dataRepository.saveZoneItems(items);

    final records = await widget.dataRepository.loadRecords();
    await widget.dataRepository.saveRecords([
      CleaningRecord(
        id: 'record-${now.microsecondsSinceEpoch}',
        title: '${item.name} 청소 완료',
        zoneName: item.name,
        completedAt: now,
        minutes: item.estimatedMinutes,
      ),
      ...(records ?? const <CleaningRecord>[]),
    ]);
  }

  String _scheduledTaskId(String itemId) => 'scheduled-zone-item-$itemId';

  String? _zoneItemIdFromTask(CleaningTask task) {
    const prefix = 'scheduled-zone-item-';
    if (!task.id.startsWith(prefix)) {
      return null;
    }

    return task.id.substring(prefix.length);
  }

  _FairyState _fairyState(int completedCount, int activeTaskCount) {
    if (activeTaskCount > 0 && completedCount == activeTaskCount) {
      return const _FairyState(
        assetPath: '캐릭터/청소요정_완료.png',
        title: '오늘의 반짝임 완성!',
        message: '모두 끝냈어요. 정말 멋지게 해냈어요!',
      );
    }
    if (completedCount == 0) {
      return const _FairyState(
        assetPath: '캐릭터/청소요정_시작.png',
        title: '가볍게 하나만 시작해요',
        message: '첫 체크를 기다리고 있을게요.',
      );
    }
    return _FairyState(
      assetPath: '캐릭터/청소요정_진행.png',
      title: '$completedCount개나 끝냈어요!',
      message: completedCount == 1
          ? '첫 반짝임 성공! 시작한 것부터 대단해요.'
          : '집도 마음도 조금씩 가벼워지고 있어요.',
    );
  }

  String _completionSnack(int completedCount) {
    const messages = [
      '첫 청소 완료! 아주 좋은 시작이에요.',
      '두 번째 반짝임까지 완료했어요!',
      '벌써 세 개예요. 오늘 정말 멋져요.',
      '깨끗해지는 만큼 마음도 가벼워져요.',
    ];
    final index = (completedCount - 1).clamp(0, messages.length - 1);
    return messages[index];
  }
}

class _FairyLabel extends StatelessWidget {
  const _FairyLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        '청소 요정의 응원',
        style: TextStyle(
          color: Color(0xFFB55567),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FairyState {
  const _FairyState({
    required this.assetPath,
    required this.title,
    required this.message,
  });

  final String assetPath;
  final String title;
  final String message;
}

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet();

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleController = TextEditingController();
  final _minutesController = TextEditingController(text: '10');
  String _zoneName = '주방';

  @override
  void dispose() {
    _titleController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('오늘 할 일 추가', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('오늘 생각난 청소를 바로 적어둘 수 있어요.'),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '할 일',
              hintText: '예: 분리수거 버리기',
            ),
          ),
          const SizedBox(height: 12),
          DropdownMenu<String>(
            width: double.infinity,
            initialSelection: _zoneName,
            label: const Text('구역'),
            dropdownMenuEntries: const [
              DropdownMenuEntry(value: '주방', label: '주방'),
              DropdownMenuEntry(value: '거실', label: '거실'),
              DropdownMenuEntry(value: '욕실', label: '욕실'),
              DropdownMenuEntry(value: '침실', label: '침실'),
              DropdownMenuEntry(value: '현관', label: '현관'),
              DropdownMenuEntry(value: '기타', label: '기타'),
            ],
            onSelected: (value) {
              if (value != null) {
                _zoneName = value;
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _minutesController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: '예상 시간(분)',
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submit,
            child: const Text('오늘 할 일에 추가'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    final minutes = int.tryParse(_minutesController.text.trim());
    if (title.isEmpty || minutes == null || minutes <= 0) {
      return;
    }

    Navigator.of(context).pop(
      CleaningTask(
        id: 'custom-task-${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        zoneName: _zoneName,
        estimatedMinutes: minutes,
        isDone: false,
        isRecurring: false,
      ),
    );
  }
}
