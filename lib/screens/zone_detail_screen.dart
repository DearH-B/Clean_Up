import 'dart:async';

import 'package:flutter/material.dart';

import '../data/product_catalog.dart';
import '../models/product_space.dart';
import '../models/zone_item.dart';
import '../repositories/product_data_repository.dart';
import '../repositories/product_catalog_repository.dart';
import '../widgets/zone_item_tile.dart';
import 'zone_item_detail_screen.dart';

class ZoneDetailScreen extends StatefulWidget {
  const ZoneDetailScreen({
    required this.zone,
    required this.items,
    required this.onItemsChanged,
    required this.onDeleteZone,
    required this.dataRepository,
    required this.catalogRepository,
    this.startWithAddItem = false,
    super.key,
  });

  final ProductSpace zone;
  final List<ZoneItem> items;
  final void Function(String zoneId, List<ZoneItem> items) onItemsChanged;
  final ValueChanged<String> onDeleteZone;
  final ProductDataRepository dataRepository;
  final ProductCatalogRepository catalogRepository;
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
      appBar: AppBar(
        title: Text(widget.zone.name),
        actions: [
          IconButton(
            tooltip: '공간 삭제',
            onPressed: _confirmDeleteZone,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: _items.isEmpty
          ? _EmptyZone(
              zoneName: widget.zone.name,
              onAdd: _showAddItemSheet,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                Text(
                  '${widget.zone.name}의 제품',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  '제품을 선택하면 관리 정보와 단계별 방법을 볼 수 있어요.',
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
        label: const Text('제품 추가'),
      ),
    );
  }

  void _openItem(ZoneItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ZoneItemDetailScreen(
          item: item,
          dataRepository: widget.dataRepository,
          catalogRepository: widget.catalogRepository,
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
      builder: (context) => _AddZoneItemSheet(
        zoneId: widget.zone.id,
        catalogRepository: widget.catalogRepository,
      ),
    );

    if (item == null || !mounted) {
      return;
    }

    setState(() {
      _items.add(item);
    });
    widget.onItemsChanged(widget.zone.id, _items);
  }

  Future<void> _confirmDeleteZone() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.zone.name} 삭제'),
        content: const Text('이 공간과 안에 등록한 제품을 모두 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    widget.onDeleteZone(widget.zone.id);
    Navigator.of(context).pop();
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
              '$zoneName에 등록된 제품이 없어요',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('관리 정보를 확인할 제품을 추가해 보세요.'),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('첫 제품 추가'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddZoneItemSheet extends StatefulWidget {
  const _AddZoneItemSheet({
    required this.zoneId,
    required this.catalogRepository,
  });

  final String zoneId;
  final ProductCatalogRepository catalogRepository;

  @override
  State<_AddZoneItemSheet> createState() => _AddZoneItemSheetState();
}

class _AddZoneItemSheetState extends State<_AddZoneItemSheet> {
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _modelController = TextEditingController();
  final _minutesController = TextEditingController(text: '10');
  ZoneItemType _selectedType = ZoneItemType.appliance;
  int _recurrenceDays = 7;
  bool _addProductInfo = false;
  bool _customBrand = false;
  String _searchQuery = '';
  ProductCatalogEntry? _selectedCatalogEntry;
  List<ProductCatalogEntry> _searchResults = [];
  Timer? _searchDebounce;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
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
              '제품 추가',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.category_outlined),
                  label: Text('종류만 등록'),
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
            if (_addProductInfo) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  labelText: '제품 검색',
                  hintText: '제품명, 브랜드 또는 모델명',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _selectedCatalogEntry = null;
                  });
                  _searchCatalog(value);
                },
              ),
              const SizedBox(height: 10),
              _CatalogSearchResults(
                query: _searchQuery,
                results: _searchResults,
                isSearching: _isSearching,
                selectedEntry: _selectedCatalogEntry,
                onSelected: _selectCatalogEntry,
              ),
              const SizedBox(height: 8),
              Text(
                '찾는 제품이 없다면 아래에서 종류, 브랜드, 모델명을 직접 입력할 수 있어요.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
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
                labelText: '제품 이름',
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
              label: const Text('관리 주기'),
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
              _ChoiceSection(
                title: '브랜드',
                helperText: '브랜드를 고르면 아래 모델 후보가 바뀌어요.',
                options: catalogBrandOptionsFor(_nameController.text),
                selectedValue:
                    _customBrand ? null : _manufacturerController.text.trim(),
                onSelected: _selectBrand,
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _customBrand = true;
                    _modelController.clear();
                  });
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('목록에 없어요'),
              ),
              if (_customBrand) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _manufacturerController,
                  decoration: const InputDecoration(
                    labelText: '브랜드 직접 입력',
                    hintText: '예: 위니아',
                  ),
                  onChanged: (_) {
                    setState(() {
                      _modelController.clear();
                    });
                  },
                ),
              ],
              const SizedBox(height: 16),
              _ChoiceSection(
                title: '대표 모델',
                helperText: _manufacturerController.text.trim().isEmpty
                    ? '브랜드를 먼저 선택하면 대표 모델을 보여드려요.'
                    : '${_manufacturerController.text.trim()} ${_nameController.text.trim()} 대표 모델이에요.',
                options: catalogModelOptionsFor(
                    _nameController.text, _manufacturerController.text.trim()),
                selectedValue: _modelController.text.trim(),
                onSelected: (modelName) {
                  setState(() {
                    _modelController.text = modelName;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _modelController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: '모델명 직접 입력 또는 선택',
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
    final catalogEntry = _selectedCatalogEntry ??
        findCatalogEntry(
          categoryName: name,
          brand: manufacturer,
          modelName: modelName,
        );

    if (_addProductInfo && catalogEntry != null) {
      Navigator.of(context).pop(
        catalogEntry.toZoneItem(
          id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
          zoneId: widget.zoneId,
        ),
      );
      return;
    }

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
        matchLevelLabel: _addProductInfo ? '사용자 입력 정보' : '제품군 기준',
        sourceTitle: _addProductInfo ? '사용자 등록 정보' : '앱 기본 관리법',
        sourceCheckedAt: now,
        productSpecs: [
          if (manufacturer.isNotEmpty) '브랜드/제조사: $manufacturer',
          if (modelName.isNotEmpty) '모델명: $modelName',
        ],
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
      _manufacturerController.clear();
      _modelController.clear();
      _customBrand = false;
      _selectedCatalogEntry = null;
    });
  }

  void _selectBrand(String brand) {
    setState(() {
      _customBrand = false;
      _manufacturerController.text = brand;
      _modelController.clear();
      _selectedCatalogEntry = null;
    });
  }

  void _selectCatalogEntry(ProductCatalogEntry entry) {
    setState(() {
      _selectedCatalogEntry = entry;
      _searchController.text = '${entry.brand} ${entry.modelName}'.trim();
      _searchQuery = _searchController.text;
      _nameController.text = entry.categoryName;
      _selectedType = entry.type;
      _recurrenceDays = entry.recurrenceDays;
      _minutesController.text = '${entry.estimatedMinutes}';
      _manufacturerController.text = entry.brand;
      _modelController.text = entry.modelName;
      _customBrand = false;
    });
  }

  void _searchCatalog(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await widget.catalogRepository.search(query, limit: 5);
      if (!mounted || query != _searchQuery) {
        return;
      }
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    });
  }
}

