import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/product_catalog.dart';
import '../data/product_consumable_defaults.dart';
import '../models/catalog_metadata.dart';
import '../models/catalog_model_option.dart';
import '../models/care_record.dart';
import '../models/product_consumable.dart';
import '../models/product_finder_result.dart';
import '../models/product_submission.dart';
import '../models/visual_product_candidate.dart';
import '../models/zone_item.dart';
import '../repositories/product_data_repository.dart';
import '../repositories/product_catalog_repository.dart';
import '../theme/app_theme.dart';
import 'care_record_editor_screen.dart';
import 'consumable_editor_screen.dart';
import 'model_selection_screen.dart';
import 'product_submission_form_screen.dart';

class ZoneItemDetailScreen extends StatefulWidget {
  const ZoneItemDetailScreen({
    required this.item,
    required this.spaceId,
    required this.spaceName,
    required this.dataRepository,
    required this.catalogRepository,
    this.onItemUpdated,
    super.key,
  });

  final ZoneItem item;
  final String spaceId;
  final String spaceName;
  final ProductDataRepository dataRepository;
  final ProductCatalogRepository catalogRepository;
  final Future<void> Function(ZoneItem item)? onItemUpdated;

  @override
  State<ZoneItemDetailScreen> createState() => _ZoneItemDetailScreenState();
}

class _ZoneItemDetailScreenState extends State<ZoneItemDetailScreen> {
  late ZoneItem _item;
  List<CareRecord> _productRecords = [];

