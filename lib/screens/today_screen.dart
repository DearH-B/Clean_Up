import 'dart:async';

import 'package:flutter/material.dart';

import '../models/cleaning_record.dart';
import '../models/cleaning_task.dart';
import '../models/zone_item.dart';
import '../repositories/cleaning_data_repository.dart';
import '../repositories/cleaning_task_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/fairy_image.dart';
import 'cleaning_session_screen.dart';

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
  final _scrollController = ScrollController();
  List<CleaningTask> _candidates = [];
  List<CleaningTask> _sessionTasks = [];
  Map<String, ZoneItem> _zoneItemsById = {};
  int? _selectedMinutes;
  _EnergyLevel _energyLevel = _EnergyLevel.normal;
  String _selectedZone = '아무 곳이나';
  int _recommendationOffset = 0;
  bool _isLoading = true;

  int get _completedCount => _sessionTasks.where((task) => task.isDone).length;

  bool get _isSessionComplete =>
      _sessionTasks.isNotEmpty && _completedCount == _sessionTasks.length;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCandidates());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Text('지금 청소', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          '시간이 생겼을 때, 부담 없는 만큼만 시작해요.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        _buildFairyPanel(context),
        const SizedBox(height: 24),
        Text(
          '지금 몇 분 정도 괜찮으세요?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          '밀린 청소 대신, 이 시간 안에 끝낼 수 있는 것만 골라드려요.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (final option in _timeOptions) ...[
              Expanded(
                child: _TimeOptionButton(
                  minutes: option.minutes,
                  label: option.label,
                  isSelected: _selectedMinutes == option.minutes,
                  onPressed: () => _selectDuration(option.minutes),
                ),
              ),
              if (option != _timeOptions.last) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 20),
        Text('오늘 체력은 어때요?', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        SegmentedButton<_EnergyLevel>(
          segments: const [
            ButtonSegment(
              value: _EnergyLevel.light,
              icon: Icon(Icons.spa_outlined),
              label: Text('가볍게'),
            ),
            ButtonSegment(
              value: _EnergyLevel.normal,
              icon: Icon(Icons.favorite_outline),
              label: Text('보통'),
            ),
            ButtonSegment(
              value: _EnergyLevel.strong,
              icon: Icon(Icons.bolt_outlined),
              label: Text('충분해요'),
            ),
          ],
          selected: {_energyLevel},
          onSelectionChanged: (selection) {
            setState(() {
              _energyLevel = selection.first;
              _refreshRecommendations();
            });
          },
        ),
        const SizedBox(height: 18),
        Text('신경 쓰이는 곳', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final zone in _zoneChoices) ...[
                ChoiceChip(
                  label: Text(zone),
                  selected: _selectedZone == zone,
                  onSelected: (_) {
                    setState(() {
                      _selectedZone = zone;
                      _refreshRecommendations();
                    });
                  },
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _showPlacePicker,
          icon: const Icon(Icons.home_work_outlined),
          label: const Text('장소에서 직접 고르기'),
        ),
        const SizedBox(height: 26),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_selectedMinutes == null && _sessionTasks.isEmpty)
          const _ReadyMessage()
        else
          _buildSession(context),
      ],
    );
  }

  Widget _buildFairyPanel(BuildContext context) {
    final state = _fairyState();
    return Container(
      height: 190,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.pinkSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -2,
            bottom: -18,
            child: FairyImage(size: 168, assetPath: state.assetPath),
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
                    width: 210,
                    child: Text(
                      state.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(width: 210, child: Text(state.message)),
                  if (_sessionTasks.isNotEmpty) ...[
                    const Spacer(),
                    SizedBox(
                      width: 180,
                      child: LinearProgressIndicator(
                        value: _completedCount / _sessionTasks.length,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSession(BuildContext context) {
    final totalMinutes = _sessionTasks.fold<int>(
      0,
      (sum, task) => sum + task.estimatedMinutes,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _isSessionComplete
                    ? '오늘 청소 끝!'
                    : '${_selectedMinutes ?? totalMinutes}분 추천 코스',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (!_isSessionComplete && _selectedMinutes != null)
              TextButton.icon(
                onPressed: _showAnotherRecommendation,
                icon: const Icon(Icons.refresh, size: 19),
                label: const Text('다른 추천'),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _isSessionComplete
              ? '계획보다 중요한 건 실제로 해낸 한 번이에요.'
              : '${_sessionTasks.length}개 · 약 $totalMinutes분 · 원할 때 멈춰도 괜찮아요',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        for (final task in _sessionTasks) ...[
          _CleaningSuggestionTile(
            task: task,
            reason: _recommendationReason(task),
            onToggle: () => _toggleTask(task),
            onStart: () => _startCleaning(task),
            onReplace: () => _replaceTask(task),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 4),
        if (_isSessionComplete)
          FilledButton.icon(
            onPressed: _finishSession,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('기분 좋게 마치기'),
          )
        else
          TextButton.icon(
            onPressed: _showAddTaskSheet,
            icon: const Icon(Icons.add),
            label: const Text('하고 싶은 청소 직접 추가'),
          ),
      ],
    );
  }

  Future<void> _loadCandidates() async {
    final savedTasks = await widget.taskRepository.loadTodayTasks() ?? [];
    final items = await widget.dataRepository.loadZoneItems() ?? [];
    final zones = await widget.dataRepository.loadZones() ?? [];
    final zoneNames = {for (final zone in zones) zone.id: zone.name};
    final now = DateTime.now();
    final itemsById = {for (final item in items) item.id: item};

    final itemTasks = <CleaningTask>[
      for (final item in items)
        if (item.isDue(now))
          CleaningTask(
            id: _scheduledTaskId(item.id),
            title: '${item.name} 청소',
            zoneName: zoneNames[item.zoneId] ?? item.name,
            estimatedMinutes: item.estimatedMinutes,
            isDone: false,
            isRecurring: true,
          ),
    ];

    if (!mounted) {
      return;
    }

    setState(() {
      _zoneItemsById = itemsById;
      _candidates = _deduplicateTasks([
        ...savedTasks.where(
          (task) =>
              !task.isDone &&
              !task.isPostponed &&
              _isStillAvailable(task, itemsById, now),
        ),
        ...itemTasks,
        ..._fallbackTasks,
      ]);
      _isLoading = false;
    });
  }

  void _selectDuration(int minutes) {
    setState(() {
      _selectedMinutes = minutes;
      _recommendationOffset = 0;
      _sessionTasks = _recommendTasks(minutes, 0);
    });
    _scrollToSession();
  }

  List<CleaningTask> _recommendTasks(int minutes, int offset) {
    final available = _candidates
        .where(
          (task) =>
              !task.isDone &&
              task.estimatedMinutes <= _maximumTaskMinutes(minutes) &&
              (_selectedZone == '아무 곳이나' ||
                  task.zoneName == _selectedZone ||
                  task.zoneName == '집 전체'),
        )
        .toList()
      ..sort((a, b) {
        final scoreComparison = _recommendationScore(
          b,
        ).compareTo(_recommendationScore(a));
        if (scoreComparison != 0) {
          return scoreComparison;
        }
        if (a.isRecurring != b.isRecurring) {
          return a.isRecurring ? -1 : 1;
        }
        return a.estimatedMinutes.compareTo(b.estimatedMinutes);
      });

    if (available.isEmpty) {
      return [];
    }

    final rotated = [
      ...available.skip(offset % available.length),
      ...available.take(offset % available.length),
    ];
    final selected = <CleaningTask>[];
    var remaining = minutes;

    for (final task in rotated) {
      if (task.estimatedMinutes <= remaining && selected.length < 3) {
        selected.add(task.copyWith(isDone: false));
        remaining -= task.estimatedMinutes;
      }
    }

    return selected.isEmpty
        ? [rotated.first.copyWith(isDone: false)]
        : selected;
  }

  int _maximumTaskMinutes(int selectedMinutes) {
    return switch (_energyLevel) {
      _EnergyLevel.light => (selectedMinutes * 0.6).ceil(),
      _EnergyLevel.normal => selectedMinutes,
      _EnergyLevel.strong => selectedMinutes,
    };
  }

  int _recommendationScore(CleaningTask task) {
    var score = 0;
    if (task.isRecurring) {
      score += 30;
    }
    if (_selectedZone != '아무 곳이나' && task.zoneName == _selectedZone) {
      score += 25;
    }
    final itemId = _zoneItemIdFromTask(task);
    final item = itemId == null ? null : _zoneItemsById[itemId];
    if (item?.hasProductInfo ?? false) {
      score += 15;
    }
    if (_energyLevel == _EnergyLevel.light && task.estimatedMinutes <= 5) {
      score += 20;
    }
    if (_energyLevel == _EnergyLevel.strong && task.estimatedMinutes >= 10) {
      score += 10;
    }
    return score;
  }

  String _recommendationReason(CleaningTask task) {
    final itemId = _zoneItemIdFromTask(task);
    final item = itemId == null ? null : _zoneItemsById[itemId];
    if (item?.lastCleanedAt != null) {
      final days = DateTime.now().difference(item!.lastCleanedAt!).inDays;
      return '마지막 청소 후 $days일이 지났어요';
    }
    if (item?.hasProductInfo ?? false) {
      return '등록한 ${item!.manufacturer ?? '제품'} 관리 시기를 참고했어요';
    }
    if (task.isRecurring) {
      return '평소 관리 주기를 참고했어요';
    }
    if (_selectedZone != '아무 곳이나' && task.zoneName == _selectedZone) {
      return '지금 신경 쓰이는 장소와 잘 맞아요';
    }
    return _energyLevel == _EnergyLevel.light
        ? '체력 부담이 적은 짧은 청소예요'
        : '선택한 시간 안에 끝내기 좋아요';
  }

  void _refreshRecommendations() {
    final minutes = _selectedMinutes;
    if (minutes == null) {
      return;
    }
    _recommendationOffset = 0;
    _sessionTasks = _recommendTasks(minutes, 0);
  }

  void _showAnotherRecommendation() {
    final minutes = _selectedMinutes;
    if (minutes == null) {
      return;
    }
    setState(() {
      _recommendationOffset++;
      _sessionTasks = _recommendTasks(minutes, _recommendationOffset);
    });
  }

  void _replaceTask(CleaningTask task) {
    final minutes = _selectedMinutes ??
        _sessionTasks.fold<int>(
          0,
          (sum, candidate) => sum + candidate.estimatedMinutes,
        );
    final currentIds = _sessionTasks.map((candidate) => candidate.id).toSet();
    final replacements = _candidates
        .where(
          (candidate) =>
              !candidate.isDone &&
              !currentIds.contains(candidate.id) &&
              candidate.estimatedMinutes <=
                  (task.estimatedMinutes + 5).clamp(1, minutes) &&
              (_selectedZone == '아무 곳이나' ||
                  candidate.zoneName == _selectedZone ||
                  candidate.zoneName == '집 전체'),
        )
        .toList()
      ..sort(
        (a, b) => _recommendationScore(b).compareTo(_recommendationScore(a)),
      );

    if (replacements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지금 조건에 맞는 다른 청소가 없어요.')),
      );
      return;
    }

    final index =
        _sessionTasks.indexWhere((candidate) => candidate.id == task.id);
    setState(() {
      _sessionTasks[index] = replacements.first.copyWith(isDone: false);
    });
  }

  Future<void> _startCleaning(CleaningTask task) async {
    final itemId = _zoneItemIdFromTask(task);
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CleaningSessionScreen(
          task: task,
          item: itemId == null ? null : _zoneItemsById[itemId],
        ),
      ),
    );

    if (completed == true && mounted && !task.isDone) {
      await _toggleTask(task);
    }
  }

  Future<void> _showPlacePicker() async {
    final task = await showModalBottomSheet<CleaningTask>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final grouped = <String, List<CleaningTask>>{};
        for (final candidate in _candidates.where((task) => !task.isDone)) {
          grouped.putIfAbsent(candidate.zoneName, () => []).add(candidate);
        }

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Text(
                '어디를 가볍게 치워볼까요?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text('하나만 골라도 충분해요.'),
              const SizedBox(height: 14),
              for (final entry in grouped.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                for (final item in entry.value)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cleaning_services_outlined),
                    title: Text(item.title),
                    subtitle: Text('약 ${item.estimatedMinutes}분'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).pop(item),
                  ),
              ],
            ],
          ),
        );
      },
    );

    if (task == null || !mounted) {
      return;
    }

    setState(() {
      _selectedMinutes = null;
      _sessionTasks = [task.copyWith(isDone: false)];
    });
    _scrollToSession();
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
      _candidates = _deduplicateTasks([..._candidates, task]);
      _sessionTasks = [..._sessionTasks, task];
    });
    unawaited(_saveUserCandidates());
  }

  Future<void> _toggleTask(CleaningTask task) async {
    final index =
        _sessionTasks.indexWhere((candidate) => candidate.id == task.id);
    if (index == -1) {
      return;
    }

    final willComplete = !task.isDone;
    setState(() {
      _sessionTasks[index] = task.copyWith(isDone: willComplete);
      final candidateIndex =
          _candidates.indexWhere((candidate) => candidate.id == task.id);
      if (candidateIndex != -1) {
        _candidates[candidateIndex] =
            _candidates[candidateIndex].copyWith(isDone: willComplete);
      }
    });

    unawaited(_saveUserCandidates());
    if (willComplete) {
      await _recordCompletion(task);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_completionSnack(_completedCount))),
        );
      }
    }
  }

  Future<void> _recordCompletion(CleaningTask task) async {
    final now = DateTime.now();
    final itemId = _zoneItemIdFromTask(task);
    final item = itemId == null ? null : _zoneItemsById[itemId];

    if (item != null) {
      final items = await widget.dataRepository.loadZoneItems() ?? [];
      final index = items.indexWhere((candidate) => candidate.id == item.id);
      if (index != -1) {
        items[index] = item.copyWith(
          lastCleanedAt: now,
          nextDueAt: now.add(Duration(days: item.recurrenceDays)),
        );
        await widget.dataRepository.saveZoneItems(items);
      }
    }

    final records = await widget.dataRepository.loadRecords() ?? [];
    await widget.dataRepository.saveRecords([
      CleaningRecord(
        id: 'record-${now.microsecondsSinceEpoch}',
        title: '${task.title} 완료',
        zoneName: task.zoneName,
        completedAt: now,
        minutes: task.estimatedMinutes,
      ),
      ...records,
    ]);
  }

  void _finishSession() {
    setState(() {
      _selectedMinutes = null;
      _sessionTasks = [];
      _recommendationOffset = 0;
    });
  }

  void _scrollToSession() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _saveUserCandidates() {
    final persistable = _candidates
        .where((task) => !_fallbackTaskIds.contains(task.id))
        .toList();
    return widget.taskRepository.saveTodayTasks(persistable);
  }

  List<CleaningTask> _deduplicateTasks(List<CleaningTask> tasks) {
    final seen = <String>{};
    return [
      for (final task in tasks)
        if (seen.add(task.id)) task,
    ];
  }

  String _scheduledTaskId(String itemId) => 'scheduled-zone-item-$itemId';

  String? _zoneItemIdFromTask(CleaningTask task) {
    const prefix = 'scheduled-zone-item-';
    return task.id.startsWith(prefix) ? task.id.substring(prefix.length) : null;
  }

  bool _isStillAvailable(
    CleaningTask task,
    Map<String, ZoneItem> itemsById,
    DateTime now,
  ) {
    final itemId = _zoneItemIdFromTask(task);
    if (itemId == null) {
      return true;
    }
    final item = itemsById[itemId];
    return item != null && item.isDue(now);
  }

  _FairyState _fairyState() {
    if (_isSessionComplete) {
      return const _FairyState(
        assetPath: '캐릭터/청소요정_완료.png',
        title: '이만큼이면 충분해요!',
        message: '오늘 생긴 여유를 반짝이는 공간으로 바꿨어요.',
      );
    }
    if (_completedCount > 0) {
      return _FairyState(
        assetPath: '캐릭터/청소요정_진행.png',
        title: '$_completedCount개나 끝냈어요!',
        message: '한 번 시작한 것만으로도 이미 멋진 변화예요.',
      );
    }
    if (_sessionTasks.isNotEmpty) {
      return const _FairyState(
        assetPath: '캐릭터/청소요정_시작.png',
        title: '딱 하나부터 시작해요',
        message: '전부 하지 않아도 괜찮아요. 마음 가는 것부터!',
      );
    }
    return const _FairyState(
      assetPath: '캐릭터/귀여운 분홍새.png',
      title: '시간이 조금 생겼나요?',
      message: '가능한 시간만 알려주면 가볍게 골라드릴게요.',
    );
  }

  String _completionSnack(int completedCount) {
    const messages = [
      '첫 번째 반짝임 완료! 시작한 마음이 제일 대단해요.',
      '두 곳이나 가벼워졌어요. 오늘 정말 잘했어요.',
      '벌써 세 개나 끝냈어요! 이제 쉬어도 충분해요.',
    ];
    return messages[(completedCount - 1).clamp(0, messages.length - 1)];
  }
}

