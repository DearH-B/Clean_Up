import 'dart:async';

import 'package:flutter/material.dart';

import '../models/product_submission.dart';
import '../repositories/product_data_repository.dart';
import '../repositories/product_submission_repository.dart';

class ProductSubmissionsScreen extends StatefulWidget {
  const ProductSubmissionsScreen({
    required this.dataRepository,
    required this.submissionRepository,
    super.key,
  });

  final ProductDataRepository dataRepository;
  final ProductSubmissionRepository submissionRepository;

  @override
  State<ProductSubmissionsScreen> createState() =>
      _ProductSubmissionsScreenState();
}

class _ProductSubmissionsScreenState extends State<ProductSubmissionsScreen> {
  List<ProductSubmission> _submissions = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadAndSync());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('제품 정보 요청'),
        actions: [
          IconButton(
            tooltip: '상태 새로고침',
            onPressed: _isSyncing ? null : _sync,
            icon: const Icon(Icons.sync),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _sync,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _submissions.isEmpty
                ? const _EmptySubmissions()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: _submissions.length + 1,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _SyncNotice(isSyncing: _isSyncing);
                      }
                      return _SubmissionCard(
                        submission: _submissions[index - 1],
                        onRetry: _isSyncing ? null : _sync,
                      );
                    },
                  ),
      ),
    );
  }

  Future<void> _loadAndSync() async {
    final submissions =
        await widget.dataRepository.loadProductSubmissions() ?? [];
    if (!mounted) {
      return;
    }
    setState(() {
      _submissions = submissions;
      _isLoading = false;
    });
    if (submissions.isNotEmpty) {
      await _sync();
    }
  }

  Future<void> _sync() async {
    if (_isSyncing) {
      return;
    }
    setState(() => _isSyncing = true);
    final updated = <ProductSubmission>[];
    var failedCount = 0;

    for (final submission in _submissions) {
      try {
        if (submission.status.canUpload) {
          updated.add(await widget.submissionRepository.submit(submission));
        } else if (submission.status.canRefresh) {
          updated.add(await widget.submissionRepository.refresh(submission));
        } else {
          updated.add(submission);
        }
      } on Object {
        failedCount++;
        updated.add(
          submission.status.canUpload
              ? submission.copyWith(
                  status: ProductSubmissionStatus.uploadFailed,
                  updatedAt: DateTime.now(),
                  statusMessage: '서버 연결 후 다시 전송할 수 있어요.',
                )
              : submission,
        );
      }
    }

    await widget.dataRepository.saveProductSubmissions(updated);
    if (!mounted) {
      return;
    }
    setState(() {
      _submissions = updated;
      _isSyncing = false;
    });
    if (failedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '서버에 연결하지 못한 요청 $failedCount개는 기기에 안전하게 보관했어요.',
          ),
        ),
      );
    }
  }
}

class _SyncNotice extends StatelessWidget {
  const _SyncNotice({required this.isSyncing});

  final bool isSyncing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (isSyncing)
            const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(Icons.cloud_done_outlined, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isSyncing
                  ? '요청 상태를 확인하고 있어요.'
                  : '오프라인에서 작성한 요청도 서버 연결 시 다시 전송됩니다.',
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({
    required this.submission,
    required this.onRetry,
  });

  final ProductSubmission submission;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context, submission.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    submission.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    submission.status.label,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(submission.type.label),
            if (submission.productName?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                submission.productName!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 10),
            Text(
              submission.details,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    _formatDate(submission.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (submission.status.canUpload)
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('다시 전송'),
                  ),
              ],
            ),
            if (submission.statusMessage?.isNotEmpty == true) ...[
              const Divider(),
              Text(
                submission.statusMessage!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(
    BuildContext context,
    ProductSubmissionStatus status,
  ) {
    return switch (status) {
      ProductSubmissionStatus.uploadFailed =>
        Theme.of(context).colorScheme.error,
      ProductSubmissionStatus.completed => const Color(0xFF2E7D32),
      ProductSubmissionStatus.investigating ||
      ProductSubmissionStatus.confirmed =>
        const Color(0xFF8A5A00),
      _ => Theme.of(context).colorScheme.primary,
    };
  }
}

class _EmptySubmissions extends StatelessWidget {
  const _EmptySubmissions();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: const [
        SizedBox(height: 100),
        Icon(Icons.mark_email_read_outlined, size: 44),
        SizedBox(height: 14),
        Text(
          '아직 제품 정보 요청이 없어요',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 6),
        Text(
          '검색되지 않는 제품이나 잘못된 관리 정보를 발견하면 여기에서 진행 상태를 확인할 수 있어요.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

String _formatDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}.$month.$day';
}