  @override
  void initState() {
    super.initState();
    final defaults = widget.item.consumables.isEmpty
        ? defaultConsumablesFor(widget.item.name)
        : const <ProductConsumable>[];
    _item = defaults.isEmpty
        ? widget.item
        : widget.item.copyWith(consumables: defaults);
    if (defaults.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(widget.onItemUpdated?.call(_item));
      });
    }
    unawaited(_loadProductRecords());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_item.displayName),
          actions: [
            IconButton(
              tooltip: '제품 정보 수정',
              onPressed: _showProductInfoSheet,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        body: Column(
          children: [
            _ProductHeader(
              item: _item,
              onComplete: _completeCare,
            ),
            const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: '관리법'),
                Tab(text: '문제 해결'),
                Tab(text: '소모품'),
                Tab(text: '기록'),
                Tab(text: '제품 정보'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildCareTab(),
                  _buildTroubleshootingTab(),
                  _buildSuppliesTab(),
                  _buildRecordsTab(),
                  _buildProductInfoTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [
        if (_item.modelImageUrl?.isNotEmpty == true) ...[
          const _GuideScopeNotice(),
          const SizedBox(height: 14),
        ],
        Text(_item.summary),
        if (_item.guideStatus != null) ...[
          const SizedBox(height: 14),
          _GuideStatus(message: _item.guideStatus!),
        ],
        const SizedBox(height: 22),
        _Section(
          title: '준비물',
          icon: Icons.cleaning_services_outlined,
          children: [
            if (_item.supplies.isEmpty)
              const Text('제품 설명서에서 필요한 용품을 먼저 확인하세요.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final supply in _item.supplies)
                    Chip(label: Text(supply)),
                ],
              ),
          ],
        ),
        _Section(
          title: '관리 순서',
          icon: Icons.format_list_numbered,
          children: [
            for (var index = 0; index < _item.steps.length; index++)
              _StepTile(number: index + 1, text: _item.steps[index]),
          ],
        ),
        _Section(
          title: '하면 안 되는 행동',
          icon: Icons.warning_amber_outlined,
          children: [
            for (final caution in _item.cautions) _BulletText(text: caution),
          ],
        ),
        if (_item.guideVideoUrl != null)
          _GuideVideoCard(
            title: _item.guideVideoTitle ?? '관리 영상',
            channel: _item.guideVideoChannel ?? 'YouTube',
            onTap: () => _openGuideVideo(_item.guideVideoUrl!),
          ),
        const SizedBox(height: 12),
        Text(
          '제품의 공식 사용설명서와 안전 지침이 이 안내보다 우선합니다.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildTroubleshootingTab() {
    final advice = _troubleshootingFor(_item.name);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [
        Text(
          '증상에 맞는 항목을 확인하세요',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        const Text('분해가 필요하거나 누수·전기 문제가 의심되면 사용을 멈추고 전문가에게 문의하세요.'),
        const SizedBox(height: 18),
        for (final item in advice) _TroubleTile(item: item),
      ],
    );
  }

  Widget _buildSuppliesTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '교체·보충 관리',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: '소모품 추가',
              onPressed: _openConsumableEditor,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text('정확한 부품 번호와 호환 여부는 제품 설명서를 우선 확인하세요.'),
        const SizedBox(height: 14),
        if (_item.consumables.isEmpty)
          _EmptyConsumables(onAdd: _openConsumableEditor)
        else
          for (final consumable in _item.consumables)
            _ConsumableCard(
              consumable: consumable,
              onReplaced: () => _markConsumableReplaced(consumable),
              onEdit: () => _openConsumableEditor(consumable: consumable),
              onDelete: () => _confirmDeleteConsumable(consumable),
              onPurchase: consumable.purchaseUrl == null
                  ? null
                  : () => _openProduct(consumable.purchaseUrl!),
            ),
        const SizedBox(height: 22),
        _Section(
          title: '청소에 필요한 용품',
          icon: Icons.inventory_2_outlined,
          children: [
            for (final supply in _item.supplies)
              _RecommendationTile(text: supply),
          ],
        ),
        if (_item.recommendedSupplies.isNotEmpty)
          _Section(
            title: '선택할 때 볼 점',
            icon: Icons.checklist_outlined,
            children: [
              for (final supply in _item.recommendedSupplies)
                _RecommendationTile(text: supply),
            ],
          ),
        if (_item.recommendedProducts.isNotEmpty)
          _Section(
            title: '추천 제품',
            icon: Icons.shopping_bag_outlined,
            children: [
              for (final product in _item.recommendedProducts)
                _ProductRecommendationCard(
                  product: product,
                  onTap: () => _openProduct(product.url),
                ),
              Text(
                '광고 또는 제휴가 있는 제품은 별도 표시합니다.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildRecordsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '관리 기록 ${_productRecords.length}개',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            FilledButton.icon(
              onPressed: _openRecordEditor,
              icon: const Icon(Icons.add_task),
              label: const Text('기록 추가'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_productRecords.isEmpty)
          const _EmptyProductRecords()
        else
          for (final record in _productRecords)
            _ProductRecordTile(
              record: record,
              onTap: () => _openRecordEditor(record: record),
              onDelete: () => _confirmDeleteRecord(record),
            ),
      ],
    );
  }

  Widget _buildProductInfoTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [
        if (_item.modelImageUrl?.isNotEmpty == true) ...[
          _VerifiedModelCard(item: _item, onOpenSource: _openProduct),
          const SizedBox(height: 18),
        ],
        if (_item.hasProductInfo) _ProductInfo(item: _item),
        if (!_item.hasProductInfo)
          OutlinedButton.icon(
            onPressed: _showProductInfoSheet,
            icon: const Icon(Icons.add),
            label: const Text('브랜드·모델 등록'),
          ),
        if (_item.guideBasis != null) ...[
          const SizedBox(height: 14),
          _GuideBasis(message: _item.guideBasis!),
        ],
        if (_item.productSpecs.isNotEmpty) ...[
          const SizedBox(height: 20),
          _Section(
            title: '확인된 제품 정보',
            icon: Icons.fact_check_outlined,
            children: [
              for (final spec in _item.productSpecs) _BulletText(text: spec),
            ],
          ),
        ],
        if (_item.productSources.isNotEmpty || _item.sourceTitle != null)
          _ProductEvidenceCard(item: _item, onOpenSource: _openProduct),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _openSubmissionForm,
          icon: const Icon(Icons.flag_outlined),
          label: const Text('제품 정보 오류 제보'),
        ),
      ],
    );
  }

  Future<void> _openSubmissionForm() async {
    final submission = await Navigator.of(context).push<ProductSubmission>(
      MaterialPageRoute(
        builder: (context) => ProductSubmissionFormScreen(
          dataRepository: widget.dataRepository,
          product: _item,
        ),
      ),
    );
    if (submission != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('요청 내역에 저장했어요. 서버 연결 시 전송됩니다.')),
      );
    }
  }

  Future<void> _showProductInfoSheet() async {
    final updatedItem = await showModalBottomSheet<ZoneItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ProductInfoSheet(
        item: _item,
        catalogRepository: widget.catalogRepository,
      ),
    );

    if (updatedItem == null || !mounted) {
      return;
    }

    setState(() {
      _item = updatedItem;
    });
    await widget.onItemUpdated?.call(updatedItem);
  }

  Future<void> _openGuideVideo(String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('영상을 열 수 없어요. 잠시 후 다시 시도해 주세요.')),
      );
    }
  }

  Future<void> _openProduct(String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제품 페이지를 열 수 없어요.')),
      );
    }
  }

  Future<void> _loadProductRecords() async {
    final records = await widget.dataRepository.loadCareRecords() ?? [];
    if (!mounted) {
      return;
    }
    setState(() {
      _productRecords = records
          .where((record) => record.productId == _item.id)
          .toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    });
  }

  Future<void> _completeCare() async {
    final now = DateTime.now();
    final updatedItem = _item.copyWith(
      lastCleanedAt: now,
      nextDueAt: _item.recurrenceDays > 0
          ? now.add(Duration(days: _item.recurrenceDays))
          : null,
      clearNextDueAt: _item.recurrenceDays <= 0,
    );
    final savedRecords = await widget.dataRepository.loadCareRecords();
    final records = [
      CareRecord(
        id: 'record-${now.microsecondsSinceEpoch}',
        title: '${_item.name} 관리 완료',
        spaceName: widget.spaceName,
        completedAt: now,
        minutes: _item.estimatedMinutes,
        type: CareRecordType.cleaning,
        productId: _item.id,
        productName: _item.displayName,
        spaceId: widget.spaceId,
        guideTitle: _item.name,
        nextCheckAt: updatedItem.nextDueAt,
      ),
      ...(savedRecords ?? const <CareRecord>[]),
    ];

    await widget.dataRepository.saveCareRecords(records);
    if (!mounted) {
      return;
    }

    setState(() {
      _item = updatedItem;
      _productRecords = [records.first, ..._productRecords];
    });
    await widget.onItemUpdated?.call(updatedItem);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('오늘 청소한 날짜를 기록했어요.')),
    );
  }

  Future<void> _openConsumableEditor({
    ProductConsumable? consumable,
  }) async {
    final updated = await Navigator.of(context).push<ProductConsumable>(
      MaterialPageRoute(
        builder: (context) => ConsumableEditorScreen(
          consumable: consumable,
        ),
      ),
    );
    if (updated == null || !mounted) {
      return;
    }
    final exists = _item.consumables.any((item) => item.id == updated.id);
    final consumables = exists
        ? [
            for (final item in _item.consumables)
              if (item.id == updated.id) updated else item,
          ]
        : [..._item.consumables, updated];
    final updatedItem = _item.copyWith(consumables: consumables);
    await widget.onItemUpdated?.call(updatedItem);
    if (!mounted) {
      return;
    }
    setState(() => _item = updatedItem);
  }

  Future<void> _markConsumableReplaced(
    ProductConsumable consumable,
  ) async {
    final now = DateTime.now();
    final replaced = consumable.markReplaced(now);
    final updatedItem = _item.copyWith(
      consumables: [
        for (final item in _item.consumables)
          if (item.id == consumable.id) replaced else item,
      ],
    );
    final savedRecords = await widget.dataRepository.loadCareRecords() ?? [];
    final record = CareRecord(
      id: 'record-${now.microsecondsSinceEpoch}',
      title: '${_item.displayName} ${consumable.name} 교체',
      spaceName: widget.spaceName,
      completedAt: now,
      minutes: 0,
      type: consumable.type == ConsumableType.filter
          ? CareRecordType.filterReplacement
          : CareRecordType.consumableReplacement,
      productId: _item.id,
      productName: _item.displayName,
      consumableId: consumable.id,
      spaceId: widget.spaceId,
      usedSupplies: [consumable.name],
      nextCheckAt: replaced.nextReplacementAt,
    );
    final records = [record, ...savedRecords];
    await widget.dataRepository.saveCareRecords(records);
    await widget.onItemUpdated?.call(updatedItem);
    if (!mounted) {
      return;
    }
    setState(() {
      _item = updatedItem;
      _productRecords = [record, ..._productRecords];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${consumable.name} 교체일을 기록했어요.')),
    );
  }

  Future<void> _confirmDeleteConsumable(
    ProductConsumable consumable,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('소모품을 삭제할까요?'),
        content: Text(
          '${consumable.name} 관리 항목을 삭제해도 이전 교체 기록은 유지됩니다.',
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
    final updatedItem = _item.copyWith(
      consumables: [
        for (final item in _item.consumables)
          if (item.id != consumable.id) item,
      ],
    );
    await widget.onItemUpdated?.call(updatedItem);
    if (!mounted) {
      return;
    }
    setState(() => _item = updatedItem);
  }

  Future<void> _openRecordEditor({CareRecord? record}) async {
    final updatedRecord = await Navigator.of(context).push<CareRecord>(
      MaterialPageRoute(
        builder: (context) => CareRecordEditorScreen(
          product: _item,
          spaceId: widget.spaceId,
          spaceName: widget.spaceName,
          record: record,
        ),
      ),
    );
    if (updatedRecord == null || !mounted) {
      return;
    }

    final savedRecords = await widget.dataRepository.loadCareRecords() ?? [];
    final exists = savedRecords.any((item) => item.id == updatedRecord.id);
    final records = exists
        ? [
            for (final item in savedRecords)
              if (item.id == updatedRecord.id) updatedRecord else item,
          ]
        : [updatedRecord, ...savedRecords];
    records.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    await widget.dataRepository.saveCareRecords(records);

    final updatedItem = _itemWithLatestRecord(_item, records);
    await widget.onItemUpdated?.call(updatedItem);
    if (!mounted) {
      return;
    }
    setState(() {
      _item = updatedItem;
      _productRecords =
          records.where((item) => item.productId == _item.id).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(exists ? '기록을 수정했어요.' : '관리 기록을 저장했어요.')),
    );
  }

  Future<void> _confirmDeleteRecord(CareRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록을 삭제할까요?'),
        content: Text(
          '${record.type.label} 기록을 삭제하면 다시 복구할 수 없어요.',
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
    final records = await widget.dataRepository.loadCareRecords() ?? [];
    final remaining = [
      for (final item in records)
        if (item.id != record.id) item,
    ];
    await widget.dataRepository.saveCareRecords(remaining);
    final updatedItem = _itemWithLatestRecord(_item, remaining);
    await widget.onItemUpdated?.call(updatedItem);
    if (!mounted) {
      return;
    }
    setState(() {
      _item = updatedItem;
      _productRecords.removeWhere((item) => item.id == record.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('기록을 삭제했어요.')),
    );
  }

  ZoneItem _itemWithLatestRecord(
    ZoneItem item,
    List<CareRecord> records,
  ) {
    final latest = latestScheduledCareRecord(records, item.id);
    if (latest == null) {
      return item.copyWith(
        clearLastCleanedAt: true,
        clearNextDueAt: true,
      );
    }
    return item.copyWith(
      lastCleanedAt: latest.completedAt,
      nextDueAt: latest.nextCheckAt ??
          (item.recurrenceDays > 0
              ? latest.completedAt.add(Duration(days: item.recurrenceDays))
              : null),
      clearNextDueAt: latest.nextCheckAt == null && item.recurrenceDays <= 0,
    );
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({
    required this.item,
    required this.onComplete,
  });

  final ZoneItem item;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final identity = [
      item.manufacturer,
      item.seriesName,
      item.modelName,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 64,
                color: AppColors.ink,
                child: item.modelImageUrl?.isNotEmpty == true
                    ? Image.network(
                        item.modelImageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          _productIcon(item.type),
                          color: Colors.white,
                        ),
                      )
                    : Icon(_productIcon(item.type), color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (identity.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(identity),
                    ],
                    const SizedBox(height: 8),
                    Container(width: 46, height: 4, color: AppColors.coral),
                    const SizedBox(height: 7),
                    _GuideSourceBadge(sourceType: item.guideSourceType),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ScheduleCard(item: item, onComplete: onComplete),
        ],
      ),
    );
  }
}

class _GuideScopeNotice extends StatelessWidget {
  const _GuideScopeNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: const Border(
          left: BorderSide(color: AppColors.coral, width: 4),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text('제품은 정확한 모델로 확인했어요. 아래 관리법은 시리즈 공통 안내예요.'),
          ),
        ],
      ),
    );
  }
}

