import 'package:flutter/material.dart';

import '../models/care_record.dart';
import '../models/zone_item.dart';

class CareRecordEditorScreen extends StatefulWidget {
  const CareRecordEditorScreen({
    required this.product,
    required this.spaceId,
    required this.spaceName,
    this.record,
    super.key,
  });

  final ZoneItem product;
  final String spaceId;
  final String spaceName;
  final CareRecord? record;

  @override
  State<CareRecordEditorScreen> createState() => _CareRecordEditorScreenState();
}

class _CareRecordEditorScreenState extends State<CareRecordEditorScreen> {
  late CareRecordType _type;
  late DateTime _completedAt;
  late int _minutes;
  DateTime? _nextCheckAt;
  late final TextEditingController _suppliesController;
  late final TextEditingController _symptomController;
  late final TextEditingController _resultController;
  late final TextEditingController _noteController;

  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _type = record?.type ?? CareRecordType.cleaning;
    _completedAt = record?.completedAt ?? DateTime.now();
    _minutes = record?.minutes ?? widget.product.estimatedMinutes;
    _nextCheckAt = record?.nextCheckAt;
    _suppliesController = TextEditingController(
      text: record?.usedSupplies.join(', ') ?? '',
    );
    _symptomController = TextEditingController(text: record?.symptom ?? '');
    _resultController = TextEditingController(text: record?.result ?? '');
    _noteController = TextEditingController(text: record?.note ?? '');
  }

  @override
  void dispose() {
    _suppliesController.dispose();
    _symptomController.dispose();
    _resultController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minuteOptions = {0, 5, 10, 15, 20, 30, 45, 60, _minutes}.toList()
      ..sort();
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '관리 기록 수정' : '관리 기록 추가'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          _ProductSummary(
            productName: widget.product.displayName,
            spaceName: widget.spaceName,
          ),
          const SizedBox(height: 22),
          Text('기록 유형', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in CareRecordType.values)
                ChoiceChip(
                  label: Text(type.label),
                  selected: _type == type,
                  onSelected: (_) => setState(() => _type = type),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _DateTimeField(
            label: '관리한 날짜와 시간',
            value: _completedAt,
            onTap: _pickCompletedAt,
          ),
          const SizedBox(height: 14),
          DropdownMenu<int>(
            width: double.infinity,
            initialSelection: _minutes,
            label: const Text('소요 시간'),
            dropdownMenuEntries: [
              for (final minutes in minuteOptions)
                DropdownMenuEntry(
                  value: minutes,
                  label: minutes == 0
                      ? '기록하지 않음'
                      : minutes >= 60
                          ? '$minutes분 이상'
                          : '$minutes분',
                ),
            ],
            onSelected: (value) {
              if (value != null) {
                setState(() => _minutes = value);
              }
            },
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('care-record-supplies'),
            controller: _suppliesController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '사용한 용품 (선택)',
              hintText: '예: 중성세제, 극세사 천',
              prefixIcon: Icon(Icons.cleaning_services_outlined),
            ),
          ),
          const SizedBox(height: 14),
          if (_type == CareRecordType.issue ||
              _type == CareRecordType.service) ...[
            TextField(
              key: const ValueKey('care-record-symptom'),
              controller: _symptomController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '문제 증상',
                hintText: '언제부터 어떤 문제가 있었나요?',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
          ],
          TextField(
            key: const ValueKey('care-record-result'),
            controller: _resultController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '관리 결과 (선택)',
              hintText: '관리 후 달라진 점을 적어두세요',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('care-record-note'),
            controller: _noteController,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: '메모 (선택)',
              hintText: '다음 관리 때 기억할 내용을 남겨두세요',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          _OptionalDateField(
            value: _nextCheckAt,
            onTap: _pickNextCheckAt,
            onClear: _nextCheckAt == null
                ? null
                : () => setState(() => _nextCheckAt = null),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.photo_camera_outlined),
                SizedBox(width: 10),
                Expanded(
                  child: Text('사진 첨부는 기기 파일 보관 정책을 정한 뒤 Phase 4 후속으로 연결합니다.'),
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
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_isEditing ? '수정 내용 저장' : '기록 저장'),
          ),
        ),
      ),
    );
  }

  Future<void> _pickCompletedAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _completedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_completedAt),
    );
    if (time == null || !mounted) {
      return;
    }
    setState(() {
      _completedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickNextCheckAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _nextCheckAt ??
          DateTime.now().add(Duration(days: widget.product.recurrenceDays)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null && mounted) {
      setState(() => _nextCheckAt = date);
    }
  }

  void _save() {
    final supplies = _suppliesController.text
        .split(RegExp(r'[,，]'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    final record = CareRecord(
      id: widget.record?.id ??
          'record-${DateTime.now().microsecondsSinceEpoch}',
      title: '${widget.product.displayName} ${_type.label}',
      spaceName: widget.spaceName,
      completedAt: _completedAt,
      minutes: _minutes,
      type: _type,
      productId: widget.product.id,
      productName: widget.product.displayName,
      spaceId: widget.spaceId,
      guideTitle: widget.product.name,
      usedSupplies: supplies,
      symptom: _nullIfEmpty(_symptomController.text),
      result: _nullIfEmpty(_resultController.text),
      note: _nullIfEmpty(_noteController.text),
      photoPaths: widget.record?.photoPaths ?? const [],
      nextCheckAt: _nextCheckAt,
    );
    Navigator.of(context).pop(record);
  }
}

class _ProductSummary extends StatelessWidget {
  const _ProductSummary({
    required this.productName,
    required this.spaceName,
  });

  final String productName;
  final String spaceName;

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
          const Icon(Icons.inventory_2_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(spaceName),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined),
        ),
        child: Text(_formatDateTime(value)),
      ),
    );
  }
}

class _OptionalDateField extends StatelessWidget {
  const _OptionalDateField({
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
          labelText: '다음 확인일 (선택)',
          prefixIcon: const Icon(Icons.event_repeat_outlined),
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  tooltip: '다음 확인일 지우기',
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                ),
        ),
        child: Text(value == null ? '정하지 않음' : _formatDate(value!)),
      ),
    );
  }
}

String? _nullIfEmpty(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
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
