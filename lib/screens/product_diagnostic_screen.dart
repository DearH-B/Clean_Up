import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/product_diagnostics.dart';
import '../models/product_diagnostic.dart';
import '../models/zone_item.dart';
import '../repositories/product_diagnostic_repository.dart';
import '../utils/external_link_launcher.dart';

class ProductDiagnosticScreen extends StatefulWidget {
  const ProductDiagnosticScreen({
    required this.item,
    this.linkLauncher = launchExternalLink,
    this.diagnosticRepository = const LocalProductDiagnosticRepository(),
    super.key,
  });

  final ZoneItem item;
  final ExternalLinkLauncher linkLauncher;
  final ProductDiagnosticRepository diagnosticRepository;

  @override
  State<ProductDiagnosticScreen> createState() =>
      _ProductDiagnosticScreenState();
}

class _ProductDiagnosticScreenState extends State<ProductDiagnosticScreen> {
  ProductDiagnostic? _selected;
  bool? _confirmed;
  late List<ProductDiagnostic> _diagnostics;

  @override
  void initState() {
    super.initState();
    _diagnostics = diagnosticsForProduct(widget.item.name);
    _loadDiagnostics();
  }

  Future<void> _loadDiagnostics() async {
    final diagnostics = await widget.diagnosticRepository.diagnosticsFor(
      widget.item.name,
    );
    if (!mounted) {
      return;
    }
    if (diagnostics.isNotEmpty) {
      setState(() {
        final selectedId = _selected?.id;
        _diagnostics = diagnostics;
        if (selectedId != null) {
          _selected = diagnostics
              .where((diagnostic) => diagnostic.id == selectedId)
              .firstOrNull;
          if (_selected == null) {
            _confirmed = null;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final diagnostics = _diagnostics;
    return Scaffold(
      appBar: AppBar(title: const Text('문제 확인')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            widget.item.displayName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('고장을 확정하는 진단이 아니며, 안전하게 다음 행동을 고르는 안내입니다.'),
          const SizedBox(height: 28),
          const _StepLabel(number: 1, text: '가장 가까운 증상을 선택하세요'),
          const SizedBox(height: 12),
          RadioGroup<ProductDiagnostic>(
            groupValue: _selected,
            onChanged: (value) {
              setState(() {
                _selected = value;
                _confirmed = null;
              });
            },
            child: Column(
              children: [
                for (final diagnostic in diagnostics)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RadioListTile<ProductDiagnostic>(
                      value: diagnostic,
                      title: Text(diagnostic.symptom),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                        side: BorderSide(
                          color: _selected == diagnostic
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_selected != null) ...[
            const SizedBox(height: 24),
            const _StepLabel(number: 2, text: '현재 상태를 확인하세요'),
            const SizedBox(height: 12),
            Text(
              _selected!.question,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('네')),
                ButtonSegment(value: false, label: Text('아니요 / 모르겠어요')),
              ],
              selected: _confirmed == null ? const {} : {_confirmed!},
              emptySelectionAllowed: true,
              onSelectionChanged: (selection) {
                setState(() =>
                    _confirmed = selection.isEmpty ? null : selection.first);
              },
            ),
          ],
          if (_selected != null && _confirmed != null) ...[
            const SizedBox(height: 28),
            _DiagnosticResult(
              diagnostic: _selected!,
              confirmed: _confirmed!,
              onOpen: _open,
            ),
            const SizedBox(height: 16),
            if (widget.item.officialManualUrl?.isNotEmpty == true)
              FilledButton.tonalIcon(
                onPressed: () => _open(widget.item.officialManualUrl!),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('공식 설명서 확인'),
              ),
            if (widget.item.supportUrl?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _open(widget.item.supportUrl!),
                icon: const Icon(Icons.support_agent_outlined),
                label: const Text('공식 고객지원'),
              ),
            ],
            if (widget.item.servicePhone?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _open('tel:${widget.item.servicePhone}'),
                icon: const Icon(Icons.call_outlined),
                label: Text('서비스센터 ${widget.item.servicePhone}'),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _open(String value) async {
    final uri = Uri.tryParse(value);
    var opened = false;
    try {
      if (uri != null && uri.hasScheme) {
        opened = await widget.linkLauncher(uri);
      }
    } on Object {
      opened = false;
    }
    if (opened || !mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('연결할 수 없어요. 주소나 전화번호를 복사해 다시 확인할 수 있어요.'),
        action: SnackBarAction(
          label: '복사',
          onPressed: () => Clipboard.setData(ClipboardData(text: value)),
        ),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          child: Text('$number'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.titleMedium),
        ),
      ],
    );
  }
}

class _DiagnosticResult extends StatelessWidget {
  const _DiagnosticResult({
    required this.diagnostic,
    required this.confirmed,
    required this.onOpen,
  });

  final ProductDiagnostic diagnostic;
  final bool confirmed;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final urgent = diagnostic.requiresStop && confirmed;
    final title =
        urgent ? '사용을 멈추고 전문가에게 문의하세요' : _outcomeLabel(diagnostic.outcome);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: urgent
              ? Theme.of(context).colorScheme.errorContainer
              : Theme.of(context).colorScheme.primaryContainer,
          border: Border.all(
            color: urgent
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(urgent ? Icons.warning_amber : Icons.fact_check_outlined),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(diagnostic.safeAction),
            if (diagnostic.steps.isNotEmpty) ...[
              const SizedBox(height: 18),
              _DiagnosticSection(
                title: '대처 순서',
                icon: Icons.format_list_numbered,
                child: Column(
                  children: [
                    for (var index = 0;
                        index < diagnostic.steps.length;
                        index++)
                      _DiagnosticStep(
                        number: index + 1,
                        text: diagnostic.steps[index],
                      ),
                  ],
                ),
              ),
            ],
            if (diagnostic.tools.isNotEmpty) ...[
              const SizedBox(height: 12),
              _DiagnosticSection(
                title: '필요한 도구',
                icon: Icons.handyman_outlined,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tool in diagnostic.tools)
                      Chip(label: Text(tool)),
                  ],
                ),
              ),
            ],
            if (diagnostic.recommendedProducts.isNotEmpty) ...[
              const SizedBox(height: 12),
              _DiagnosticSection(
                title: '제품 추천',
                icon: Icons.shopping_bag_outlined,
                child: Column(
                  children: [
                    for (final product in diagnostic.recommendedProducts)
                      _RecommendedProductTile(
                        product: product,
                        onOpen: onOpen,
                      ),
                  ],
                ),
              ),
            ],
            if (diagnostic.caution != null) ...[
              const SizedBox(height: 12),
              _DiagnosticSection(
                title: '주의',
                icon: Icons.warning_amber_outlined,
                child: Text(
                  diagnostic.caution!,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
            if (diagnostic.warningSigns.isNotEmpty) ...[
              const SizedBox(height: 12),
              _DiagnosticSection(
                title: '즉시 중단 신호',
                icon: Icons.report_gmailerrorred_outlined,
                child: Text(
                  diagnostic.warningSigns.join(', '),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _DiagnosticSection(
              title: '근거',
              icon: Icons.fact_check_outlined,
              child:
                  _DiagnosticEvidence(diagnostic: diagnostic, onOpen: onOpen),
            ),
          ],
        ),
      ),
    );
  }

  String _outcomeLabel(DiagnosticOutcome outcome) => switch (outcome) {
        DiagnosticOutcome.selfCare => '안전한 범위에서 직접 확인할 수 있어요',
        DiagnosticOutcome.checkManual => '공식 설명서를 먼저 확인하세요',
        DiagnosticOutcome.replaceConsumable => '소모품 상태도 함께 확인하세요',
        DiagnosticOutcome.stopUsing => '사용 중단이 필요한 증상일 수 있어요',
        DiagnosticOutcome.professionalSupport => '전문가 점검을 권장해요',
      };
}

class _DiagnosticSection extends StatelessWidget {
  const _DiagnosticSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DiagnosticStep extends StatelessWidget {
  const _DiagnosticStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            child: Text(
              '$number',
              style: const TextStyle(fontSize: 11),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _RecommendedProductTile extends StatelessWidget {
  const _RecommendedProductTile({
    required this.product,
    required this.onOpen,
  });

  final DiagnosticProductRecommendation product;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onOpen(product.url),
        borderRadius: BorderRadius.circular(3),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.open_in_new, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${product.brand} ${product.name}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(product.reason),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _EvidenceBadge(
                          label: product.isSearchLink ? '판매처 검색' : '상품 상세',
                        ),
                        _EvidenceBadge(
                          label: product.isSponsored ? '광고·제휴' : '광고 아님',
                        ),
                      ],
                    ),
                    if (product.suitableMaterials.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '사용 재질: ${product.suitableMaterials.join(', ')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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

class _EvidenceBadge extends StatelessWidget {
  const _EvidenceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _DiagnosticEvidence extends StatelessWidget {
  const _DiagnosticEvidence({
    required this.diagnostic,
    required this.onOpen,
  });

  final ProductDiagnostic diagnostic;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final sourceUrl = diagnostic.sourceUrl;
    final sources = diagnostic.sources;
    final officialSourceCount =
        sources.where((source) => source.isOfficial).length;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined, size: 19),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  diagnostic.reviewStatus.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${diagnostic.basisType.label} · ${diagnostic.reviewedAt} 검토'),
          const SizedBox(height: 4),
          Text(diagnostic.sourceTitle),
          if (officialSourceCount > 0) ...[
            const SizedBox(height: 6),
            Text(
              '공식 근거 $officialSourceCount건',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
          if (diagnostic.applicableMaterials.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '적용 전 확인: ${diagnostic.applicableMaterials.join(', ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (sources.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final source in sources)
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    source.isOfficial
                        ? Icons.verified_outlined
                        : Icons.description_outlined,
                    size: 20,
                  ),
                  title: Text(source.title),
                  subtitle: Text(
                    '${source.publisher} · ${source.checkedAt} 확인',
                  ),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => onOpen(source.url),
                ),
              ),
          ] else if (sourceUrl?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => onOpen(sourceUrl!),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('근거 자료 확인'),
            ),
          ],
        ],
      ),
    );
  }
}