IconData _productIcon(ZoneItemType type) {
  return switch (type) {
    ZoneItemType.appliance => Icons.kitchen_outlined,
    ZoneItemType.furniture => Icons.chair_outlined,
    ZoneItemType.fixture => Icons.countertops_outlined,
    ZoneItemType.other => Icons.inventory_2_outlined,
  };
}

class _TroubleAdvice {
  const _TroubleAdvice({
    required this.title,
    required this.action,
    this.stopAndAsk = false,
  });

  final String title;
  final String action;
  final bool stopAndAsk;
}

List<_TroubleAdvice> _troubleshootingFor(String productName) {
  final name = productName.replaceAll(' ', '');
  if (name.contains('식기세척기')) {
    return const [
      _TroubleAdvice(
        title: '냄새가 나요',
        action: '필터와 배수구 주변의 음식물 찌꺼기를 확인하고 문 패킹의 물기를 닦으세요.',
      ),
      _TroubleAdvice(
        title: '세척이 잘 안 돼요',
        action: '분사 노즐 구멍 막힘, 필터 조립 상태와 전용 세제 사용량을 확인하세요.',
      ),
      _TroubleAdvice(
        title: '물이 빠지지 않아요',
        action: '사용을 멈추고 필터가 정확히 조립됐는지 확인하세요. 배수 호스나 펌프 분해는 서비스센터에 문의하세요.',
        stopAndAsk: true,
      ),
      _TroubleAdvice(
        title: '물이 새요',
        action: '전원과 급수를 차단하고 사용을 중단한 뒤 설치 상태와 서비스센터를 확인하세요.',
        stopAndAsk: true,
      ),
    ];
  }
  if (name.contains('냉장고')) {
    return const [
      _TroubleAdvice(
        title: '냄새가 나요',
        action: '상한 식품을 확인하고 선반, 서랍과 문 고무패킹의 음식물 흔적을 닦으세요.',
      ),
      _TroubleAdvice(
        title: '문이 잘 닫히지 않아요',
        action: '고무패킹의 이물질과 수납물이 문을 막는지 확인하세요.',
      ),
      _TroubleAdvice(
        title: '성에나 물방울이 많아요',
        action: '문이 오래 열려 있었는지 확인하고 통풍구를 막은 식품을 정리하세요.',
      ),
      _TroubleAdvice(
        title: '냉각이 약하거나 이상 소음이 나요',
        action: '전원과 온도 설정을 확인한 뒤 지속되면 내부 부품을 만지지 말고 서비스센터에 문의하세요.',
        stopAndAsk: true,
      ),
    ];
  }
  if (name.contains('음식물처리기')) {
    return const [
      _TroubleAdvice(
        title: '냄새가 나요',
        action: '투입구와 외부 접합부를 닦고 처리 방식에 맞는 미생물 또는 건조통 관리법을 확인하세요.',
      ),
      _TroubleAdvice(
        title: '평소와 다른 소음이 나요',
        action: '즉시 사용을 멈추고 투입 금지 물질 여부를 확인한 뒤 제조사에 문의하세요.',
        stopAndAsk: true,
      ),
      _TroubleAdvice(
        title: '누수 흔적이 있어요',
        action: '전원과 급수를 차단하고 배관이나 본체를 분해하지 말고 설치업체에 문의하세요.',
        stopAndAsk: true,
      ),
    ];
  }
  return const [
    _TroubleAdvice(
      title: '오염이나 냄새가 생겼어요',
      action: '제품 표면과 사용자가 분리할 수 있는 부품을 확인하고 설명서의 관리 항목을 먼저 찾으세요.',
    ),
    _TroubleAdvice(
      title: '소음, 누수 또는 작동 문제가 있어요',
      action: '사용을 멈추고 전원을 분리한 뒤 임의로 분해하지 말고 제조사나 전문가에게 문의하세요.',
      stopAndAsk: true,
    ),
  ];
}