class _CatalogSearchResults extends StatelessWidget {
  const _CatalogSearchResults({
    required this.query,
    required this.results,
    required this.isSearching,
    required this.selectedEntry,
    required this.onSelected,
  });

  final String query;
  final List<ProductCatalogEntry> results;
  final bool isSearching;
  final ProductCatalogEntry? selectedEntry;
  final ValueChanged<ProductCatalogEntry> onSelected;

  @override
  Widget build(BuildContext context) {
    if (query.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    if (isSearching) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (results.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text('카탈로그에서 찾지 못했어요. 직접 입력해 등록할 수 있어요.')),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final entry in results)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              onTap: () => onSelected(entry),
              leading: Icon(
                selectedEntry?.id == entry.id
                    ? Icons.check_circle
                    : Icons.inventory_2_outlined,
              ),
              title: Text(entry.name),
              subtitle: Text(
                [
                  entry.brand,
                  entry.modelName,
                  entry.matchLevelLabel,
                ].where((text) => text.isNotEmpty).join(' · '),
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
      ],
    );
  }
}

class _ChoiceSection extends StatelessWidget {
  const _ChoiceSection({
    required this.title,
    required this.helperText,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  final String title;
  final String helperText;
  final List<String> options;
  final String? selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(helperText, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 10),
        if (options.isEmpty)
          Text(
            '선택 가능한 대표 모델이 없어요. 직접 입력해 주세요.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                ChoiceChip(
                  label: Text(option),
                  selected: selectedValue == option,
                  onSelected: (_) => onSelected(option),
                ),
            ],
          ),
      ],
    );
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
