import 'package:flutter/material.dart';

import '../models/product_space.dart';
import '../models/zone_item.dart';
import '../repositories/product_catalog_repository.dart';
import '../repositories/product_diagnostic_repository.dart';
import '../repositories/product_data_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/zone_item_tile.dart';
import 'product_registration_screen.dart';
import 'product_diagnostic_screen.dart';
import 'zone_item_detail_screen.dart';

class ZoneDetailScreen extends StatefulWidget {
  const ZoneDetailScreen({
    required this.zone,
    required this.items,
    required this.allProducts,
    required this.spaces,
    required this.onItemsChanged,
    required this.onProductAdded,
    required this.onDeleteZone,
    required this.dataRepository,
    required this.catalogRepository,
    this.startWithAddItem = false,
    super.key,
  });

  final ProductSpace zone;
  final List<ZoneItem> items;
  final List<ZoneItem> allProducts;
  final List<ProductSpace> spaces;
  final Future<void> Function(String spaceId, List<ZoneItem> items)
      onItemsChanged;
  final Future<void> Function(ZoneItem product) onProductAdded;
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
          _openRegistration();
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
          ? _EmptySpace(
              spaceName: widget.zone.name,
              onAdd: _openRegistration,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                const Text(
                  '제품 목록',
                  style: TextStyle(
                    color: AppColors.coral,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${widget.zone.name}의 제품',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 7),
                Container(width: 52, height: 4, color: AppColors.coral),
                const SizedBox(height: 9),
                Text(
                  '제품을 선택하면 관리 정보와 단계별 방법을 볼 수 있어요.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                for (final item in _items) ...[
                  ZoneItemTile(
                    item: item,
                    onTap: () => _openItem(item),
                    onSolveProblem: () => _openProblemSolver(item),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRegistration,
        icon: const Icon(Icons.add),
        label: const Text('제품 추가'),
      ),
    );
  }

  Future<void> _openRegistration() async {
    final savedProducts =
        await widget.dataRepository.loadUserProducts() ?? widget.allProducts;
    if (!mounted) {
      return;
    }
    final result = await Navigator.of(context).push<ProductRegistrationResult>(
      MaterialPageRoute(
        builder: (context) => ProductRegistrationScreen(
          space: widget.zone,
          spaces: widget.spaces,
          existingProducts: savedProducts,
          dataRepository: widget.dataRepository,
          catalogRepository: widget.catalogRepository,
        ),
      ),
    );

    if (result == null || !mounted) {
      return;
    }
    final existing = result.existingProduct;
    if (existing != null) {
      _openItem(existing);
      return;
    }
    final product = result.product;
    if (product == null) {
      return;
    }

    if (product.zoneId == widget.zone.id) {
      setState(() => _items.add(product));
    }
    await widget.onProductAdded(product);
    if (!mounted) {
      return;
    }
    if (result.openDetails && product.zoneId == widget.zone.id) {
      _openItem(product);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.displayName} 제품을 등록했어요.')),
      );
    }
  }

  void _openItem(ZoneItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ZoneItemDetailScreen(
          item: item,
          spaceId: widget.zone.id,
          spaceName: widget.zone.name,
          spaces: widget.spaces,
          dataRepository: widget.dataRepository,
          catalogRepository: widget.catalogRepository,
          onItemUpdated: (updatedItem) async {
            final index = _items.indexWhere(
              (candidate) => candidate.id == updatedItem.id,
            );
            if (index == -1 || !mounted) {
              return;
            }
            if (updatedItem.zoneId == widget.zone.id) {
              setState(() => _items[index] = updatedItem);
              await widget.onItemsChanged(widget.zone.id, _items);
            } else {
              setState(() => _items.removeAt(index));
              await widget.onItemsChanged(widget.zone.id, _items);
              await widget.onProductAdded(updatedItem);
            }
          },
          onItemDeleted: (itemId) async {
            if (!mounted) {
              return;
            }
            setState(() {
              _items.removeWhere((candidate) => candidate.id == itemId);
            });
            await widget.onItemsChanged(widget.zone.id, _items);
          },
        ),
      ),
    );
  }

  void _openProblemSolver(ZoneItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDiagnosticScreen(
          item: item,
          diagnosticRepository: const RemoteFirstProductDiagnosticRepository(),
        ),
      ),
    );
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

class _EmptySpace extends StatelessWidget {
  const _EmptySpace({
    required this.spaceName,
    required this.onAdd,
  });

  final String spaceName;
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
              '$spaceName에 등록된 제품이 없어요',
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
