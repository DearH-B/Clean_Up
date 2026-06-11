import 'package:flutter/material.dart';

import '../models/care_record.dart';

class RecordTile extends StatelessWidget {
  const RecordTile({
    required this.record,
    this.onTap,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final CareRecord record;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(
            _iconFor(record.type),
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        title: Text(
          record.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            record.spaceName,
            record.type.label,
            _formatDateTime(record.completedAt),
            if (record.minutes > 0) '${record.minutes}분',
          ].join(' · '),
        ),
        trailing: onEdit == null && onDelete == null
            ? const Icon(Icons.chevron_right)
            : PopupMenuButton<String>(
                tooltip: '기록 메뉴',
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit?.call();
                  } else if (value == 'delete') {
                    onDelete?.call();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('수정')),
                  PopupMenuItem(value: 'delete', child: Text('삭제')),
                ],
              ),
      ),
    );
  }
}

IconData _iconFor(CareRecordType type) {
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

String _formatDateTime(DateTime dateTime) {
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$month.$day $hour:$minute';
}
