import 'package:flutter/material.dart';

import '../models/cleaning_zone.dart';
import '../models/zone_item.dart';
import '../repositories/cleaning_data_repository.dart';
import '../widgets/zone_item_tile.dart';
import 'zone_item_detail_screen.dart';

class ZoneDetailScreen extends StatefulWidget {
  const ZoneDetailScreen({
    required this.zone,
    required this.items,
    required this.onItemsChanged,
    required this.dataRepository,
    this.startWithAddItem = false,
    super.key,
  });

  final CleaningZone zone;
  final List<ZoneItem> items;
  final void Function(String zoneId, List<ZoneItem> items) onItemsChanged;
  final CleaningDataRepository dataRepository;
  final bool startWithAddItem;

  @override
  State<ZoneDetailScreen> createState() => _ZoneDetailScreenState();
}

class _ZoneDetailScreenState extends State<ZoneDetailScreen> {
  late List<ZoneItem> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.items.toList();
    if (widget.startWithAddItem) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showAddItemSheet();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.zone.name)),
      body: _items.isEmpty
          ? _EmptyZone(
              zoneName: widget.zone.name,
              onAdd: _showAddItemSheet,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                Text(
                  '${widget.zone.name}의 가전과 가구',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  '항목을 선택하면 준비물과 단계별 청소법을 볼 수 있어요.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                for (final item in _items) ...[
                  ZoneItemTile(
                    item: item,
                    onTap: () => _openItem(item),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemSheet,
        icon: const Icon(Icons.add),
        label: const Text('항목 추가'),
      ),
    );
  }

  void _openItem(ZoneItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ZoneItemDetailScreen(
          item: item,
          dataRepository: widget.dataRepository,
          onItemUpdated: (updatedItem) {
            final index = _items.indexWhere(
              (candidate) => candidate.id == updatedItem.id,
            );
            if (index == -1 || !mounted) {
              return;
            }
            setState(() {
              _items[index] = updatedItem;
            });
            widget.onItemsChanged(widget.zone.id, _items);
          },
        ),
      ),
    );
  }

  Future<void> _showAddItemSheet() async {
    final item = await showModalBottomSheet<ZoneItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _AddZoneItemSheet(zoneId: widget.zone.id),
    );

    if (item == null || !mounted) {
      return;
    }

    setState(() {
      _items.add(item);
    });
    widget.onItemsChanged(widget.zone.id, _items);
  }
}

class _EmptyZone extends StatelessWidget {
  const _EmptyZone({
    required this.zoneName,
    required this.onAdd,
  });

