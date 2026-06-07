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
        title: Text(item.name),
        subtitle: Text(
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
}
