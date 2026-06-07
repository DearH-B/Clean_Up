import 'package:flutter/material.dart';

import '../models/cleaning_zone.dart';
import '../models/zone_item.dart';
import '../repositories/cleaning_data_repository.dart';
import '../widgets/fairy_image.dart';
import '../widgets/zone_card.dart';
import 'zone_detail_screen.dart';

class ZonesScreen extends StatefulWidget {
  const ZonesScreen({
    required this.dataRepository,
    super.key,
  });

  final CleaningDataRepository dataRepository;

  @override
  State<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends State<ZonesScreen> {
  late List<CleaningZone> _zones;
  late List<ZoneItem> _items;

  @override
  void initState() {
    super.initState();
    _zones = [];
    _items = [];
    _loadSavedData();
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
        if (_zones.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyZones(onAdd: _showAddZoneSheet),
          )
        else
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
                  final zone = _zoneWithProgress(_zones[index]);

                  return ZoneCard(
                    zone: zone,
                    index: index,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => ZoneDetailScreen(
                            zone: zone,
                            items: _items
                                .where((item) => item.zoneId == zone.id)
                                .toList(),
                            onItemsChanged: _updateZoneItems,
                            dataRepository: widget.dataRepository,
                          ),
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
    await widget.dataRepository.saveZones(_zones);
  }

  Future<void> _loadSavedData() async {
    final savedZones = await widget.dataRepository.loadZones();
    final savedItems = await widget.dataRepository.loadZoneItems();
    if (!mounted) {
      return;
    }

    setState(() {
      if (savedZones != null) {
        _zones = savedZones;
      }
      if (savedItems != null) {
        _items = savedItems;
      }
    });
  }

  void _updateZoneItems(String zoneId, List<ZoneItem> updatedItems) {
    setState(() {
      _items = [
        for (final item in _items)
          if (item.zoneId != zoneId) item,
        ...updatedItems,
      ];
    });
    widget.dataRepository.saveZoneItems(_items);
  }

  CleaningZone _zoneWithProgress(CleaningZone zone) {
    final zoneItems = _items.where((item) => item.zoneId == zone.id).toList();
    return zone.copyWith(
      taskCount: zoneItems.length,
      completedTaskCount:
          zoneItems.where((item) => item.lastCleanedAt != null).length,
    );
  }
}

class _EmptyZones extends StatelessWidget {
  const _EmptyZones({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 96),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_home_work_outlined,
            size: 54,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            '아직 등록한 구역이 없어요',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            '주방, 방1, 욕실처럼 내가 관리할 공간을 먼저 만들어 보세요.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('구역 추가'),
          ),
        ],
      ),
    );
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
  final _nameFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _nameFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
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
              focusNode: _nameFocusNode,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '구역 이름',
                hintText: '예: 방1',
              ),
              onSubmitted: (_) => _descriptionFocusNode.requestFocus(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              focusNode: _descriptionFocusNode,
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
