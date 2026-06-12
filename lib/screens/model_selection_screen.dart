import 'package:flutter/material.dart';

import '../data/visual_product_candidates.dart';
import '../models/catalog_model_option.dart';
import '../models/product_finder_result.dart';
import '../models/visual_product_candidate.dart';
import '../repositories/product_catalog_repository.dart';

class ModelSelectionScreen extends StatefulWidget {
  const ModelSelectionScreen({
    required this.categoryName,
    required this.brand,
    required this.catalogRepository,
    this.selectedModel,
    super.key,
  });

  final String categoryName;
  final String brand;
  final ProductCatalogRepository catalogRepository;
  final String? selectedModel;

  @override
  State<ModelSelectionScreen> createState() => _ModelSelectionScreenState();
}

class _ModelSelectionScreenState extends State<ModelSelectionScreen> {
  String _query = '';
  int? _releaseYear;
  _FinderMode _mode = _FinderMode.models;
  bool _isLoading = true;
  List<CatalogModelOption> _models = [];

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _normalize(_query);
    final filteredModels = _models
        .where(
          (model) =>
              (_releaseYear == null || model.releaseYear == _releaseYear) &&
              (normalizedQuery.isEmpty ||
                  _normalize(model.modelName).contains(normalizedQuery) ||
                  _normalize(model.displayName).contains(normalizedQuery)),
        )
        .toList();
    final visualCandidates = visualCandidatesFor(
      categoryName: widget.categoryName,
      brand: widget.brand,
    )
        .where(
          (candidate) =>
              normalizedQuery.isEmpty ||
              _normalize(candidate.displayName).contains(normalizedQuery) ||
              _normalize(candidate.formFactor).contains(normalizedQuery) ||
              candidate.features.any(
                (feature) => _normalize(feature).contains(normalizedQuery),
              ),
        )
        .toList();
    final releaseYears = {
      for (final model in _models)
        if (model.releaseYear != null) model.releaseYear!,
    }.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: const Text('내 제품 찾기')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            '${widget.brand} ${widget.categoryName}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text('이미지와 출시 시기를 비교해 내 제품과 가장 가까운 후보를 골라보세요.'),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: '제품 검색',
              hintText: '모델명, 시리즈 또는 외형 특징',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 14),
          SegmentedButton<_FinderMode>(
            segments: const [
              ButtonSegment(
                value: _FinderMode.models,
                icon: Icon(Icons.list_alt_outlined),
                label: Text('정확한 모델'),
              ),
              ButtonSegment(
                value: _FinderMode.visual,
                icon: Icon(Icons.image_search_outlined),
                label: Text('외형으로 찾기'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) {
              setState(() {
                _mode = selection.single;
                if (_mode == _FinderMode.visual) {
                  _releaseYear = null;
                }
              });
            },
          ),
          if (_mode == _FinderMode.models && releaseYears.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('출시 시기', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('전체'),
                    selected: _releaseYear == null,
                    onSelected: (_) => setState(() => _releaseYear = null),
                  ),
                  for (final year in releaseYears) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('$year년'),
                      selected: _releaseYear == year,
                      onSelected: (_) => setState(() => _releaseYear = year),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if ((_mode == _FinderMode.models && filteredModels.isEmpty) ||
              (_mode == _FinderMode.visual && visualCandidates.isEmpty))
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('조건에 맞는 후보가 없어요. 모델명을 직접 입력할 수 있어요.'),
            )
          else ...[
            if (_mode == _FinderMode.models && filteredModels.isNotEmpty) ...[
              Text('모델 후보', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final model in filteredModels)
                _ModelCard(
                  model: model,
                  selected: widget.selectedModel == model.modelName,
                  onSelected: () => _finish(
                    ProductFinderResult.exact(model.modelName),
                  ),
                ),
            ],
            if (_mode == _FinderMode.visual && visualCandidates.isNotEmpty) ...[
              Text(
                '모델명을 모를 때',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              const Text('문 구조와 외형이 비슷한 제품을 고르면 시리즈 공통 관리법을 연결해요.'),
              const SizedBox(height: 10),
              for (final candidate in visualCandidates)
                _VisualCandidateCard(
                  candidate: candidate,
                  onSelected: () => _finish(
                    ProductFinderResult.similar(candidate),
                  ),
                ),
            ],
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _enterModelManually,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('모델명 직접 입력'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadModels() async {
    final models = await widget.catalogRepository.modelsFor(
      category: widget.categoryName,
      brand: widget.brand,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _models = models;
      _isLoading = false;
    });
  }

  Future<void> _enterModelManually() async {
    var input = _query.trim();
    final model = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모델명 직접 입력'),
        content: TextFormField(
          initialValue: input,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: '모델명',
            hintText: '제품 라벨의 모델명을 그대로 입력하세요',
          ),
          onChanged: (value) => input = value,
          onFieldSubmitted: (value) {
            final model = value.trim();
            if (model.isNotEmpty) {
              Navigator.of(context).pop(model);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final model = input.trim();
              if (model.isNotEmpty) {
                Navigator.of(context).pop(model);
              }
            },
            child: const Text('입력'),
          ),
        ],
      ),
    );
    if (model != null && mounted) {
      _finish(ProductFinderResult.exact(model));
    }
  }

  void _finish(ProductFinderResult result) {
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    });
  }
}

class _ModelCard extends StatelessWidget {
  const _ModelCard({
    required this.model,
    required this.selected,
    required this.onSelected,
  });

  final CatalogModelOption model;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ModelThumbnail(imageUrl: model.imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.displayName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(model.modelName),
                  if (model.releaseYear != null)
                    Text(
                      '${model.releaseYear}년 출시',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    onPressed: onSelected,
                    icon: Icon(
                      selected ? Icons.check_circle : Icons.verified_outlined,
                    ),
                    label: const Text('정확해요'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelThumbnail extends StatelessWidget {
  const _ModelThumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return Container(
        width: 88,
        height: 104,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.inventory_2_outlined, size: 48),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        url,
        width: 88,
        height: 104,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          return const SizedBox.square(
            dimension: 88,
            child: Icon(Icons.inventory_2_outlined),
          );
        },
      ),
    );
  }
}

class _VisualCandidateCard extends StatelessWidget {
  const _VisualCandidateCard({
    required this.candidate,
    required this.onSelected,
  });

  final VisualProductCandidate candidate;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 88,
              height: 112,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(candidate.icon, size: 52),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.displayName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(candidate.releasePeriod),
                  const SizedBox(height: 6),
                  Text(candidate.features.join(' · ')),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: onSelected,
                    icon: const Icon(Icons.image_search_outlined),
                    label: const Text('비슷해요'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _normalize(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '');
}

enum _FinderMode { models, visual }
