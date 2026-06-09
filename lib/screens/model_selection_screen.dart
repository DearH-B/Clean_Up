import 'package:flutter/material.dart';

class ModelSelectionScreen extends StatefulWidget {
  const ModelSelectionScreen({
    required this.categoryName,
    required this.brand,
    required this.models,
    this.selectedModel,
    super.key,
  });

  final String categoryName;
  final String brand;
  final List<String> models;
  final String? selectedModel;

  @override
  State<ModelSelectionScreen> createState() => _ModelSelectionScreenState();
}

class _ModelSelectionScreenState extends State<ModelSelectionScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _normalize(_query);
    final filtered = widget.models
        .where(
          (model) =>
              normalizedQuery.isEmpty ||
              _normalize(model).contains(normalizedQuery),
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
          const Text('제품 라벨의 모델명과 같은 항목을 선택하세요. 정확하지 않으면 직접 입력하거나 건너뛸 수 있어요.'),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: '모델 검색',
              hintText: '모델명의 일부를 입력하세요',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('일치하는 대표 모델이 없습니다. 모델명을 직접 입력할 수 있어요.'),
            )
          else
            for (final model in filtered)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () => Navigator.of(context).pop(model),
                  leading: Icon(
                    widget.selectedModel == model
                        ? Icons.check_circle
                        : Icons.inventory_2_outlined,
                  ),
                  title: Text(model),
                  subtitle: Text('${widget.brand} ${widget.categoryName}'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _enterModelManually,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('모델명 직접 입력'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: const Text('모델명을 모르겠어요'),
          ),
        ],
      ),
    );
  }

  Future<void> _enterModelManually() async {
    final controller = TextEditingController(text: _query);
    final model = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모델명 직접 입력'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: '모델명',
            hintText: '제품 라벨의 모델명을 그대로 입력하세요',
          ),
          onSubmitted: (value) {
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
              final model = controller.text.trim();
              if (model.isNotEmpty) {
                Navigator.of(context).pop(model);
              }
            },
            child: const Text('입력'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (model != null && mounted) {
      Navigator.of(context).pop(model);
    }
  }
}

String _normalize(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '');
}
