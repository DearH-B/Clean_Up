import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/cleaning_record.dart';
import '../models/zone_item.dart';
import '../repositories/cleaning_data_repository.dart';

class ZoneItemDetailScreen extends StatefulWidget {
  const ZoneItemDetailScreen({
    required this.item,
    required this.dataRepository,
    this.onItemUpdated,
    super.key,
  });

  final ZoneItem item;
  final CleaningDataRepository dataRepository;
  final ValueChanged<ZoneItem>? onItemUpdated;

  @override
  State<ZoneItemDetailScreen> createState() => _ZoneItemDetailScreenState();
}

class _ZoneItemDetailScreenState extends State<ZoneItemDetailScreen> {
  late ZoneItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_item.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                child: Icon(_iconFor(_item.type)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _item.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text('${_item.type.label} · ${_item.frequency}'),
                    const SizedBox(height: 8),
                    _GuideSourceBadge(sourceType: _item.guideSourceType),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(_item.summary),
          const SizedBox(height: 16),
          _ScheduleCard(
            item: _item,
            onComplete: _completeCleaning,
          ),
          const SizedBox(height: 16),
          if (!_item.hasProductInfo)
            OutlinedButton.icon(
              onPressed: _showProductInfoSheet,
              icon: const Icon(Icons.add),
              label: const Text('브랜드·모델 등록'),
            ),
          if (_item.hasProductInfo) ...[
            const SizedBox(height: 20),
            _ProductInfo(item: _item),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _showProductInfoSheet,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('제품 정보 수정'),
              ),
            ),
          ],
          if (_item.guideStatus != null) ...[
            const SizedBox(height: 12),
            _GuideStatus(message: _item.guideStatus!),
          ],
          if (_item.guideBasis != null) ...[
            const SizedBox(height: 12),
            _GuideBasis(message: _item.guideBasis!),
          ],
          if (_item.guideVideoUrl != null) ...[
            const SizedBox(height: 12),
            _GuideVideoCard(
              title: _item.guideVideoTitle ?? '세척 영상',
              channel: _item.guideVideoChannel ?? 'YouTube',
              onTap: () => _openGuideVideo(_item.guideVideoUrl!),
            ),
          ],
          const SizedBox(height: 24),
          _Section(
            title: '준비물',
            icon: Icons.cleaning_services_outlined,
            children: [
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
          if (_item.recommendedSupplies.isNotEmpty)
            _Section(
              title: '청소용품 추천',
              icon: Icons.shopping_bag_outlined,
              children: [
                for (final recommendation in _item.recommendedSupplies)
                  _RecommendationTile(text: recommendation),
                const SizedBox(height: 4),
                Text(
                  '광고 또는 제휴가 있는 제품은 반드시 별도 표시하고, 추천 이유를 함께 안내해요.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          if (_item.recommendedProducts.isNotEmpty)
            _Section(
              title: '추천 제품',
              icon: Icons.featured_play_list_outlined,
              children: [
                for (final product in _item.recommendedProducts)
                  _ProductRecommendationCard(
                    product: product,
                    onTap: () => _openProduct(product.url),
                  ),
                Text(
                  '추천 제품은 사용 전 반드시 제품 표면과 제조사 지침을 확인하세요.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          _Section(
            title: '먼저 확인하세요',
            icon: Icons.warning_amber_outlined,
            children: [
              for (final caution in _item.cautions) _BulletText(text: caution),
            ],
          ),
          _Section(
            title: '청소 순서',
            icon: Icons.format_list_numbered,
            children: [
              for (var index = 0; index < _item.steps.length; index++)
                _StepTile(
                  number: index + 1,
                  text: _item.steps[index],
                ),
            ],
          ),
          Text(
            '제품의 공식 사용설명서와 안전 지침이 이 안내보다 우선합니다.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
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

  Future<void> _showProductInfoSheet() async {
    final updatedItem = await showModalBottomSheet<ZoneItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ProductInfoSheet(item: _item),
    );

    if (updatedItem == null || !mounted) {
      return;
    }

    setState(() {
      _item = updatedItem;
    });
    widget.onItemUpdated?.call(updatedItem);
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

  Future<void> _completeCleaning() async {
    final now = DateTime.now();
    final updatedItem = _item.copyWith(
      lastCleanedAt: now,
      nextDueAt: now.add(Duration(days: _item.recurrenceDays)),
    );
    final savedRecords = await widget.dataRepository.loadRecords();
    final records = [
      CleaningRecord(
        id: 'record-${now.microsecondsSinceEpoch}',
        title: '${_item.name} 청소 완료',
        zoneName: _item.name,
        completedAt: now,
        minutes: _item.estimatedMinutes,
      ),
      ...(savedRecords ?? const <CleaningRecord>[]),
    ];

    await widget.dataRepository.saveRecords(records);
    if (!mounted) {
      return;
    }

    setState(() {
      _item = updatedItem;
    });
    widget.onItemUpdated?.call(updatedItem);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('청소 기록에 저장했어요. 다음 일정도 갱신됐어요.')),
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
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nextDueAt == null
                      ? '아직 예정일이 없어요'
                      : '다음 예정일 ${_formatDate(item.nextDueAt!)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text('${item.frequency} · 예상 ${item.estimatedMinutes}분'),
              ],
            ),
          ),
          FilledButton(
            onPressed: onComplete,
            child: const Text('완료'),
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
                  '이 청소법의 참고 기준',
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
  const _ProductInfoSheet({required this.item});

  final ZoneItem item;

  @override
  State<_ProductInfoSheet> createState() => _ProductInfoSheetState();
}

class _ProductInfoSheetState extends State<_ProductInfoSheet> {
  late final TextEditingController _manufacturerController;
  late final TextEditingController _modelController;
  late bool _customBrand;

  @override
  void initState() {
    super.initState();
    _manufacturerController = TextEditingController(
      text: widget.item.manufacturer,
    );
    _modelController = TextEditingController(text: widget.item.modelName);
    _customBrand = !_brandOptions.contains(widget.item.manufacturer) &&
        (widget.item.manufacturer?.isNotEmpty ?? false);
  }

  @override
  void dispose() {
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
            _ChoiceSection(
              title: '브랜드',
              helperText: '브랜드를 고르면 아래 모델 후보가 바뀌어요.',
              options: _brandOptionsFor(widget.item.name),
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
                  : '${_manufacturerController.text.trim()} ${widget.item.name} 대표 모델이에요.',
              options: _modelOptionsFor(
                widget.item.name,
                _manufacturerController.text.trim(),
              ),
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
                hintText: '제품 라벨의 모델명을 그대로 적어도 좋아요.',
              ),
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

    Navigator.of(context).pop(
      widget.item.copyWith(
        manufacturer: manufacturer,
        modelName: modelName,
        guideStatus: '등록된 제품 정보를 바탕으로 공식 안내를 확인할 수 있어요.',
      ),
    );
  }

  void _selectBrand(String brand) {
    setState(() {
      _customBrand = false;
      _manufacturerController.text = brand;
      _modelController.clear();
    });
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

const _brandOptions = [
  '삼성전자',
  'LG전자',
  '위니아',
  '쿠쿠',
  '쿠첸',
  '다이슨',
  '샤오미',
  '에코업',
  '제이앤에이치컴퍼니',
];

List<String> _brandOptionsFor(String itemName) {
  if (itemName.contains('음식물')) {
    return const ['에코업', '제이앤에이치컴퍼니', '쿠쿠', '스마트카라'];
  }
  if (itemName.contains('냉장고')) {
    return const ['삼성전자', 'LG전자', '위니아'];
  }
  if (itemName.contains('전자레인지')) {
    return const ['삼성전자', 'LG전자', '쿠쿠'];
  }
  if (itemName.contains('공기청정')) {
    return const ['삼성전자', 'LG전자', '다이슨', '샤오미'];
  }
  return _brandOptions;
}

List<String> _modelOptionsFor(String itemName, String brand) {
  if (itemName.contains('음식물')) {
    if (brand == '에코업' || brand == '제이앤에이치컴퍼니') {
      return const ['DCS-HM4AG-W', 'DCS-HM4AG', 'ECO-UP'];
    }
    if (brand == '쿠쿠') return const ['CFD-BG202MOG', 'CFD-BG202M'];
    if (brand == '스마트카라') return const ['PCS-400', 'PCS-500D'];
  }
  if (itemName.contains('냉장고')) {
    if (brand == '삼성전자') {
      return const ['RF85C90F1AP', 'RF85C9141AP', 'RF60C9013AP'];
    }
    if (brand == 'LG전자') {
      return const ['M874GBB031', 'T873MEE312', 'S834MTE10'];
    }
    if (brand == '위니아') {
      return const ['WRB480DMS', 'WRT50DS', 'ERB48DWG'];
    }
  }
  if (itemName.contains('공기청정')) {
    if (brand == '삼성전자') return const ['AX060B510RSD', 'AX033B310GBD'];
    if (brand == 'LG전자') return const ['AS193DWFA', 'AS120VELA'];
    if (brand == '다이슨') return const ['PH04', 'TP07', 'HP07'];
    if (brand == '샤오미') return const ['Mi Air 3H', 'Smart Air 4'];
  }
  if (itemName.contains('전자레인지')) {
    if (brand == '삼성전자') return const ['MS23K3513AW', 'MS23T5018AK'];
    if (brand == 'LG전자') return const ['MW23BD', 'MW25B'];
    if (brand == '쿠쿠') return const ['CMW-A201DW', 'CMW-A201DB'];
  }
  return const [];
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
        if (item.modelName != null)
          _InfoRow(label: '모델명', value: item.modelName!),
        if (item.productMethod != null)
          _InfoRow(label: '처리 방식', value: item.productMethod!),
      ],
    );
  }
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
