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
  List<String> get _steps {
    final itemSteps = widget.item?.steps ?? const [];
    if (itemSteps.isNotEmpty) {
      return itemSteps;
    }
    return _defaultSteps(widget.task);
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
                    Text(widget.task.zoneName),
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
            onPressed: _showCompletion,
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

  Future<void> _showCompletion() async {
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FairyImage(
                size: 126,
                assetPath: '캐릭터/청소요정_완료.png',
              ),
              const SizedBox(height: 16),
              Text(
                '한 곳을 반짝이게 만들었어요!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.task.title}을 해낸 오늘의 나, 정말 멋져요.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).pop(true);
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('뿌듯하게 마치기'),
                ),
              ),
            ],
          ),
        ),
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
      '충분히 환기됐다고 느껴지면 창문 상태를 다시 확인해요.',
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