class _TroubleTile extends StatelessWidget {
  const _TroubleTile({required this.item});

  final _TroubleAdvice item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: Icon(
          item.stopAndAsk ? Icons.report_outlined : Icons.build_outlined,
          color: item.stopAndAsk ? Theme.of(context).colorScheme.error : null,
        ),
        title: Text(item.title),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.action),
          if (item.stopAndAsk) ...[
            const SizedBox(height: 8),
            Text(
              '사용 중단 및 전문가 확인 권장',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyProductRecords extends StatelessWidget {
  const _EmptyProductRecords();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text('아직 이 제품의 관리 기록이 없습니다.'),
    );
  }
}

class _ProductRecordTile extends StatelessWidget {
  const _ProductRecordTile({
    required this.record,
    required this.onTap,
    required this.onDelete,
  });

  final CareRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(_recordTypeIcon(record.type)),
      title: Text(record.title),
      subtitle: Text(
        [
          _sourceDate(record.completedAt),
          record.type.label,
          if (record.minutes > 0) '${record.minutes}분',
          if (record.note?.isNotEmpty == true) record.note!,
        ].join(' · '),
      ),
      trailing: PopupMenuButton<String>(
        tooltip: '기록 메뉴',
        onSelected: (value) {
          if (value == 'edit') {
            onTap();
          } else if (value == 'delete') {
            onDelete();
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'edit', child: Text('수정')),
          PopupMenuItem(value: 'delete', child: Text('삭제')),
        ],
      ),
    );
  }
}

