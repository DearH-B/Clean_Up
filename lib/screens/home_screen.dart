import 'dart:async';

import 'package:flutter/material.dart';

import '../models/care_record.dart';
import '../models/zone_item.dart';
import '../repositories/product_data_repository.dart';
import '../repositories/product_catalog_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/fairy_image.dart';
import 'zone_item_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.dataRepository,
    required this.catalogRepository,
    required this.onOpenProducts,
    super.key,
  });

  final ProductDataRepository dataRepository;
  final ProductCatalogRepository catalogRepository;
  final VoidCallback onOpenProducts;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ZoneItem> _items = [];
  List<CareRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  @override
  Widget build(BuildContext context) {
    final dueItems = _items.where((item) => item.isDue(DateTime.now())).toList()
      ..sort((a, b) => (a.nextDueAt ?? DateTime(3000))
          .compareTo(b.nextDueAt ?? DateTime(3000)));
    final featuredItems = dueItems.isEmpty ? _items.take(3).toList() : dueItems;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('홈', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      '우리집 제품의 청소법과 소모품을 한곳에 모아둘게요.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const FairyImage(size: 58),
            ],
          ),
          const SizedBox(height: 18),
          _HeroPanel(
            itemCount: _items.length,
            dueCount: dueItems.length,
            onAddProduct: widget.onOpenProducts,
            onFindGuide: widget.onOpenProducts,
          ),
          const SizedBox(height: 22),
          _QuickStats(items: _items, records: _records),
          const SizedBox(height: 24),
          _SectionTitle(
            title: dueItems.isEmpty ? '바로 볼 제품' : '관리해두면 좋은 제품',
            actionLabel: '내 제품 보기',
            onAction: widget.onOpenProducts,
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_items.isEmpty)
            _EmptyProducts(onAddProduct: widget.onOpenProducts)
          else
            for (final item in featuredItems.take(4)) ...[
              _HomeProductCard(
                item: item,
                onTap: () => _openItem(item),
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 14),
          const _SectionTitle(title: '제품 정보 원칙'),
          const SizedBox(height: 10),
          const _DirectionCard(),
        ],
      ),
    );
  }

  Future<void> _loadData() async {
    final items = await widget.dataRepository.loadUserProducts();
    final records = await widget.dataRepository.loadCareRecords();
    if (!mounted) {
      return;
    }

    setState(() {
      _items = items ?? [];
      _records = records ?? [];
      _isLoading = false;
    });
  }

  Future<void> _openItem(ZoneItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ZoneItemDetailScreen(
          item: item,
          dataRepository: widget.dataRepository,
          catalogRepository: widget.catalogRepository,
          onItemUpdated: _updateItem,
        ),
      ),
    );
    await _loadData();
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
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.itemCount,
    required this.dueCount,
    required this.onAddProduct,
    required this.onFindGuide,
  });

  final int itemCount;
  final int dueCount;
  final VoidCallback onAddProduct;
  final VoidCallback onFindGuide;

  @override
  Widget build(BuildContext context) {
    final title = itemCount == 0
        ? '제품을 등록해볼까요?'
        : dueCount > 0
            ? '관리법 바로 보기'
            : '필요할 때 바로 보기';
    final message = itemCount == 0
        ? '음식물처리기, 냉장고, 세탁기처럼 자주 검색하는 제품부터 넣어두면 좋아요.'
        : dueCount > 0
            ? '$dueCount개 제품은 청소법이나 소모품을 확인하기 좋은 시점이에요.'
            : '등록된 제품 $itemCount개의 관리법과 추천용품을 정리해두고 있어요.';

    return Container(
      height: 256,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.pinkSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -22,
            bottom: -24,
            child: FairyImage(size: 150),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PillLabel(text: '제품 관리 도우미'),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 216),
                    child: Text(
                      message,
                      maxLines: 4,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: onAddProduct,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('제품 추가'),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: onFindGuide,
                        tooltip: '관리법 찾기',
                        icon: const Icon(Icons.manage_search_outlined),
                      ),
                    ],
                  ),
                ],
              ),
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
    final recommendedCount =
        items.where((item) => item.recommendedProducts.isNotEmpty).length;

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
            label: '추천용품',
            value: '$recommendedCount',
            icon: Icons.shopping_bag_outlined,
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppColors.rose),
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
    required this.onTap,
  });

  final ZoneItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                child: Icon(_iconFor(item.type)),
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
                        _MiniBadge(label: _dueLabel(item.nextDueAt)),
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

  String _dueLabel(DateTime? dateTime) {
    if (dateTime == null) {
      return '관리일 미정';
    }
    final now = DateTime.now();
    if (!dateTime.isAfter(now)) {
      return '관리 확인';
    }
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '다음 $month.$day';
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 36, color: AppColors.rose),
          const SizedBox(height: 10),
          const Text(
            '아직 등록된 제품이 없어요',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            '자주 청소법을 검색하는 제품부터 하나만 추가해보세요.',
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

class _DirectionCard extends StatelessWidget {
  const _DirectionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DirectionRow(
            icon: Icons.inventory_2_outlined,
            text: '제품별 관리법, 주의사항, 준비물을 한곳에 정리',
          ),
          SizedBox(height: 10),
          _DirectionRow(
            icon: Icons.manage_search_outlined,
            text: '모델명이 없어도 비슷한 제품 기준으로 안내',
          ),
          SizedBox(height: 10),
          _DirectionRow(
            icon: Icons.shopping_bag_outlined,
            text: '출처와 추천 이유가 분명한 관리용품 안내',
          ),
        ],
      ),
    );
  }
}

class _DirectionRow extends StatelessWidget {
  const _DirectionRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: AppColors.rose),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFB55567),
          fontSize: 12,
          fontWeight: FontWeight.w700,
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
        color: const Color(0xFFFFF3F5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
