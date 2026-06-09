import 'package:flutter/material.dart';

import '../models/care_record.dart';
import '../repositories/product_data_repository.dart';
import '../widgets/fairy_image.dart';
import '../widgets/record_tile.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    required this.dataRepository,
    super.key,
  });

  final ProductDataRepository dataRepository;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late List<CareRecord> _records;

  @override
  void initState() {
    super.initState();
    _records = [];
    _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    final totalMinutes = _records.fold<int>(
      0,
      (sum, record) => sum + record.minutes,
    );

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
                  const Text('제품을 돌본 기록을 모아봤어요.'),
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
                    '관리 기록 ${_records.length}개',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('총 $totalMinutes분 동안 제품을 관리했어요'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('최근 기록', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (_records.isEmpty)
          const _EmptyHistory()
        else
          for (final record in _records) ...[
            RecordTile(record: record),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  Future<void> _loadRecords() async {
    final savedRecords = await widget.dataRepository.loadCareRecords();
    if (!mounted || savedRecords == null) {
      return;
    }

    setState(() {
      _records = savedRecords;
    });
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(
              Icons.history_toggle_off_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 10),
            Text(
              '아직 관리 기록이 없어요',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              '제품 상세에서 관리를 완료하면 자동으로 기록돼요.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
