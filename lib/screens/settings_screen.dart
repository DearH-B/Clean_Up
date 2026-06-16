import 'package:flutter/material.dart';

import '../models/product_submission.dart';
import '../repositories/product_data_repository.dart';
import 'data_management_screen.dart';
import 'policy_screen.dart';
import 'product_submission_form_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.dataRepository,
    required this.onDataChanged,
    super.key,
  });

  final ProductDataRepository dataRepository;
  final VoidCallback onDataChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SettingsSection(
            title: '내 데이터',
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_download_outlined),
                title: const Text('백업·복원·전체 삭제'),
                subtitle: const Text('현재 데이터는 이 기기에 저장돼요.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final changed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) =>
                          DataManagementScreen(dataRepository: dataRepository),
                    ),
                  );
                  if (changed == true) onDataChanged();
                },
              ),
            ],
          ),
          _SettingsSection(
            title: '도움말과 피드백',
            children: [
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('앱 기능 문제 신고'),
                subtitle: const Text('작동하지 않거나 저장되지 않는 문제'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openFeedback(
                  context,
                  ProductSubmissionType.appIssue,
                  '앱 기능 문제',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.rate_review_outlined),
                title: const Text('사용하기 불편한 점'),
                subtitle: const Text('헷갈리는 화면이나 번거로운 과정'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openFeedback(
                  context,
                  ProductSubmissionType.usabilityFeedback,
                  '사용성 개선 의견',
                ),
              ),
            ],
          ),
          _SettingsSection(
            title: '정책과 안전',
            children: [
              _policyTile(
                context,
                Icons.privacy_tip_outlined,
                '개인정보 및 기기 데이터',
                PolicyType.privacy,
              ),
              _policyTile(
                context,
                Icons.description_outlined,
                '서비스 이용 안내',
                PolicyType.terms,
              ),
              _policyTile(
                context,
                Icons.health_and_safety_outlined,
                '제품 정보 책임 범위',
                PolicyType.productInformation,
              ),
              _policyTile(
                context,
                Icons.ads_click_outlined,
                '추천 및 광고 표시 원칙',
                PolicyType.advertising,
              ),
            ],
          ),
          const _SettingsSection(
            title: '앱 정보',
            children: [
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('버전'),
                trailing: Text('0.1.0 (1)'),
              ),
              ListTile(
                leading: Icon(Icons.mail_outline),
                title: Text('문의 채널'),
                subtitle: Text('정식 출시 전 문의 이메일을 연결할 예정입니다.'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openFeedback(
    BuildContext context,
    ProductSubmissionType type,
    String title,
  ) async {
    final submission = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductSubmissionFormScreen(
          dataRepository: dataRepository,
          initialType: type,
          initialTitle: title,
          screenContext: '설정 · 도움말과 피드백',
        ),
      ),
    );
    if (submission != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('피드백을 요청 내역에 저장했어요.')),
      );
    }
  }

  Widget _policyTile(
    BuildContext context,
    IconData icon,
    String title,
    PolicyType type,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PolicyScreen(type: type),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          Card(child: Column(children: children)),
        ],
      ),
    );
  }
}
