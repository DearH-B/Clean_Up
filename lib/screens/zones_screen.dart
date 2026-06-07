import 'package:flutter/material.dart';

import '../data/mock_cleaning_data.dart';
import '../models/cleaning_zone.dart';
import '../widgets/fairy_image.dart';
import '../widgets/zone_card.dart';
import 'zone_detail_screen.dart';

class ZonesScreen extends StatefulWidget {
  const ZonesScreen({super.key});

  @override
  State<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends State<ZonesScreen> {
  late final List<CleaningZone> _zones;

  @override
  void initState() {
    super.initState();
    _zones = cleaningZones.toList();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '구역',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      const Text('청소할 공간을 골라볼까요?'),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _showAddZoneSheet,
                  tooltip: '구역 추가',
                  icon: const Icon(Icons.add_home_work_outlined),
                ),
                const SizedBox(width: 8),
                const FairyImage(size: 58),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 190,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final zone = _zones[index];

                return ZoneCard(
                  zone: zone,
                  index: index,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => ZoneDetailScreen(zone: zone),
                      ),
                    );
                  },
                );
              },
              childCount: _zones.length,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddZoneSheet() async {
    final zone = await showModalBottomSheet<CleaningZone>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _AddZoneSheet(),
    );

    if (zone == null || !mounted) {
      return;
    }

    setState(() {
      _zones.add(zone);
    });
  }
}

class _AddZoneSheet extends StatefulWidget {
  const _AddZoneSheet();

  @override
  State<_AddZoneSheet> createState() => _AddZoneSheetState();
}

class _AddZoneSheetState extends State<_AddZoneSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
          Text('새 구역 추가', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('방1, 방2, 베란다처럼 우리 집 구조에 맞춰 만들어요.'),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '구역 이름',
              hintText: '예: 방1',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: '구역 설명',
              hintText: '예: 책상, 침대, 옷장',
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submit,
            child: const Text('구역 추가'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    if (name.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      CleaningZone(
        id: 'custom-zone-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        description: description.isEmpty ? '새로 추가한 청소 구역' : description,
        taskCount: 0,
        completedTaskCount: 0,
      ),
    );
  }
}
