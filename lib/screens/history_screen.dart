import 'dart:async';

import 'package:flutter/material.dart';

import '../models/care_record.dart';
import '../models/product_space.dart';
import '../models/zone_item.dart';
import '../repositories/product_data_repository.dart';
import '../widgets/record_tile.dart';
import 'care_record_editor_screen.dart';

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
  final _searchController = TextEditingController();
  List<CareRecord> _records = [];
  List<ZoneItem> _products = [];
  List<ProductSpace> _spaces = [];
  String _query = '';
  String? _selectedProductId;
  String? _selectedSpaceId;
  CareRecordType? _selectedType;
  bool _isLoading = true;

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
    final filtered = _filteredRecords;
    final groups = _groupByMonth(filtered);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Text('기록', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text('제품별 청소, 점검, 교체와 문제 이력을 찾아볼 수 있어요.'),
          const SizedBox(height: 20),
          _HistorySummary(
            count: filtered.length,
            latestAt: filtered.isEmpty ? null : filtered.first.completedAt,
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: '기록 검색',
              hintText: '제품, 메모, 증상, 사용한 용품',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: '검색어 지우기',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterMenu<String>(
                  label: _selectedProductId == null
                      ? '모든 제품'
                      : _productName(_selectedProductId!),
                  icon: Icons.inventory_2_outlined,
                  value: _selectedProductId,
                  entries: [
                    const DropdownMenuEntry(value: null, label: '모든 제품'),
                    for (final product in _products)
                      DropdownMenuEntry(
                        value: product.id,
                        label: product.displayName,
                      ),
                  ],
                  onSelected: (value) {
                    setState(() => _selectedProductId = value);
                  },
                ),
                const SizedBox(width: 8),
                _FilterMenu<String>(
                  label: _selectedSpaceId == null
                      ? '모든 공간'
                      : _spaceName(_selectedSpaceId!),
                  icon: Icons.home_work_outlined,
                  value: _selectedSpaceId,
                  entries: [
                    const DropdownMenuEntry(value: null, label: '모든 공간'),
                    for (final space in _spaces)
                      DropdownMenuEntry(value: space.id, label: space.name),
                  ],
                  onSelected: (value) {
                    setState(() => _selectedSpaceId = value);
                  },
                ),
                const SizedBox(width: 8),
                _FilterMenu<CareRecordType>(
                  label: _selectedType?.label ?? '모든 유형',
                  icon: Icons.tune,
                  value: _selectedType,
                  entries: [
                    const DropdownMenuEntry(value: null, label: '모든 유형'),
                    for (final type in CareRecordType.values)
                      DropdownMenuEntry(value: type, label: type.label),
                  ],
                  onSelected: (value) {
                    setState(() => _selectedType = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (filtered.isEmpty)
            _EmptyHistory(hasFilters: _hasFilters)
          else
            for (final group in groups.entries) ...[
              Text(group.key, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              for (final record in group.value) ...[
                RecordTile(
                  record: record,
                  onTap: () => _showRecordDetails(record),
                  onEdit: () => _editRecord(record),
                  onDelete: () => _confirmDeleteRecord(record),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  List<CareRecord> get _filteredRecords {
    final normalizedQuery = _normalize(_query);
    return _records.where((record) {
      if (_selectedProductId != null &&
          record.productId != _selectedProductId) {
        return false;
      }
      if (_selectedSpaceId != null && record.spaceId != _selectedSpaceId) {
        return false;
      }
      if (_selectedType != null && record.type != _selectedType) {
        return false;
      }
      if (normalizedQuery.isEmpty) {
        return true;
      }
      final searchText = [
        record.title,
        record.displayProductName,
        record.spaceName,
        record.type.label,
        record.guideTitle,
        record.symptom,
        record.result,
        record.note,
        ...record.usedSupplies,
      ].whereType<String>().map(_normalize).join(' ');
      return searchText.contains(normalizedQuery);
    }).toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  bool get _hasFilters =>
      _query.isNotEmpty ||
      _selectedProductId != null ||
      _selectedSpaceId != null ||
      _selectedType != null;

  Future<void> _loadData() async {
    final records = await widget.dataRepository.loadCareRecords();
    final products = await widget.dataRepository.loadUserProducts();
    final spaces = await widget.dataRepository.loadSpaces();
    if (!mounted) {
      return;
    }
    setState(() {
      _records = records ?? [];
      _products = products ?? [];
      _spaces = spaces ?? [];
      _isLoading = false;
    });
  }

  Future<void> _editRecord(CareRecord record) async {
    final product = _productFor(record);
    final updated = await Navigator.of(context).push<CareRecord>(
      MaterialPageRoute(
        builder: (context) => CareRecordEditorScreen(
          product: product,
          spaceId: record.spaceId ?? product.zoneId,
          spaceName: record.spaceName,
          record: record,
        ),
      ),
    );
    if (updated == null || !mounted) {
      return;
    }
    final records = [
      for (final item in _records)
        if (item.id == updated.id) updated else item,
    ];
    await widget.dataRepository.saveCareRecords(records);
    await _syncProductSchedule(updated.productId, records);
    if (!mounted) {
      return;
    }
    setState(() => _records = records);
  }

  Future<void> _confirmDeleteRecord(CareRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록을 삭제할까요?'),
        content: Text(
          '${record.displayProductName}의 ${record.type.label} 기록은 삭제 후 복구할 수 없어요.',
        ),
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
    if (confirmed != true) {
      return;
    }
    final records = [
      for (final item in _records)
        if (item.id != record.id) item,
    ];
    await widget.dataRepository.saveCareRecords(records);
    await _syncProductSchedule(record.productId, records);
    if (!mounted) {
      return;
    }
    setState(() => _records = records);
  }

  Future<void> _syncProductSchedule(
    String? productId,
    List<CareRecord> records,
  ) async {
    if (productId == null) {
      return;
    }
    final productIndex =
        _products.indexWhere((product) => product.id == productId);
    if (productIndex < 0) {
      return;
    }
    final product = _products[productIndex];
    final latest = latestScheduledCareRecord(records, productId);
    final updated = latest == null
        ? product.copyWith(
            clearLastCleanedAt: true,
            clearNextDueAt: true,
          )
        : product.copyWith(
            lastCleanedAt: latest.completedAt,
            nextDueAt: latest.nextCheckAt ??
                latest.completedAt.add(
                  Duration(days: product.recurrenceDays),
                ),
          );
    final products = _products.toList();
    products[productIndex] = updated;
    await widget.dataRepository.saveUserProducts(products);
    _products = products;
  }

  Future<void> _showRecordDetails(CareRecord record) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _RecordDetailsSheet(
        record: record,
        onEdit: () {
          Navigator.of(context).pop();
          _editRecord(record);
        },
        onDelete: () {
          Navigator.of(context).pop();
          _confirmDeleteRecord(record);
        },
      ),
    );
  }

  ZoneItem _productFor(CareRecord record) {
    for (final product in _products) {
      if (product.id == record.productId) {
        return product;
      }
    }
    return ZoneItem(
      id: record.productId ?? 'legacy-${record.id}',
      zoneId: record.spaceId ?? '',
      name:
          record.displayProductName.isEmpty ? '제품' : record.displayProductName,
      type: ZoneItemType.other,
      summary: '',
      frequency: '',
      supplies: const [],
      cautions: const [],
      steps: const [],
      estimatedMinutes: record.minutes,
    );
  }

  String _productName(String productId) {
    for (final product in _products) {
      if (product.id == productId) {
        return product.displayName;
      }
    }
    return '선택한 제품';
  }

  String _spaceName(String spaceId) {
    for (final space in _spaces) {
      if (space.id == spaceId) {
        return space.name;
      }
    }
    return '선택한 공간';
  }
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({
    required this.count,
    required this.latestAt,
  });

  final int count;
  final DateTime? latestAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 0 ? '아직 기록이 없어요' : '관리 기록 $count개',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  count == 0
                      ? '제품 상세에서 첫 관리 기록을 남겨보세요'
                      : '최근 기록 ${_formatDate(latestAt!)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterMenu<T> extends StatelessWidget {
  const _FilterMenu({
    required this.label,
    required this.icon,
    required this.value,
    required this.entries,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final T? value;
  final List<DropdownMenuEntry<T?>> entries;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: (context, controller, child) => OutlinedButton.icon(
        onPressed: () {
          controller.isOpen ? controller.close() : controller.open();
        },
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
      menuChildren: [
        for (final entry in entries)
          MenuItemButton(
            onPressed: () => onSelected(entry.value),
            leadingIcon: entry.value == value
                ? const Icon(Icons.check, size: 18)
                : const SizedBox(width: 18),
            child: Text(entry.label),
          ),
      ],
    );
  }
}

class _RecordDetailsSheet extends StatelessWidget {
  const _RecordDetailsSheet({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  final CareRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: '기록 수정',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: '기록 삭제',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _DetailLine(label: '유형', value: record.type.label),
            _DetailLine(label: '공간', value: record.spaceName),
            _DetailLine(
              label: '날짜',
              value: _formatDateTime(record.completedAt),
            ),
            if (record.minutes > 0)
              _DetailLine(label: '소요 시간', value: '${record.minutes}분'),
            if (record.usedSupplies.isNotEmpty)
              _DetailLine(
                label: '사용 용품',
                value: record.usedSupplies.join(', '),
              ),
            if (record.symptom?.isNotEmpty == true)
              _DetailLine(label: '문제 증상', value: record.symptom!),
            if (record.result?.isNotEmpty == true)
              _DetailLine(label: '관리 결과', value: record.result!),
            if (record.note?.isNotEmpty == true)
              _DetailLine(label: '메모', value: record.note!),
            if (record.nextCheckAt != null)
              _DetailLine(
                label: '다음 확인일',
                value: _formatDate(record.nextCheckAt!),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.hasFilters});

  final bool hasFilters;

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
              hasFilters ? '조건에 맞는 기록이 없어요' : '아직 관리 기록이 없어요',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters ? '검색어나 필터를 바꿔보세요.' : '제품 상세에서 관리 기록을 추가할 수 있어요.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

Map<String, List<CareRecord>> _groupByMonth(List<CareRecord> records) {
  final groups = <String, List<CareRecord>>{};
  for (final record in records) {
    final key = '${record.completedAt.year}년 ${record.completedAt.month}월';
    groups.putIfAbsent(key, () => []).add(record);
  }
  return groups;
}

String _normalize(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '');
}

String _formatDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}.$month.$day';
}

String _formatDateTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${_formatDate(value)} $hour:$minute';
}