class _TimeOptionButton extends StatelessWidget {
  const _TimeOptionButton({
    required this.minutes,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final int minutes;
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: isSelected
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(padding: EdgeInsets.zero),
              child: _content(context),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
              child: _content(context),
            ),
    );
  }

  Widget _content(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$minutes분',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _ReadyMessage extends StatelessWidget {
  const _ReadyMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: const Column(
        children: [
          Icon(Icons.timer_outlined, size: 34, color: AppColors.rose),
          SizedBox(height: 10),
          Text(
            '아직 정해진 할 일은 없어요',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 5),
          Text(
            '시간을 고르는 순간, 지금 할 청소만 나타나요.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CleaningSuggestionTile extends StatelessWidget {
  const _CleaningSuggestionTile({
    required this.task,
    required this.reason,
    required this.onToggle,
    required this.onStart,
    required this.onReplace,
  });

  final CleaningTask task;
  final String reason;
  final VoidCallback onToggle;
  final VoidCallback onStart;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: task.isDone
                        ? AppColors.pinkSoft
                        : Theme.of(context).colorScheme.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    task.isDone
                        ? Icons.check_rounded
                        : Icons.cleaning_services_outlined,
                    color: task.isDone
                        ? AppColors.rose
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          decoration:
                              task.isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${task.zoneName} · 약 ${task.estimatedMinutes}분',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Checkbox(value: task.isDone, onChanged: (_) => onToggle()),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 16),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      reason,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            if (!task.isDone) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onReplace,
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('교체'),
                  ),
                  const SizedBox(width: 4),
                  FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow, size: 19),
                    label: const Text('시작'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
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
        '청소 요정의 추천',
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
    return SingleChildScrollView(
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
          Text('하고 싶은 청소 추가', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('지금 떠오른 청소를 이번 코스에만 가볍게 더해요.'),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '할 일',
              hintText: '예: 분리수거 버리기',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in _taskPresets)
                ActionChip(
                  label: Text(preset.title),
                  onPressed: () => _pickTaskPreset(preset),
                ),
            ],
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
            decoration: const InputDecoration(labelText: '예상 시간(분)'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submit,
            child: const Text('이번 청소에 추가'),
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
      ),
    );
  }

  void _pickTaskPreset(_TaskPreset preset) {
    setState(() {
      _titleController.text = preset.title;
      _zoneName = preset.zoneName;
      _minutesController.text = '${preset.minutes}';
    });
  }
}

