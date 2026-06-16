import 'package:flutter/material.dart';

import '../models/zone_item.dart';
import '../theme/app_theme.dart';

class ZoneItemTile extends StatelessWidget {
  const ZoneItemTile({
    required this.item,
    required this.onTap,
    required this.onSolveProblem,
    super.key,
  });

  final ZoneItem item;
  final VoidCallback onTap;
  final VoidCallback onSolveProblem;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        leading: Container(
          width: 44,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(_iconFor(item), color: AppColors.ink),
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
                  if (item.nextDueAt != null)
                    _MiniBadge(label: '다음 ${_formatDue(item.nextDueAt!)}'),
                ],
              ),
            ],
          ),
        ),
        trailing: IconButton(
          tooltip: '문제 해결',
          onPressed: onSolveProblem,
          icon: const Icon(Icons.handyman_outlined),
        ),
      ),
    );
  }

  IconData _iconFor(ZoneItem item) {
    final name = item.name.replaceAll(' ', '');
    if (name.contains('냉장고')) return Icons.kitchen_outlined;
    if (name.contains('세면대')) return Icons.wash_outlined;
    if (name.contains('변기')) return Icons.wc_outlined;
    if (name.contains('침대') || name.contains('매트리스')) {
      return Icons.bed_outlined;
    }
    if (name.contains('TV')) return Icons.tv_outlined;
    if (name.contains('세탁기')) return Icons.local_laundry_service_outlined;
    if (name.contains('공기청정기') || name.contains('환풍기')) {
      return Icons.air_outlined;
    }
    return switch (item.type) {
      ZoneItemType.appliance => Icons.kitchen_outlined,
      ZoneItemType.furniture => Icons.chair_outlined,
      ZoneItemType.fixture => Icons.countertops_outlined,
      ZoneItemType.other => Icons.inventory_2_outlined,
    };
  }

  String _formatDue(DateTime dateTime) {
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppColors.ink),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
