import 'package:flutter/material.dart';

import '../data/visual_product_candidates.dart';
import '../models/visual_product_candidate.dart';

class VisualProductFinderScreen extends StatefulWidget {
  const VisualProductFinderScreen({
    required this.categoryName,
    required this.brand,
    super.key,
  });

  final String categoryName;
  final String brand;

  @override
  State<VisualProductFinderScreen> createState() =>
      _VisualProductFinderScreenState();
}

class _VisualProductFinderScreenState extends State<VisualProductFinderScreen> {
  String? _releaseFilter;

  @override
  Widget build(BuildContext context) {
    final candidates = visualCandidatesFor(
      categoryName: widget.categoryName,
      brand: widget.brand,
    );
    final filtered = _releaseFilter == null
        ? candidates
        : candidates
            .where((candidate) => candidate.releasePeriod == _releaseFilter)
            .toList();
    final periods =
        {for (final item in candidates) item.releasePeriod}.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('외형으로 제품 찾기')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            '${widget.brand.isEmpty ? widget.categoryName : '${widget.brand} ${widget.categoryName}'}와 비슷한 형태를 골라주세요',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text(
            '정확한 품번을 확정하지 않아요. 문 개수와 내부 구조가 비슷하면 공통 관리법을 연결합니다.',
          ),
          if (periods.isNotEmpty) ...[
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('전체 연식'),
                    selected: _releaseFilter == null,
                    onSelected: (_) => setState(() => _releaseFilter = null),
                  ),
                  const SizedBox(width: 8),
                  for (final period in periods) ...[
                    ChoiceChip(
                      label: Text(period),
                      selected: _releaseFilter == period,
                      onSelected: (_) {
                        setState(() => _releaseFilter = period);
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          for (final candidate in filtered)
            _CandidateCard(
              candidate: candidate,
              onSelected: () => Navigator.of(context).pop(candidate),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.help_outline),
            label: const Text('비슷한 제품이 없어요'),
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.candidate,
    required this.onSelected,
  });

  final VisualProductCandidate candidate;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 92,
                height: 116,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Icon(candidate.icon, size: 58),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(candidate.formFactor),
                    Text(
                      candidate.releasePeriod,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 9),
                    for (final feature in candidate.features)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text('• $feature'),
                      ),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: onSelected,
                      child: const Text('이 제품과 비슷해요'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
