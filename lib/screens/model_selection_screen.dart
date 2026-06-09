import 'package:flutter/material.dart';

import '../models/catalog_model_option.dart';
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
    final filtered = _models
        .where(
          (model) =>
              normalizedQuery.isEmpty ||
              _normalize(model.modelName).contains(normalizedQuery) ||
              _normalize(model.displayName).contains(normalizedQuery),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('모델 선택')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            '${widget.brand} ${widget.categoryName}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text('제품 라벨과 이미지, 출시연도를 비교해 가장 비슷한 모델을 선택하세요.'),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: '모델 검색',
              hintText: '모델명이나 제품군을 입력하세요',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '등록된 모델 후보가 없어요. 모델명을 직접 입력하거나 건너뛸 수 있어요.',
              ),
            )
          else
            for (final model in filtered)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () => _finish(model.modelName),
                  leading: _ModelThumbnail(imageUrl: model.imageUrl),
                  title: Text(model.displayName),
                  subtitle: Text(
                    [
                      if (model.displayName != model.modelName) model.modelName,
                      if (model.releaseYear != null) '${model.releaseYear}년형',
                    ].isEmpty
                        ? '${widget.brand} ${widget.categoryName}'
                        : [
                            if (model.displayName != model.modelName)
                              model.modelName,
                            if (model.releaseYear != null)
                              '${model.releaseYear}년형',
                          ].join(' · '),
                  ),
                  trailing: Icon(
                    widget.selectedModel == model.modelName
                        ? Icons.check_circle
                        : Icons.chevron_right,
                  ),
                ),
              ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _enterModelManually,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('모델명 직접 입력'),
          ),
          TextButton(
            onPressed: () => _finish(''),
            child: const Text('모델명을 모르겠어요'),
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
      _finish(model);
    }
  }

  void _finish(String model) {
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop(model);
      }
    });
  }
}

class _ModelThumbnail extends StatelessWidget {
  const _ModelThumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return const CircleAvatar(child: Icon(Icons.tv_outlined));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        url,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return const SizedBox.square(
            dimension: 56,
            child: Icon(Icons.inventory_2_outlined),
          );
        },
      ),
    );
  }
}

String _normalize(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '');
}