IconData _recordTypeIcon(CareRecordType type) {
  return switch (type) {
    CareRecordType.cleaning => Icons.cleaning_services_outlined,
    CareRecordType.inspection => Icons.search_outlined,
    CareRecordType.filterReplacement => Icons.filter_alt_outlined,
    CareRecordType.consumableReplacement => Icons.autorenew_outlined,
    CareRecordType.issue => Icons.report_problem_outlined,
    CareRecordType.service => Icons.home_repair_service_outlined,
    CareRecordType.note => Icons.note_alt_outlined,
  };
}

class _EmptyConsumables extends StatelessWidget {
  const _EmptyConsumables({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Icon(Icons.filter_alt_outlined, size: 34),
          const SizedBox(height: 8),
          const Text(
            '등록된 소모품이 없어요',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          const Text(
            '필터나 세척제의 이름과 교체 주기를 직접 추가할 수 있어요.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('소모품 추가'),
          ),
        ],
      ),
    );
  }
}

class _ConsumableCard extends StatelessWidget {
  const _ConsumableCard({
    required this.consumable,
    required this.onReplaced,
    required this.onEdit,
    required this.onDelete,
    required this.onPurchase,
  });

  final ProductConsumable consumable;
  final VoidCallback onReplaced;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onPurchase;

