import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../repositories/product_data_repository.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({
    required this.dataRepository,
    super.key,
  });

  final ProductDataRepository dataRepository;

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  bool _isWorking = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('데이터 백업')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            '내 데이터 보관',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            '현재는 기기 안에 저장됩니다. 앱을 삭제하거나 휴대폰을 바꾸기 전에 백업 코드를 보관하세요.',
          ),
          const SizedBox(height: 28),
          _DataAction(
            icon: Icons.copy_all_outlined,
            title: '백업 코드 복사',
            description: '제품, 공간, 관리 기록과 소모품 정보를 하나의 코드로 복사합니다.',
            buttonLabel: '클립보드에 복사',
            onPressed: _isWorking ? null : _copyBackup,
          ),
          const Divider(height: 48),
          _DataAction(
            icon: Icons.settings_backup_restore_outlined,
            title: '백업 코드 복원',
            description: '클립보드의 백업 코드로 현재 기기의 데이터를 교체합니다.',
            buttonLabel: '클립보드에서 복원',
            onPressed: _isWorking ? null : _restoreBackup,
          ),
          const Divider(height: 48),
          _DataAction(
            icon: Icons.delete_forever_outlined,
            title: '기기 데이터 전체 삭제',
            description: '등록한 공간, 제품, 관리 기록, 요청 내역과 최근 검색을 모두 삭제합니다.',
            buttonLabel: '전체 데이터 삭제',
            destructive: true,
            onPressed: _isWorking ? null : _deleteAllData,
          ),
          if (_isWorking) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
          const SizedBox(height: 28),
          Text(
            '백업 코드에는 등록한 제품과 기록이 포함됩니다. 다른 사람과 공유하지 마세요.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모든 데이터를 삭제할까요?'),
        content: const Text(
          '이 기기에 저장된 공간, 제품과 관리 기록이 모두 삭제됩니다. 삭제 후에는 백업 코드가 없으면 복구할 수 없어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('모두 삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isWorking = true);
    try {
      await widget.dataRepository.clearAllUserData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이 기기의 사용자 데이터를 모두 삭제했어요.')),
      );
      Navigator.of(context).pop(true);
    } on Object {
      _showError('데이터를 삭제하지 못했어요.');
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _copyBackup() async {
    setState(() => _isWorking = true);
    try {
      final backup = await widget.dataRepository.exportBackupJson();
      await Clipboard.setData(ClipboardData(text: backup));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('백업 코드를 클립보드에 복사했어요.')),
        );
      }
    } on Object {
      _showError('백업 코드를 만들지 못했어요.');
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
      }
    }
  }

  Future<void> _restoreBackup() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final encoded = clipboard?.text?.trim();
    if (encoded == null || encoded.isEmpty) {
      _showError('클립보드에 백업 코드가 없어요.');
      return;
    }
    if (!mounted) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('백업을 복원할까요?'),
        content: const Text('현재 제품과 기록이 백업 코드의 내용으로 교체됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('복원'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isWorking = true);
    try {
      final summary = await widget.dataRepository.restoreBackupJson(encoded);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '제품 ${summary.productCount}개와 기록 ${summary.recordCount}개를 복원했어요.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } on FormatException catch (error) {
      _showError(error.message);
    } on Object {
      _showError('백업을 복원하지 못했어요.');
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _DataAction extends StatelessWidget {
  const _DataAction({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 32),
        const SizedBox(height: 14),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(description),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(buttonLabel),
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                )
              : null,
        ),
      ],
    );
  }
}