class _TimeOption {
  const _TimeOption(this.minutes, this.label);

  final int minutes;
  final String label;
}

class _TaskPreset {
  const _TaskPreset(this.title, this.zoneName, this.minutes);

  final String title;
  final String zoneName;
  final int minutes;
}

enum _EnergyLevel { light, normal, strong }

const _timeOptions = [
  _TimeOption(5, '아주 가볍게'),
  _TimeOption(15, '한 곳 산뜻하게'),
  _TimeOption(30, '제대로 한 번'),
];

const _zoneChoices = ['아무 곳이나', '주방', '거실', '욕실', '침실', '현관'];

const _taskPresets = [
  _TaskPreset('분리수거 버리기', '현관', 7),
  _TaskPreset('창문 열고 환기', '기타', 5),
  _TaskPreset('바닥 청소기 돌리기', '거실', 15),
  _TaskPreset('싱크대 주변 닦기', '주방', 8),
  _TaskPreset('욕실 세면대 닦기', '욕실', 8),
];

const _fallbackTasks = [
  CleaningTask(
    id: 'fallback-ventilate',
    title: '창문 열고 환기하기',
    zoneName: '집 전체',
    estimatedMinutes: 5,
    isDone: false,
  ),
  CleaningTask(
    id: 'fallback-sink',
    title: '싱크대 주변 물기 닦기',
    zoneName: '주방',
    estimatedMinutes: 5,
    isDone: false,
  ),
  CleaningTask(
    id: 'fallback-table',
    title: '테이블 위 물건 제자리 두기',
    zoneName: '거실',
    estimatedMinutes: 5,
    isDone: false,
  ),
  CleaningTask(
    id: 'fallback-vacuum',
    title: '자주 걷는 곳만 청소기 돌리기',
    zoneName: '거실',
    estimatedMinutes: 10,
    isDone: false,
  ),
  CleaningTask(
    id: 'fallback-washbasin',
    title: '세면대와 수전 닦기',
    zoneName: '욕실',
    estimatedMinutes: 8,
    isDone: false,
  ),
  CleaningTask(
    id: 'fallback-bed',
    title: '침구 정리하고 주변 환기하기',
    zoneName: '침실',
    estimatedMinutes: 10,
    isDone: false,
  ),
  CleaningTask(
    id: 'fallback-floor',
    title: '바닥 청소기 돌리기',
    zoneName: '집 전체',
    estimatedMinutes: 15,
    isDone: false,
  ),
];

const _fallbackTaskIds = {
  'fallback-ventilate',
  'fallback-sink',
  'fallback-table',
  'fallback-vacuum',
  'fallback-washbasin',
  'fallback-bed',
  'fallback-floor',
};
