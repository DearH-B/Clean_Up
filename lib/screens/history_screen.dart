import 'package:flutter/material.dart';

import '../data/mock_cleaning_data.dart';
import '../widgets/fairy_image.dart';
import '../widgets/record_tile.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('기록', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  const Text('반짝인 순간들을 모아봤어요.'),
                ],
              ),
            ),
            const FairyImage(size: 64),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, size: 30),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이번 주 3번 청소했어요',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Text('총 45분 동안 집을 돌봤어요'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('최근 기록', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        for (final record in cleaningRecords) ...[
          RecordTile(record: record),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
