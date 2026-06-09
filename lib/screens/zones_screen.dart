import 'package:flutter/material.dart';

import '../models/product_space.dart';
import '../models/zone_item.dart';
import '../repositories/product_data_repository.dart';
import '../repositories/product_catalog_repository.dart';
import '../widgets/fairy_image.dart';
import '../widgets/space_card.dart';
import 'zone_detail_screen.dart';

class ZonesScreen extends StatefulWidget {
  const ZonesScreen({
    required this.dataRepository,
    required this.catalogRepository,
    super.key,
  });

  final ProductDataRepository dataRepository;
  final ProductCatalogRepository catalogRepository;

  @override
  State<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends State<ZonesScreen> {
  List<ProductSpace> _spaces = [];
  List<ZoneItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
                        '내 제품',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      const Text('공간별로 제품을 넣어두고 청소법을 바로 확인해요.'),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _showAddZoneSheet,
                  tooltip: '공간 추가',
                  icon: const Icon(Icons.add_home_work_outlined),
                ),
                const SizedBox(width: 8),
                const FairyImage(size: 58),
              ],
            ),
          ),
        ),
        if (_isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_spaces.isEmpty)
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
                  final space = _spaceWithProgress(_spaces[index]);

                  return SpaceCard(
                    space: space,
                    index: index,
                    onTap: () => _openSpace(space),
                  );
                },
                childCount: _spaces.length,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _loadSavedData() async {
    final savedSpaces = await widget.dataRepository.loadSpaces();
    final savedItems = await widget.dataRepository.loadUserProducts();
    if (!mounted) {
      return;
    }

    setState(() {
      _spaces = savedSpaces ?? [];
      _items = savedItems ?? [];
      _isLoading = false;
    });
  }

  Future<void> _showAddZoneSheet() async {
    final space = await showModalBottomSheet<ProductSpace>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _AddZoneSheet(),
    );

    if (space == null || !mounted) {
      return;
    }

    setState(() {
      _spaces.add(space);
    });
    await widget.dataRepository.saveSpaces(_spaces);
    if (mounted) {
      _openSpace(space, startWithAddItem: true);
    }
  }

  Future<void> _updateZoneItems(
    String spaceId,
    List<ZoneItem> updatedItems,
  ) async {
    setState(() {
      _items = [
        for (final item in _items)
          if (item.zoneId != spaceId) item,
        ...updatedItems,
      ];
    });
    await widget.dataRepository.saveUserProducts(_items);
  }

  ProductSpace _spaceWithProgress(ProductSpace space) {
    final products = _items.where((item) => item.zoneId == space.id).toList();
    return space.copyWith(
      productCount: products.length,
      identifiedProductCount:
          products.where((item) => item.hasProductInfo).length,
    );
  }

  Future<void> _createPresetZones(List<_ZonePreset> presets) async {
    if (presets.isEmpty) {
      return;
    }

    final createdSpaces = [
      for (final preset in presets)
        ProductSpace(
          id: 'custom-zone-${preset.name}-${DateTime.now().microsecondsSinceEpoch}',
          name: preset.name,
          description: preset.description,
          productCount: 0,
          identifiedProductCount: 0,
        ),
    ];

    setState(() {
      _spaces.addAll(createdSpaces);
    });
    await widget.dataRepository.saveSpaces(_spaces);

    if (mounted && createdSpaces.length == 1) {
      _openSpace(createdSpaces.first, startWithAddItem: true);
    }
  }

  void _openSpace(
    ProductSpace space, {
    bool startWithAddItem = false,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ZoneDetailScreen(
          zone: space,
          items: _items.where((item) => item.zoneId == space.id).toList(),
          onItemsChanged: _updateZoneItems,
          onDeleteZone: _deleteZone,
          dataRepository: widget.dataRepository,
          catalogRepository: widget.catalogRepository,
          startWithAddItem: startWithAddItem,
        ),
      ),
    );
  }

  Future<void> _deleteZone(String zoneId) async {
    ProductSpace? deletedSpace;
    for (final space in _spaces) {
      if (space.id == zoneId) {
        deletedSpace = space;
        break;
      }
    }
    if (deletedSpace == null) {
      return;
    }

    setState(() {
      _spaces = [
        for (final space in _spaces)
          if (space.id != zoneId) space,
      ];
      _items = [
        for (final item in _items)
          if (item.zoneId != zoneId) item,
      ];
    });

    await widget.dataRepository.saveSpaces(_spaces);
    await widget.dataRepository.saveUserProducts(_items);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${deletedSpace.name} 공간을 삭제했어요.')),
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
              Icons.inventory_2_outlined,
              size: 54,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '제품을 담을 공간을 먼저 만들까요?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            '주방, 거실, 욕실처럼 제품이 놓인 공간을 고르면 다음에 제품을 추가할 수 있어요.',
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
            label: const Text('선택한 공간 만들기'),
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
  _ZonePreset(name: '주방', description: '냉장고, 음식물처리기, 싱크대'),
  _ZonePreset(name: '거실', description: '공기청정기, 소파, 테이블'),
  _ZonePreset(name: '욕실', description: '세면대, 샤워부스, 환풍기'),
  _ZonePreset(name: '침실', description: '침대, 매트리스, 옷장'),
  _ZonePreset(name: '방1', description: '책상, 의자, 수납장'),
  _ZonePreset(name: '방2', description: '필요한 제품을 직접 추가'),
  _ZonePreset(name: '베란다', description: '창틀, 세탁기, 바닥'),
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
            Text('공간 추가', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('제품을 어디에 두었는지 찾기 쉽게 공간을 만들어두세요.'),
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
                labelText: '공간 이름',
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
                labelText: '공간 설명',
                hintText: '예: 책상, 의자, 수납장',
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submit,
              child: const Text('공간 추가'),
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
      ProductSpace(
        id: 'custom-zone-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        description: description.isEmpty ? '새로 추가한 제품 공간' : description,
        productCount: 0,
        identifiedProductCount: 0,
      ),
    );
  }

  void _pickPreset(String name) {
    setState(() {
      _nameController.text = name;
      _descriptionController.text = switch (name) {
        '주방' => '냉장고, 음식물처리기, 싱크대',
        '거실' => '공기청정기, 소파, 테이블',
        '욕실' => '세면대, 샤워부스, 환풍기',
        '침실' => '침대, 매트리스, 옷장',
        _ => '새로 추가한 제품 공간',
      };
    });
  }
}
