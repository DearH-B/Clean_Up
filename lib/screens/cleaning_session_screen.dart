import 'dart:async';

import 'package:flutter/material.dart';

import '../models/cleaning_task.dart';
import '../models/zone_item.dart';
import '../theme/app_theme.dart';
import '../widgets/fairy_image.dart';

class CleaningSessionScreen extends StatefulWidget {
  const CleaningSessionScreen({
    required this.task,
    this.item,
    super.key,
  });

  final CleaningTask task;
  final ZoneItem? item;

  @override
  State<CleaningSessionScreen> createState() => _CleaningSessionScreenState();
}

class _CleaningSessionScreenState extends State<CleaningSessionScreen> {
  Timer? _timer;
  late int _remainingSeconds;
  bool _isRunning = false;

  int get _totalSeconds => widget.task.estimatedMinutes * 60;

  List<String> get _steps {
    final itemSteps = widget.item?.steps ?? const [];
    if (itemSteps.isNotEmpty) {
      return itemSteps;
    }
    return _defaultSteps(widget.task);
  }

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _totalSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      appBar: AppBar(title: const Text('청소 시작')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FairyImage(
                size: 82,
                assetPath: '캐릭터/청소요정_진행.png',
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.task.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${widget.task.zoneName} · 약 ${widget.task.estimatedMinutes}분',
                    ),
                    if (item?.hasProductInfo ?? false) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${item!.manufacturer ?? ''} ${item.modelName ?? ''}'
                            .trim(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _TimerPanel(
            remainingSeconds: _remainingSeconds,
            totalSeconds: _totalSeconds,
            isRunning: _isRunning,
            onToggle: _toggleTimer,
            onReset: _resetTimer,
          ),
          if (item?.supplies.isNotEmpty ?? false) ...[
            const SizedBox(height: 24),
            Text('준비물', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final supply in item!.supplies) Chip(label: Text(supply)),
              ],
            ),
          ],
          if (item?.cautions.isNotEmpty ?? false) ...[
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF3DCE1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_outlined, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '먼저 확인하세요',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final caution in item!.cautions.take(2))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text('• $caution'),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text('이 순서로 해봐요', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (var index = 0; index < _steps.length; index++)
            _StepRow(number: index + 1, text: _steps[index]),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.check_rounded),
            label: const Text('청소 완료'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('오늘은 여기까지만'),
          ),
        ],
      ),
    );
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() {
        _isRunning = false;
      });
      return;
    }

    if (_remainingSeconds == 0) {
      _remainingSeconds = _totalSeconds;
    }
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
        });
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _totalSeconds;
      _isRunning = false;
    });
  }
}

class _TimerPanel extends StatelessWidget {
  const _TimerPanel({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isRunning,
    required this.onToggle,
    required this.onReset,
  });

  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final VoidCallback onToggle;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    final progress =
        totalSeconds == 0 ? 0.0 : 1 - (remainingSeconds / totalSeconds);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.pinkSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '$minutes:$seconds',
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: onToggle,
                icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(isRunning ? '잠시 멈춤' : '타이머 시작'),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: '타이머 초기화',
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.pinkSoft,
            foregroundColor: AppColors.rose,
            child: Text(
              '$number',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(text),
            ),
          ),
        ],
      ),
    );
  }
}

List<String> _defaultSteps(CleaningTask task) {
  final title = task.title;
  if (title.contains('환기')) {
    return const [
      '가까운 창문을 열고 공기가 통할 길을 만들어요.',
      '주변에 넘어질 물건이 없는지 가볍게 정리해요.',
      '타이머가 끝나면 창문 상태를 다시 확인해요.',
    ];
  }
  if (title.contains('싱크대') || title.contains('세면대')) {
    return const [
      '표면 위 물건과 눈에 보이는 찌꺼기를 치워요.',
      '부드러운 천이나 수세미로 자주 닿는 곳부터 닦아요.',
      '깨끗한 물로 헹구고 마른 천으로 물기를 제거해요.',
    ];
  }
  if (title.contains('청소기') || title.contains('바닥')) {
    return const [
      '바닥에 놓인 큰 물건만 잠시 올려둬요.',
      '자주 걷는 동선부터 청소기를 천천히 움직여요.',
      '눈에 띄는 모서리 한 곳까지 정리하고 마쳐요.',
    ];
  }
  return const [
    '청소할 범위를 작게 정하고 필요한 도구를 준비해요.',
    '가장 눈에 띄는 곳부터 한 방향으로 정리해요.',
    '도구를 제자리에 두고 달라진 공간을 확인해요.',
  ];
}
