import 'package:flutter/material.dart';

import '../models/cleaning_record.dart';

class RecordTile extends StatelessWidget {
  const RecordTile({
    required this.record,
    super.key,
  });

  final CleaningRecord record;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Text(
            '${record.minutes}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(
          record.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${record.zoneName} · ${_formatDateTime(record.completedAt)}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$month.$day $hour:$minute';
  }
}
