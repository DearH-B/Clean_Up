import 'package:flutter/material.dart';

import '../models/product_space.dart';
import '../theme/app_theme.dart';

class SpaceCard extends StatelessWidget {
  const SpaceCard({
    required this.space,
    required this.index,
    required this.onTap,
    super.key,
  });

  final ProductSpace space;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const colors = [
      AppColors.warmGray,
      AppColors.steelSoft,
      AppColors.coralSoft,
      AppColors.graySoft,
    ];
    const icons = [
      Icons.soup_kitchen_outlined,
      Icons.weekend_outlined,
      Icons.bathtub_outlined,
      Icons.bed_outlined,
    ];
    final accent = colors[index % colors.length];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icons[index % icons.length]),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      space.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                space.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    '${space.identifiedProductCount}/${space.productCount} 제품 확인',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: space.identificationProgress),
            ],
          ),
        ),
      ),
    );
  }
}
