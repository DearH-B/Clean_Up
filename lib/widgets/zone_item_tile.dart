import 'package:flutter/material.dart';

import '../models/zone_item.dart';

class ZoneItemTile extends StatelessWidget {
  const ZoneItemTile({
    required this.item,
    required this.onTap,
    super.key,
  });

  final ZoneItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          child: Icon(_iconFor(item.type)),
        ),
        title: Text(item.displayName),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.hasProductInfo
                    ? [
                        item.manufacturer,
                        item.modelName,
                      ]
                        .whereType<String>()
                        .where((text) => text.isNotEmpty)
                        .join(' · ')
                    : '${item.type.label} · 제품 정보 없음',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.displayName != item.name) ...[
                const SizedBox(height: 3),
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 5),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _MiniBadge(label: item.guideSourceType.label),
                  _MiniBadge(label: '다음 ${_formatDue(item.nextDueAt)}'),
                ],
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
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

  String _formatDue(DateTime? dateTime) {
    if (dateTime == null) {
      return '미정';
    }
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$month.$day';
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