  final String zoneName;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '$zoneName에 등록된 항목이 없어요',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('자주 청소하는 가전이나 가구를 추가해 보세요.'),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('첫 항목 추가'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddZoneItemSheet extends StatefulWidget {
  const _AddZoneItemSheet({required this.zoneId});

  final String zoneId;

  @override
  State<_AddZoneItemSheet> createState() => _AddZoneItemSheetState();
}

class _AddZoneItemSheetState extends State<_AddZoneItemSheet> {
  final _nameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _modelController = TextEditingController();
  final _minutesController = TextEditingController(text: '10');
  ZoneItemType _selectedType = ZoneItemType.appliance;
  int _recurrenceDays = 7;
  bool _addProductInfo = false;

  @override
  void dispose() {
    _nameController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _minutesController.dispose();
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
            Text(
              '가전 또는 가구 추가',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.category_outlined),
                  label: Text('일반 항목'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.qr_code_2),
                  label: Text('제품 등록'),
                ),
              ],
              selected: {_addProductInfo},
              onSelectionChanged: (selection) {
                setState(() {
                  _addProductInfo = selection.first;
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              _addProductInfo
                  ? '브랜드나 모델명을 알고 있다면 함께 등록해요.'
                  : '제품 정보를 몰라도 냉장고처럼 종류만 등록할 수 있어요.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in _itemPresets)
                  ActionChip(
                    label: Text(preset.name),
                    onPressed: () => _pickItemPreset(preset),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '항목 이름',
                hintText: '예: 냉장고',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownMenu<ZoneItemType>(
              width: double.infinity,
              initialSelection: _selectedType,
              label: const Text('종류'),
              dropdownMenuEntries: [
                for (final type in ZoneItemType.values)
                  DropdownMenuEntry(value: type, label: type.label),
              ],
              onSelected: (type) {
                if (type != null) {
                  setState(() {
                    _selectedType = type;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownMenu<int>(
              width: double.infinity,
              initialSelection: _recurrenceDays,
              label: const Text('청소 주기'),
              dropdownMenuEntries: const [
                DropdownMenuEntry(value: 1, label: '매일'),
                DropdownMenuEntry(value: 7, label: '매주'),
                DropdownMenuEntry(value: 14, label: '2주마다'),
                DropdownMenuEntry(value: 30, label: '한 달마다'),
                DropdownMenuEntry(value: 90, label: '3개월마다'),
              ],
              onSelected: (days) {
                if (days != null) {
                  setState(() {
                    _recurrenceDays = days;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _minutesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '예상 시간(분)',
                hintText: '예: 10',
              ),
            ),
            if (_addProductInfo) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _manufacturerController,
                decoration: const InputDecoration(
                  labelText: '브랜드 또는 제조사',
                  hintText: '예: 삼성전자',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _modelController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: '모델명',
                  hintText: '제품 라벨에 적힌 모델명',
                ),
                onSubmitted: (_) => _submit(),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submit,
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    final manufacturer = _manufacturerController.text.trim();
    final modelName = _modelController.text.trim();
    final minutes = int.tryParse(_minutesController.text.trim()) ?? 10;
    final now = DateTime.now();

    Navigator.of(context).pop(
      ZoneItem(
        id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
        zoneId: widget.zoneId,
        name: name,
        type: _selectedType,
        summary: '$name 청소를 시작하기 전에 제품 재질과 설명서를 확인하세요.',
        frequency: _frequencyLabel(_recurrenceDays),
        estimatedMinutes: minutes,
        recurrenceDays: _recurrenceDays,
        nextDueAt: now,
        supplies: const ['부드러운 천', '중성세제'],
        cautions: const [
          '가전은 전원을 분리하고, 제품별 사용설명서를 우선 확인하세요.',
          '세제를 눈에 띄지 않는 곳에 먼저 시험하세요.',
        ],
        steps: [
          '$name 주변의 물건과 먼지를 먼저 정리해요.',
          '제품 재질에 맞는 도구와 중성세제로 오염을 닦아요.',
          '깨끗한 천으로 세제와 물기를 제거해요.',
          '충분히 건조한 뒤 원래 위치에 정리해요.',
        ],
        manufacturer:
            _addProductInfo && manufacturer.isNotEmpty ? manufacturer : null,
        modelName: _addProductInfo && modelName.isNotEmpty ? modelName : null,
        guideStatus: _addProductInfo
            ? '등록된 제품 정보를 바탕으로 공식 안내를 확인할 수 있어요.'
            : '브랜드와 모델명이 없어 일반적인 관리 방법을 안내해요.',
        guideBasis: _addProductInfo
            ? '동일 모델 자료가 없으면 같은 브랜드 또는 유사 제품군을 참고해 안내해요.'
            : '제품군에 공통으로 적용되는 일반 관리법이에요.',
        guideSourceType: _addProductInfo
            ? GuideSourceType.similarProduct
            : GuideSourceType.general,
        recommendedSupplies: const [
          '표면 손상을 줄이는 부드러운 극세사 천',
          '재질에 맞는 중성세제',
          '좁은 부분을 위한 부드러운 틈새 솔',
        ],
      ),
    );
  }

  String _frequencyLabel(int days) {
    return switch (days) {
      1 => '매일',
      7 => '매주',
      14 => '2주마다',
      30 => '한 달마다',
      90 => '3개월마다',
      _ => '$days일마다',
    };
  }

  void _pickItemPreset(_ItemPreset preset) {
    setState(() {
      _nameController.text = preset.name;
      _selectedType = preset.type;
      _recurrenceDays = preset.recurrenceDays;
      _minutesController.text = '${preset.estimatedMinutes}';
      _addProductInfo = false;
      _manufacturerController.clear();
      _modelController.clear();
    });
  }
}

class _ItemPreset {
  const _ItemPreset({
    required this.name,
    required this.type,
    required this.recurrenceDays,
    required this.estimatedMinutes,
  });

  final String name;
  final ZoneItemType type;
  final int recurrenceDays;
  final int estimatedMinutes;
}

const _itemPresets = [
  _ItemPreset(
    name: '냉장고',
    type: ZoneItemType.appliance,
    recurrenceDays: 30,
    estimatedMinutes: 20,
  ),
  _ItemPreset(
    name: '싱크대',
    type: ZoneItemType.fixture,
    recurrenceDays: 1,
    estimatedMinutes: 8,
  ),
  _ItemPreset(
    name: '전자레인지',
    type: ZoneItemType.appliance,
    recurrenceDays: 7,
    estimatedMinutes: 10,
  ),
  _ItemPreset(
    name: '음식물처리기',
    type: ZoneItemType.appliance,
    recurrenceDays: 7,
    estimatedMinutes: 12,
  ),
  _ItemPreset(
    name: '소파',
    type: ZoneItemType.furniture,
    recurrenceDays: 14,
    estimatedMinutes: 15,
  ),
  _ItemPreset(
    name: '침대',
    type: ZoneItemType.furniture,
    recurrenceDays: 7,
    estimatedMinutes: 20,
  ),
  _ItemPreset(
    name: '세면대',
    type: ZoneItemType.fixture,
    recurrenceDays: 7,
    estimatedMinutes: 8,
  ),
  _ItemPreset(
    name: '공기청정기',
    type: ZoneItemType.appliance,
    recurrenceDays: 30,
    estimatedMinutes: 15,
  ),
];