  @override
  Widget build(BuildContext context) {
    final dueLabel = _replacementLabel(consumable);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(child: Icon(_consumableIcon(consumable.type))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        consumable.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        consumable.compatibilityLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: '소모품 메뉴',
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('수정')),
                    PopupMenuItem(value: 'delete', child: Text('삭제')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                Chip(label: Text(consumable.type.label)),
                Chip(label: Text(_periodLabel(consumable.replacementDays))),
                if (consumable.partNumber?.isNotEmpty == true)
                  Chip(label: Text('부품 ${consumable.partNumber}')),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  consumable.isDue(DateTime.now())
                      ? Icons.warning_amber_outlined
                      : Icons.event_outlined,
                  size: 19,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    dueLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (consumable.note?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                consumable.note!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onReplaced,
                    icon: const Icon(Icons.check),
                    label: Text(
                      consumable.type == ConsumableType.refill
                          ? '보충했어요'
                          : '교체했어요',
                    ),
                  ),
                ),
                if (onPurchase != null) ...[
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    onPressed: onPurchase,
                    tooltip: consumable.isSponsored ? '구매 링크 · 광고' : '구매 링크',
                    icon: const Icon(Icons.shopping_bag_outlined),
                  ),
                ],
              ],
            ),
            if (consumable.isSponsored) ...[
              const SizedBox(height: 7),
              const Text(
                '광고·제휴 링크',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.item,
    required this.onComplete,
  });

  final ZoneItem item;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.rule),
      ),
      child: Row(
        children: [
          Container(width: 7, height: 54, color: AppColors.coral),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.lastCleanedAt == null
                      ? '아직 청소 기록이 없어요'
                      : '마지막 청소 ${_formatDate(item.lastCleanedAt!)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  item.nextDueAt == null
                      ? '청소한 날만 가볍게 남겨두세요'
                      : '다음 확인 ${_formatDate(item.nextDueAt!)}',
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onComplete,
            child: const Text('오늘 청소'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$month.$day';
  }
}

IconData _consumableIcon(ConsumableType type) {
  return switch (type) {
    ConsumableType.filter => Icons.filter_alt_outlined,
    ConsumableType.cleaner => Icons.cleaning_services_outlined,
    ConsumableType.refill => Icons.opacity_outlined,
    ConsumableType.part => Icons.build_outlined,
    ConsumableType.other => Icons.inventory_2_outlined,
  };
}

String _replacementLabel(ProductConsumable consumable) {
  final last = consumable.lastReplacedAt;
  final next = consumable.nextReplacementAt;
  if (last == null) {
    return '마지막 교체일을 아직 기록하지 않았어요';
  }
  if (next == null) {
    return '마지막 교체 ${_sourceDate(last)}';
  }
  if (consumable.isDue(DateTime.now())) {
    return '교체 시기 확인 · 마지막 ${_sourceDate(last)}';
  }
  return '마지막 ${_sourceDate(last)} · 다음 ${_sourceDate(next)}';
}

String _periodLabel(int days) {
  if (days >= 365 && days % 365 == 0) {
    return '${days ~/ 365}년 주기';
  }
  if (days >= 30 && days % 30 == 0) {
    return '${days ~/ 30}개월 주기';
  }
  return '$days일 주기';
}

class _GuideSourceBadge extends StatelessWidget {
  const _GuideSourceBadge({required this.sourceType});

  final GuideSourceType sourceType;

  @override
  Widget build(BuildContext context) {
    final color = switch (sourceType) {
      GuideSourceType.official => const Color(0xFFE8F4EC),
      GuideSourceType.officialVideo => const Color(0xFFFFE7E7),
      GuideSourceType.similarProduct => const Color(0xFFFFF2D8),
      GuideSourceType.general => const Color(0xFFF3EEF0),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        sourceType.label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ProductRecommendationCard extends StatelessWidget {
  const _ProductRecommendationCard({
    required this.product,
    required this.onTap,
  });

  final CleaningProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE9ED),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.cleaning_services_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              product.brand,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: product.isSponsored
                                  ? const Color(0xFFFFE0A8)
                                  : const Color(0xFFF3EEF0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.isSponsored ? '광고' : '추천',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        product.reason,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.open_in_new_rounded, size: 19),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideVideoCard extends StatelessWidget {
  const _GuideVideoCard({
    required this.title,
    required this.channel,
    required this.onTap,
  });

  final String title;
  final String channel;
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
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE7E7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Color(0xFFE53935),
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '공식 세척 영상 보기',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$title · $channel',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideBasis extends StatelessWidget {
  const _GuideBasis({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF3DCE1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.manage_search_outlined, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '이 관리법의 참고 기준',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductEvidenceCard extends StatelessWidget {
  const _ProductEvidenceCard({
    required this.item,
    required this.onOpenSource,
  });

  final ZoneItem item;
  final ValueChanged<String> onOpenSource;

  @override
  Widget build(BuildContext context) {
    final sources = item.productSources;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_outlined, size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sources.isEmpty ? item.matchLevelLabel ?? '정보 출처' : '정보 출처',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (sources.isNotEmpty)
                Text(
                  '${sources.length}개',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (sources.isEmpty)
            _LegacySource(item: item, onOpenSource: onOpenSource)
          else
            for (var index = 0; index < sources.length; index++) ...[
              if (index > 0) const Divider(height: 22),
              _SourceDetails(
                source: sources[index],
                onOpenSource: onOpenSource,
              ),
            ],
        ],
      ),
    );
  }
}

class _SourceDetails extends StatelessWidget {
  const _SourceDetails({
    required this.source,
    required this.onOpenSource,
  });

  final ProductSource source;
  final ValueChanged<String> onOpenSource;

  @override
  Widget build(BuildContext context) {
    final checkedAt = source.checkedAt;
    final url = source.url;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                source.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (source.isOfficial)
              const Chip(
                label: Text('공식'),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${source.type.label} · ${source.publisher} · ${_sourceDate(checkedAt)} 확인',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (source.supports.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text('근거: ${source.supports.join(', ')}'),
        ],
        if (!source.isActive) ...[
          const SizedBox(height: 5),
          Text(
            '현재 유효성을 다시 확인해야 하는 출처예요.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (url?.isNotEmpty == true)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => onOpenSource(url!),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('출처 열기'),
            ),
          ),
      ],
    );
  }
}

class _LegacySource extends StatelessWidget {
  const _LegacySource({
    required this.item,
    required this.onOpenSource,
  });

  final ZoneItem item;
  final ValueChanged<String> onOpenSource;

  @override
  Widget build(BuildContext context) {
    final checkedAt = item.sourceCheckedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.sourceTitle!),
        if (checkedAt != null)
          Text(
            '${_sourceDate(checkedAt)} 확인',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (item.sourceUrl?.isNotEmpty == true)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => onOpenSource(item.sourceUrl!),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('확인한 출처 열기'),
            ),
          ),
      ],
    );
  }
}

String _sourceDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}.$month.$day';
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check_rounded, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ProductInfoSheet extends StatefulWidget {
  const _ProductInfoSheet({
    required this.item,
    required this.catalogRepository,
  });

  final ZoneItem item;
  final ProductCatalogRepository catalogRepository;

  @override
  State<_ProductInfoSheet> createState() => _ProductInfoSheetState();
}

