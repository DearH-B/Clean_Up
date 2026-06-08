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
            child: _InitialZoneSetup(onCreate: _createPresetZones),
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
                    onTap: () => _openZone(zone),
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
    if (mounted) {
      _openZone(zone, startWithAddItem: true);
    }
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

  Future<void> _createPresetZones(List<_ZonePreset> presets) async {
    if (presets.isEmpty) {
      return;
    }

    final createdZones = [
      for (final preset in presets)
        CleaningZone(
          id: 'custom-zone-${preset.name}-${DateTime.now().microsecondsSinceEpoch}',
          name: preset.name,
          description: preset.description,
          taskCount: 0,
          completedTaskCount: 0,
        ),
    ];

    setState(() {
      _zones.addAll(createdZones);
    });
    await widget.dataRepository.saveZones(_zones);

    if (mounted && createdZones.length == 1) {
      _openZone(createdZones.first, startWithAddItem: true);
    }
  }

  void _openZone(
    CleaningZone zone, {
    bool startWithAddItem = false,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ZoneDetailScreen(
          zone: zone,
          items: _items.where((item) => item.zoneId == zone.id).toList(),
          onItemsChanged: _updateZoneItems,
          dataRepository: widget.dataRepository,
          startWithAddItem: startWithAddItem,
        ),
      ),
    );
  }
}

class _InitialZoneSetup extends StatefulWidget {
  const _InitialZoneSetup({required this.onCreate});

  final ValueChanged<List<_ZonePreset>> onCreate;

  @override
  State<_InitialZoneSetup> createState() => _InitialZoneSetupState();
}

class _InitialZoneSetupState extends State<_InitialZoneSetup> {
  final Set<_ZonePreset> _selectedPresets = {
    _zonePresets[0],
    _zonePresets[1],
    _zonePresets[2],
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 96),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Icon(
              Icons.add_home_work_outlined,
              size: 54,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '먼저 집 구조를 골라볼까요?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            '자주 청소하는 공간을 선택하면 바로 시작할 수 있어요.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final preset in _zonePresets)
                FilterChip(
                  label: Text(preset.name),
                  selected: _selectedPresets.contains(preset),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedPresets.add(preset);
                      } else {
                        _selectedPresets.remove(preset);
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: _selectedPresets.isEmpty
                ? null
                : () => widget.onCreate(_selectedPresets.toList()),
            icon: const Icon(Icons.check_rounded),
            label: const Text('선택한 구역 만들기'),
          ),
        ],
      ),
    );
  }
}

class _ZonePreset {
  const _ZonePreset({
    required this.name,
    required this.description,
  });

  final String name;
  final String description;
}

const _zonePresets = [
  _ZonePreset(name: '주방', description: '싱크대, 조리대, 냉장고 앞 공간'),
  _ZonePreset(name: '거실', description: '소파, 테이블, 바닥, 창가'),
  _ZonePreset(name: '욕실', description: '세면대, 변기, 샤워부스'),
  _ZonePreset(name: '침실', description: '침구, 옷장 주변, 협탁'),
  _ZonePreset(name: '방1', description: '책상, 침대, 옷장'),
  _ZonePreset(name: '방2', description: '새로 추가한 청소 구역'),
  _ZonePreset(name: '베란다', description: '창틀, 바닥, 세탁 공간'),
  _ZonePreset(name: '현관', description: '신발장, 바닥, 문 주변'),
];

class _AddZoneSheet extends StatefulWidget {
  const _AddZoneSheet();

  @override
  State<_AddZoneSheet> createState() => _AddZoneSheetState();
}

class _AddZoneSheetState extends State<_AddZoneSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _descriptionFocusNode = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in const ['주방', '거실', '욕실', '침실', '방1', '방2'])
                  ActionChip(
                    label: Text(preset),
                    onPressed: () => _pickPreset(preset),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.text,
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

  void _pickPreset(String name) {
    setState(() {
      _nameController.text = name;
      _descriptionController.text = switch (name) {
        '주방' => '싱크대, 조리대, 냉장고 앞 공간',
        '거실' => '소파, 테이블, 바닥, 창가',
        '욕실' => '세면대, 변기, 샤워부스',
        '침실' => '침구, 옷장 주변, 협탁',
        _ => '새로 추가한 청소 구역',
      };
    });
  }
}
