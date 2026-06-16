import 'dart:async';

import 'package:flutter/material.dart';

import '../models/care_record.dart';
import '../models/product_space.dart';
import '../models/zone_item.dart';
import '../repositories/product_data_repository.dart';
import '../repositories/product_catalog_repository.dart';
import '../repositories/product_submission_repository.dart';
import '../theme/app_theme.dart';
import 'product_submissions_screen.dart';
import 'zone_item_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.dataRepository,
    required this.catalogRepository,
    required this.onOpenProducts,
    required this.submissionRepository,
    super.key,
  });

  final ProductDataRepository dataRepository;
  final ProductCatalogRepository catalogRepository;
  final VoidCallback onOpenProducts;
  final ProductSubmissionRepository submissionRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ZoneItem> _items = [];
  List<ProductSpace> _spaces = [];
  List<CareRecord> _records = [];
  List<String> _recentProductIds = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recentItems = [
      for (final id in _recentProductIds)
        ..._items.where((item) => item.id == id),
    ];
    final normalizedQuery = _normalizeSearch(_searchQuery);
    final searchResults = normalizedQuery.isEmpty
        ? const <ZoneItem>[]
        : _items
            .where(
              (item) => _normalizeSearch([
                item.name,
                item.nickname,
                item.manufacturer,
                item.seriesName,
                item.modelName,
              ].whereType<String>().join(' '))
                  .contains(normalizedQuery),
            )
            .toList();
    final featuredItems = normalizedQuery.isNotEmpty
        ? searchResults
        : recentItems.isEmpty
            ? _items.take(4).toList()
            : recentItems;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          const _EditorialPageHeader(
            eyebrow: 'HOME PRODUCT MANUAL',
            title: '홈',
            description: '우리집 제품의 관리법과 소모품을 한곳에서 확인하세요.',
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              labelText: '내 제품 검색',
              hintText: '제품명, 브랜드, 모델명',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: '검색어 지우기',
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          _HeroPanel(
            itemCount: _items.length,
            onAddProduct: widget.onOpenProducts,
          ),
          const SizedBox(height: 22),
          _QuickStats(items: _items, records: _records),
          const SizedBox(height: 24),
          _SectionTitle(
            title: normalizedQuery.isNotEmpty
                ? '검색 결과 ${searchResults.length}개'
                : recentItems.isEmpty
                    ? '내 제품'
                    : '최근 본 제품',
            actionLabel: normalizedQuery.isEmpty ? '내 제품 보기' : null,
            onAction: normalizedQuery.isEmpty ? widget.onOpenProducts : null,
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_items.isEmpty)
            _EmptyProducts(onAddProduct: widget.onOpenProducts)
          else if (normalizedQuery.isNotEmpty && searchResults.isEmpty)
            const _EmptySearchResults()
          else
            for (final item in featuredItems.take(4)) ...[
              _HomeProductCard(
                item: item,
                records: _records,
                onTap: () => _openItem(item),
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _openSubmissions,
              icon: const Icon(Icons.inbox_outlined),
              label: const Text('제품 정보 요청 내역'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadData() async {
    final items = await widget.dataRepository.loadUserProducts();
    final spaces = await widget.dataRepository.loadSpaces();
    final records = await widget.dataRepository.loadCareRecords();
    final recentProductIds = await widget.dataRepository.loadRecentProductIds();
    if (!mounted) {
      return;
    }

    setState(() {
      _items = items ?? [];
      _spaces = spaces ?? [];
      _records = records ?? [];
      _recentProductIds = recentProductIds;
      _isLoading = false;
    });
  }

  Future<void> _openItem(ZoneItem item) async {
    final space = _spaceFor(item);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ZoneItemDetailScreen(
          item: item,
          spaceId: space?.id ?? item.zoneId,
          spaceName: space?.name ?? '미지정 공간',
          spaces: _spaces,
          dataRepository: widget.dataRepository,
          catalogRepository: widget.catalogRepository,
          onItemUpdated: _updateItem,
          onItemDeleted: _deleteItem,
        ),
      ),
    );
    await _loadData();
  }

  Future<void> _openSubmissions() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProductSubmissionsScreen(
          dataRepository: widget.dataRepository,
          submissionRepository: widget.submissionRepository,
        ),
      ),
    );
  }

  ProductSpace? _spaceFor(ZoneItem item) {
    for (final space in _spaces) {
      if (space.id == item.zoneId) {
        return space;
      }
    }
    return null;
  }

  Future<void> _updateItem(ZoneItem updatedItem) async {
    final savedItems = await widget.dataRepository.loadUserProducts() ?? [];
    final updatedItems = [
      for (final item in savedItems)
        if (item.id == updatedItem.id) updatedItem else item,
    ];
    await widget.dataRepository.saveUserProducts(updatedItems);
    if (!mounted) {
      return;
    }
    setState(() {
      _items = updatedItems;
    });
  }

  Future<void> _deleteItem(String itemId) async {
    final savedItems = await widget.dataRepository.loadUserProducts() ?? [];
    final updatedItems = [
      for (final item in savedItems)
        if (item.id != itemId) item,
    ];
    await widget.dataRepository.saveUserProducts(updatedItems);
    if (!mounted) {
      return;
    }
    setState(() => _items = updatedItems);
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.itemCount,
    required this.onAddProduct,
  });

  final int itemCount;
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    final title = itemCount == 0 ? '제품을 등록해볼까요?' : '필요할 때 바로 보기';
    final message = itemCount == 0
        ? '자주 찾는 제품부터 등록해 두면 관리법과 설명서를 바로 볼 수 있어요.'
        : '등록된 제품 $itemCount개의 관리법, 설명서와 소모품 정보를 모아두고 있어요.';

    return Container(
      constraints: const BoxConstraints(minHeight: 245),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.rule, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 8, color: AppColors.coral),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _PillLabel(text: 'CARE INDEX'),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(message),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: onAddProduct,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('제품 추가'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 64,
                  height: 112,
                  alignment: Alignment.center,
                  color: AppColors.ink,
                  child: const RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'PRODUCT CARE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({
    required this.items,
    required this.records,
  });

  final List<ZoneItem> items;
  final List<CareRecord> records;

  @override
  Widget build(BuildContext context) {
    final productInfoCount = items.where((item) => item.hasProductInfo).length;
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: '등록 제품',
            value: '${items.length}',
            icon: Icons.inventory_2_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: '모델 정보',
            value: '$productInfoCount',
            icon: Icons.qr_code_2,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: '관리 기록',
            value: '${records.length}',
            icon: Icons.history,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 28, height: 5, color: AppColors.coral),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 5, height: 24, color: AppColors.coral),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _HomeProductCard extends StatelessWidget {
  const _HomeProductCard({
    required this.item,
    required this.records,
    required this.onTap,
  });

  final ZoneItem item;
  final List<CareRecord> records;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(3),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 58,
                color: AppColors.ink,
                child: Icon(_iconFor(item.type), color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _productLine(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _MiniBadge(label: item.guideSourceType.label),
                        _MiniBadge(label: _statusLabel(item)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(ZoneItemType type) {
    return switch (type) {
      ZoneItemType.appliance => Icons.kitchen_outlined,
      ZoneItemType.furniture => Icons.chair_outlined,
      ZoneItemType.fixture => Icons.countertops_outlined,
      ZoneItemType.other => Icons.inventory_2_outlined,
    };
  }

  String _productLine(ZoneItem item) {
    final parts = [
      item.manufacturer,
      item.modelName,
    ].whereType<String>().where((text) => text.trim().isNotEmpty).toList();
    if (parts.isNotEmpty) {
      return parts.join(' · ');
    }
    return '${item.type.label} · 모델 정보 없이 일반 관리법 제공';
  }

  String _statusLabel(ZoneItem item) {
    final lastManagedAt = item.lastCleanedAt ??
        latestScheduledCareRecord(records, item.id)?.completedAt;
    if (lastManagedAt != null) {
      return '마지막 관리 ${_shortDate(lastManagedAt)}';
    }
    if (item.nextDueAt == null) {
      return '관리 전';
    }
    final now = DateTime.now();
    if (!item.nextDueAt!.isAfter(now)) {
      return '관리 확인';
    }
    return '다음 ${_shortDate(item.nextDueAt!)}';
  }

  String _shortDate(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$month.$day';
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts({required this.onAddProduct});

  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.rule),
      ),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 36, color: AppColors.coral),
          const SizedBox(height: 10),
          const Text(
            '아직 등록된 제품이 없어요',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            '설명서나 관리법을 자주 찾는 제품부터 하나만 추가해보세요.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAddProduct,
            icon: const Icon(Icons.add),
            label: const Text('내 제품 추가'),
          ),
        ],
      ),
    );
  }
}

class _EmptySearchResults extends StatelessWidget {
  const _EmptySearchResults();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.rule),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_outlined, size: 34, color: AppColors.coral),
          SizedBox(height: 10),
          Text(
            '등록된 제품에서 찾지 못했어요',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text('제품명이나 모델명의 일부만 입력해보세요.'),
        ],
      ),
    );
  }
}

class _PillLabel extends StatelessWidget {
  const _PillLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.coral,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppColors.ink),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EditorialPageHeader extends StatelessWidget {
  const _EditorialPageHeader({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: AppColors.coral,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 7),
        Container(width: 52, height: 4, color: AppColors.coral),
        const SizedBox(height: 9),
        Text(
          description,
          style: const TextStyle(color: AppColors.muted),
        ),
      ],
    );
  }
}

String _normalizeSearch(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '');
}