class _ProductInfoSheetState extends State<_ProductInfoSheet> {
  final _searchController = TextEditingController();
  late final TextEditingController _manufacturerController;
  late final TextEditingController _modelController;
  late bool _customBrand;
  String _searchQuery = '';
  ProductCatalogEntry? _selectedCatalogEntry;
  VisualProductCandidate? _visualCandidate;
  CatalogModelOption? _exactModel;
  List<ProductCatalogEntry> _searchResults = [];
  Timer? _searchDebounce;
  bool _isSearching = false;

  String get _categoryName =>
      findCatalogEntryById(widget.item.catalogProductId ?? '')?.categoryName ??
      widget.item.name;

  @override
  void initState() {
    super.initState();
    _manufacturerController = TextEditingController(
      text: widget.item.manufacturer,
    );
    _modelController = TextEditingController(text: widget.item.modelName);
    if (widget.item.modelName?.isNotEmpty == true &&
        (widget.item.modelImageUrl?.isNotEmpty == true ||
            widget.item.officialProductUrl?.isNotEmpty == true)) {
      _exactModel = CatalogModelOption(
        modelName: widget.item.modelName!,
        displayName: widget.item.modelDisplayName ?? widget.item.modelName!,
        releaseYear: widget.item.modelReleaseYear,
        imageUrl: widget.item.modelImageUrl,
        productUrl: widget.item.officialProductUrl,
        features: widget.item.modelFeatures,
      );
    }
    _customBrand = !catalogBrandOptionsFor(_categoryName).contains(
          widget.item.manufacturer,
        ) &&
        (widget.item.manufacturer?.isNotEmpty ?? false);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
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
              '${widget.item.name} 제품 정보',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('제품 라벨이나 설명서에서 확인할 수 있어요.'),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: '제품 검색',
                hintText: '브랜드 또는 모델명',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _selectedCatalogEntry = null;
                });
                _searchCatalog(value);
              },
            ),
            if (_searchQuery.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _ProductCatalogResults(
                query: _searchQuery,
                results: _searchResults,
                isSearching: _isSearching,
                selectedEntry: _selectedCatalogEntry,
                onSelected: _selectCatalogEntry,
              ),
              const SizedBox(height: 12),
            ],
            _ChoiceSection(
              title: '브랜드',
              helperText: '브랜드를 고르면 아래 모델 후보가 바뀌어요.',
              options: catalogBrandOptionsFor(_categoryName),
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
            FilledButton.tonalIcon(
              onPressed: _manufacturerController.text.trim().isEmpty
                  ? null
                  : _openProductFinder,
              icon: const Icon(Icons.image_search_outlined),
              label: Text(
                _modelController.text.trim().isEmpty ? '내 제품 찾기' : '정확한 모델 바꾸기',
              ),
            ),
            if (_manufacturerController.text.trim().isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '브랜드를 먼저 선택하면 이미지와 출시 시기로 제품을 찾을 수 있어요.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 16),
            _ChoiceSection(
              title: '대표 모델',
              helperText: _manufacturerController.text.trim().isEmpty
                  ? '브랜드를 먼저 선택하면 대표 모델을 보여드려요.'
                  : '${_manufacturerController.text.trim()} $_categoryName 대표 모델이에요.',
              options: catalogModelOptionsFor(
                  _categoryName, _manufacturerController.text.trim()),
              selectedValue: _modelController.text.trim(),
              onSelected: (modelName) {
                setState(() {
                  _modelController.text = modelName;
                  _exactModel = null;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _modelController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: '모델명 직접 입력 또는 선택',
                hintText: '제품 라벨의 모델명을 그대로 적어도 좋아요.',
              ),
              onChanged: (_) => setState(() => _exactModel = null),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submit,
              child: const Text('제품 정보 저장'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final manufacturer = _manufacturerController.text.trim();
    final modelName = _modelController.text.trim();
    if (manufacturer.isEmpty && modelName.isEmpty) {
      return;
    }

    final catalogEntry = findCatalogEntry(
          categoryName: _categoryName,
          brand: manufacturer,
          modelName: modelName,
        ) ??
        _selectedCatalogEntry;
    if (catalogEntry != null) {
      Navigator.of(context).pop(catalogEntry.mergeInto(widget.item));
      return;
    }

    Navigator.of(context).pop(
      widget.item.copyWith(
        manufacturer: manufacturer,
        modelName: modelName,
        modelDisplayName: _exactModel?.displayName,
        modelReleaseYear: _exactModel?.releaseYear,
        modelImageUrl: _exactModel?.imageUrl,
        officialProductUrl: _exactModel?.productUrl,
        modelFeatures: _exactModel?.features,
        visualCandidateId: _visualCandidate?.id,
        releasePeriod: _visualCandidate?.releasePeriod,
        clearVisualCandidate: modelName.isNotEmpty && _visualCandidate == null,
        clearExactModel: modelName.isEmpty || _exactModel == null,
        guideStatus: '등록된 제품 정보를 바탕으로 공식 안내를 확인할 수 있어요.',
        sourceTitle: _exactModel == null ? '사용자 등록 정보' : '제조사 공식 제품 페이지',
        sourceUrl: _exactModel?.productUrl,
        clearSourceUrl: _exactModel == null,
        sourceCheckedAt: DateTime.now(),
        matchLevelLabel: _exactModel == null ? '사용자 입력 정보' : '공식 확인 모델',
        productSpecs: [
          if (manufacturer.isNotEmpty) '브랜드/제조사: $manufacturer',
          if (modelName.isNotEmpty) '모델명: $modelName',
          if (_exactModel?.releaseYear != null)
            '출시 연도: ${_exactModel!.releaseYear}년',
          ...?_exactModel?.features,
        ],
      ),
    );
  }

  void _selectBrand(String brand) {
    setState(() {
      _customBrand = false;
      _manufacturerController.text = brand;
      _modelController.clear();
      _selectedCatalogEntry = null;
      _visualCandidate = null;
      _exactModel = null;
    });
  }

  void _selectCatalogEntry(ProductCatalogEntry entry) {
    setState(() {
      _selectedCatalogEntry = entry;
      _searchController.text =
          '${entry.brand} ${entry.seriesName} ${entry.modelName}'.trim();
      _searchQuery = _searchController.text;
      _manufacturerController.text = entry.brand;
      _modelController.text = entry.modelName;
      _visualCandidate = null;
      _exactModel = null;
      _customBrand = false;
    });
  }

  Future<void> _openProductFinder() async {
    final brand = _manufacturerController.text.trim();
    if (brand.isEmpty) {
      return;
    }
    final result = await Navigator.of(context).push<ProductFinderResult>(
      MaterialPageRoute(
        builder: (context) => ModelSelectionScreen(
          categoryName: _categoryName,
          brand: brand,
          catalogRepository: widget.catalogRepository,
          selectedModel: _modelController.text.trim().isEmpty
              ? null
              : _modelController.text.trim(),
        ),
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _selectedCatalogEntry = null;
      if (result.hasModelName) {
        _modelController.text = result.modelName;
        _exactModel = result.exactModel;
        _visualCandidate = null;
      } else {
        _modelController.clear();
        _exactModel = null;
        _visualCandidate = result.visualCandidate;
      }
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
      final results = await widget.catalogRepository.search(
        query,
        category: _categoryName,
        limit: 4,
      );
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

class _ProductCatalogResults extends StatelessWidget {
  const _ProductCatalogResults({
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
        child: const Text('일치하는 제품이 없어요. 아래에서 직접 입력할 수 있어요.'),
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
                  entry.seriesName,
                  entry.modelName,
                  entry.matchLevelLabel,
                ].where((text) => text.isNotEmpty).join(' · '),
              ),
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
          Text('선택 가능한 대표 모델이 없어요. 직접 입력해 주세요.',
              style: Theme.of(context).textTheme.bodySmall)
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

class _ProductInfo extends StatelessWidget {
  const _ProductInfo({required this.item});

  final ZoneItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (item.manufacturer != null)
          _InfoRow(label: '제조사', value: item.manufacturer!),
        if (item.seriesName?.isNotEmpty == true)
          _InfoRow(label: '시리즈', value: item.seriesName!),
        if (item.modelName?.isNotEmpty == true)
          _InfoRow(label: '모델명', value: item.modelName!),
        if (item.productMethod != null)
          _InfoRow(label: '처리 방식', value: item.productMethod!),
        if (item.releasePeriod != null)
          _InfoRow(label: '출시 시기', value: item.releasePeriod!),
        if (item.purchaseDate != null)
          _InfoRow(label: '구매일', value: _formatProductDate(item.purchaseDate!)),
        if (item.installedDate != null)
          _InfoRow(
              label: '설치일', value: _formatProductDate(item.installedDate!)),
        if (item.note?.trim().isNotEmpty == true)
          _InfoRow(label: '메모', value: item.note!.trim()),
      ],
    );
  }
}

class _VerifiedModelCard extends StatelessWidget {
  const _VerifiedModelCard({
    required this.item,
    required this.onOpenSource,
  });

  final ZoneItem item;
  final ValueChanged<String> onOpenSource;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 104,
                height: 104,
                child: Image.network(
                  item.modelImageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_not_supported_outlined, size: 36),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Chip(
                      avatar: Icon(Icons.verified_outlined, size: 16),
                      label: Text('공식 모델 확인'),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.modelDisplayName ?? item.modelName ?? item.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (item.modelName?.isNotEmpty == true)
                      Text(
                        item.modelName!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (item.modelReleaseYear != null)
                      Text(
                        '${item.modelReleaseYear}년 출시',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (item.modelFeatures.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final feature in item.modelFeatures)
                  Chip(
                    label: Text(feature),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '제품 식별은 공식 모델 기준이며, 관리법은 현재 시리즈 공통 안내입니다.',
                ),
              ),
              if (item.officialProductUrl?.isNotEmpty == true)
                IconButton(
                  tooltip: '공식 제품 페이지',
                  onPressed: () => onOpenSource(item.officialProductUrl!),
                  icon: const Icon(Icons.open_in_new),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatProductDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}.$month.$day';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStatus extends StatelessWidget {
  const _GuideStatus({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 7),
            child: Icon(Icons.circle, size: 6),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.text,
  });

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            child: Text('$number'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(text),
            ),
          ),
        ],
      ),
    );
  }
}
