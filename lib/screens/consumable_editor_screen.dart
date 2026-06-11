import 'package:flutter/material.dart';

import '../models/product_consumable.dart';

class ConsumableEditorScreen extends StatefulWidget {
  const ConsumableEditorScreen({
    this.consumable,
    super.key,
  });

  final ProductConsumable? consumable;

  @override
  State<ConsumableEditorScreen> createState() => _ConsumableEditorScreenState();
}

class _ConsumableEditorScreenState extends State<ConsumableEditorScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _partNumberController;
  late final TextEditingController _compatibilityController;
  late final TextEditingController _purchaseUrlController;
  late final TextEditingController _noteController;
  late ConsumableType _type;
  late int _replacementDays;
  late bool _isSponsored;
  DateTime? _lastReplacedAt;

  @override
  void initState() {
    super.initState();
    final consumable = widget.consumable;
    _nameController = TextEditingController(text: consumable?.name ?? '');
    _partNumberController =
        TextEditingController(text: consumable?.partNumber ?? '');
    _compatibilityController = TextEditingController(
      text: consumable?.compatibilityLabel ?? '제품 설명서 확인 필요',
    );
    _purchaseUrlController =
        TextEditingController(text: consumable?.purchaseUrl ?? '');
    _noteController = TextEditingController(text: consumable?.note ?? '');
    _type = consumable?.type ?? ConsumableType.filter;
    _replacementDays = consumable?.replacementDays ?? 180;
    _isSponsored = consumable?.isSponsored ?? false;
    _lastReplacedAt = consumable?.lastReplacedAt;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _partNumberController.dispose();
    _compatibilityController.dispose();
    _purchaseUrlController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final replacementDayOptions = {
      30,
      60,
      90,
      180,
      365,
      _replacementDays,
    }.toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.consumable == null ? '소모품 추가' : '소모품 수정'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          TextField(
            key: const ValueKey('consumable-name'),
            controller: _nameController,
            autofocus: widget.consumable == null,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '소모품 이름',
              hintText: '예: 집진·탈취 필터',
            ),
          ),
          const SizedBox(height: 14),
          DropdownMenu<ConsumableType>(
            width: double.infinity,
            initialSelection: _type,
            label: const Text('종류'),
            dropdownMenuEntries: [
              for (final type in ConsumableType.values)
                DropdownMenuEntry(value: type, label: type.label),
            ],
            onSelected: (value) {
              if (value != null) {
                setState(() => _type = value);
              }
            },
          ),
          const SizedBox(height: 14),
          DropdownMenu<int>(
            width: double.infinity,
            initialSelection: _replacementDays,
            label: const Text('교체 또는 보충 주기'),
            dropdownMenuEntries: [
              for (final days in replacementDayOptions)
                DropdownMenuEntry(
                  value: days,
                  label: _replacementPeriodLabel(days),
                ),
            ],
            onSelected: (value) {
              if (value != null) {
                setState(() => _replacementDays = value);
              }
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _compatibilityController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '호환 정보',
              hintText: '예: 모델별 전용 필터 확인 필요',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _partNumberController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '부품 번호 (선택)',
              hintText: '설명서나 기존 필터의 번호를 확인하세요',
            ),
          ),
          const SizedBox(height: 14),
          _LastReplacementField(
            value: _lastReplacedAt,
            onTap: _pickLastReplacement,
            onClear: _lastReplacedAt == null
                ? null
                : () => setState(() => _lastReplacedAt = null),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _purchaseUrlController,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '구매 링크 (선택)',
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('광고 또는 제휴 링크'),
            subtitle: const Text('수익이 발생하는 링크라면 반드시 표시하세요.'),
            value: _isSponsored,
            onChanged: (value) => setState(() => _isSponsored = value),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '메모 (선택)',
              hintText: '교체 표시등이나 사용 환경 등을 적어두세요',
              alignLabelWithHint: true,
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
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('소모품 저장'),
          ),
        ),
      ),
    );
  }

  Future<void> _pickLastReplacement() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _lastReplacedAt ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null && mounted) {
      setState(() => _lastReplacedAt = date);
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('소모품 이름을 입력해 주세요.')),
      );
      return;
    }
    final lastReplacedAt = _lastReplacedAt;
    Navigator.of(context).pop(
      ProductConsumable(
        id: widget.consumable?.id ??
            'consumable-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        type: _type,
        replacementDays: _replacementDays,
        compatibilityLabel: _compatibilityController.text.trim().isEmpty
            ? '제품 설명서 확인 필요'
            : _compatibilityController.text.trim(),
        partNumber: _nullIfEmpty(_partNumberController.text),
        lastReplacedAt: lastReplacedAt,
        nextReplacementAt: lastReplacedAt?.add(
          Duration(days: _replacementDays),
        ),
        purchaseUrl: _nullIfEmpty(_purchaseUrlController.text),
        isSponsored: _isSponsored,
        note: _nullIfEmpty(_noteController.text),
      ),
    );
  }
}

class _LastReplacementField extends StatelessWidget {
  const _LastReplacementField({
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: '마지막 교체일 (선택)',
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  tooltip: '교체일 지우기',
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                ),
        ),
        child: Text(value == null ? '모름' : _formatDate(value!)),
      ),
    );
  }
}

String? _nullIfEmpty(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _replacementPeriodLabel(int days) {
  if (days % 365 == 0) {
    return '약 ${days ~/ 365}년';
  }
  if (days % 30 == 0) {
    return '약 ${days ~/ 30}개월';
  }
  return '약 $days일';
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}.$month.$day';
}
