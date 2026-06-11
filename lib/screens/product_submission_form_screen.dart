import 'package:flutter/material.dart';

import '../models/product_submission.dart';
import '../models/zone_item.dart';
import '../repositories/product_data_repository.dart';

class ProductSubmissionFormScreen extends StatefulWidget {
  const ProductSubmissionFormScreen({
    required this.dataRepository,
    this.product,
    this.initialType,
    this.initialTitle,
    super.key,
  });

  final ProductDataRepository dataRepository;
  final ZoneItem? product;
  final ProductSubmissionType? initialType;
  final String? initialTitle;

  @override
  State<ProductSubmissionFormScreen> createState() =>
      _ProductSubmissionFormScreenState();
}

class _ProductSubmissionFormScreenState
    extends State<ProductSubmissionFormScreen> {
  late ProductSubmissionType _type;
  late final TextEditingController _titleController;
  final _detailsController = TextEditingController();
  final _sourceUrlController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ??
        (widget.product == null
            ? ProductSubmissionType.missingProduct
            : ProductSubmissionType.incorrectInfo);
    _titleController = TextEditingController(
      text: widget.initialTitle ??
          (widget.product == null
              ? ''
              : '${widget.product!.displayName} 정보 확인 요청'),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    _sourceUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      appBar: AppBar(title: const Text('제품 정보 제보')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          if (product != null) ...[
            _ProductContextCard(product: product),
            const SizedBox(height: 18),
          ],
          DropdownMenu<ProductSubmissionType>(
            key: const ValueKey('submission-type'),
            width: double.infinity,
            initialSelection: _type,
            label: const Text('제보 유형'),
            dropdownMenuEntries: [
              for (final type in ProductSubmissionType.values)
                if (product != null ||
                    type == ProductSubmissionType.missingProduct)
                  DropdownMenuEntry(value: type, label: type.label),
            ],
            onSelected: (value) {
              if (value != null) {
                setState(() => _type = value);
              }
            },
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('submission-title'),
            controller: _titleController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '제목',
              hintText: '확인이 필요한 내용을 짧게 적어주세요',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('submission-details'),
            controller: _detailsController,
            minLines: 5,
            maxLines: 9,
            decoration: const InputDecoration(
              labelText: '자세한 내용',
              hintText: '어떤 정보가 다르거나 위험한지 알려주세요',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _sourceUrlController,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: '참고 링크 (선택)',
              hintText: '제조사 페이지나 공식 설명서 주소',
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.privacy_tip_outlined, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '제보는 바로 공개되지 않으며 운영자 확인 후 제품 정보에 반영됩니다. '
                    '이름, 주소, 전화번호 같은 개인정보는 적지 마세요.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            10 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.outbox_outlined),
            label: const Text('요청 내역에 저장'),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final details = _detailsController.text.trim();
    if (title.isEmpty || details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 자세한 내용을 입력해 주세요.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final now = DateTime.now();
    final product = widget.product;
    final submission = ProductSubmission(
      id: 'submission-${now.microsecondsSinceEpoch}',
      type: _type,
      title: title,
      details: details,
      productId: product?.catalogProductId ?? product?.id,
      productName: product?.displayName,
      categoryName: product?.name,
      brand: product?.manufacturer,
      modelName: product?.modelName,
      sourceUrl: _nullIfEmpty(_sourceUrlController.text),
      createdAt: now,
      updatedAt: now,
      status: ProductSubmissionStatus.pendingUpload,
    );
    final existing = await widget.dataRepository.loadProductSubmissions() ?? [];
    await widget.dataRepository.saveProductSubmissions([
      submission,
      ...existing,
    ]);
    if (mounted) {
      Navigator.of(context).pop(submission);
    }
  }
}

class _ProductContextCard extends StatelessWidget {
  const _ProductContextCard({required this.product});

  final ZoneItem product;

  @override
  Widget build(BuildContext context) {
    final identity = [
      product.manufacturer,
      product.modelName,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' · ');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (identity.isNotEmpty) Text(identity),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String? _nullIfEmpty(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
