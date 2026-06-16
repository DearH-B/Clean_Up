import 'package:flutter/material.dart';

enum PolicyType { privacy, terms, productInformation, advertising }

class PolicyScreen extends StatelessWidget {
  const PolicyScreen({required this.type, super.key});

  final PolicyType type;

  @override
  Widget build(BuildContext context) {
    final policy = _policyFor(type);
    return Scaffold(
      appBar: AppBar(title: Text(policy.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          Text(policy.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('시행 예정일: 정식 출시일'),
          const SizedBox(height: 24),
          for (final section in policy.sections) ...[
            Text(section.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(section.body),
            const SizedBox(height: 24),
          ],
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: const Text(
              '정식 출시 전 사업자 정보, 서비스명, 문의 이메일과 관할 법률을 확정해 최종 법률 검토가 필요합니다.',
            ),
          ),
        ],
      ),
    );
  }
}

class _Policy {
  const _Policy(this.title, this.sections);

  final String title;
  final List<_PolicySection> sections;
}

class _PolicySection {
  const _PolicySection(this.title, this.body);

  final String title;
  final String body;
}

_Policy _policyFor(PolicyType type) => switch (type) {
      PolicyType.privacy => const _Policy(
          '개인정보 및 기기 데이터 안내',
          [
            _PolicySection(
              '기기에 저장되는 정보',
              '등록한 공간과 제품, 모델명, 구매·설치일, 메모, 관리 기록, 소모품 정보와 최근 검색이 현재 기기 안에 저장됩니다.',
            ),
            _PolicySection(
              '사진과 카메라',
              '제품 라벨 사진은 글자를 인식해 제품을 검색하는 데 사용합니다. 앱은 선택한 사진 자체를 사용자 데이터베이스에 저장하지 않습니다.',
            ),
            _PolicySection(
              '서버로 전송되는 정보',
              '제품 검색어와 제품 정보 요청 내용은 카탈로그 검색 또는 요청 접수를 위해 서버로 전송될 수 있습니다. 계정 기능이 도입되기 전에는 사용자 제품 목록을 서버에 동기화하지 않습니다.',
            ),
            _PolicySection(
              '삭제와 백업',
              '설정의 데이터 관리에서 백업 코드를 만들거나 이 기기의 사용자 데이터를 전체 삭제할 수 있습니다. 앱 삭제 전 백업하지 않은 로컬 데이터는 복구할 수 없습니다.',
            ),
          ],
        ),
      PolicyType.terms => const _Policy(
          '서비스 이용 안내',
          [
            _PolicySection(
              '서비스 목적',
              '사용자가 보유한 제품의 설명서, 관리 정보, 소모품과 관리 기록을 한곳에서 확인하도록 돕습니다.',
            ),
            _PolicySection(
              '사용자의 확인 책임',
              '제품 모델과 설치 환경에 따라 안내가 달라질 수 있으므로 실제 작업 전 제조사의 최신 사용설명서와 안전 지침을 확인해야 합니다.',
            ),
            _PolicySection(
              '금지 행위',
              '서비스를 방해하거나 다른 사람의 정보를 침해하고, 허위 또는 위험한 제품 정보를 고의로 제출하는 행위를 금지합니다.',
            ),
          ],
        ),
      PolicyType.productInformation => const _Policy(
          '제품 정보 책임 범위',
          [
            _PolicySection(
              '공식 자료 우선',
              '앱의 관리 안내보다 제조사의 최신 사용설명서, 리콜 안내, 안전 지침과 서비스센터 안내가 우선합니다.',
            ),
            _PolicySection(
              '진단의 한계',
              '문제 확인 기능은 고장을 확정하거나 수리를 지시하지 않습니다. 누수, 연기, 전기 냄새, 과열 또는 분해가 필요한 상황에서는 사용을 멈추고 전문가에게 문의해야 합니다.',
            ),
            _PolicySection(
              '자료 상태 표시',
              '정확한 모델의 공식 자료인지, 유사 제품 또는 일반 제품군을 참고한 정보인지 화면에 구분해 표시합니다. 오류는 제품 상세에서 제보할 수 있습니다.',
            ),
          ],
        ),
      PolicyType.advertising => const _Policy(
          '추천 및 광고 표시 원칙',
          [
            _PolicySection(
              '추천 기준',
              '관리 단계에 실제로 필요한 용도와 제품 호환성을 먼저 설명하며 구매 링크만 단독으로 노출하지 않습니다.',
            ),
            _PolicySection(
              '광고와 제휴',
              '대가를 받거나 구매에 따른 수수료가 발생하는 링크는 광고 또는 제휴임을 제품 옆에 명확히 표시합니다.',
            ),
            _PolicySection(
              '가격과 재고',
              '가격, 재고, 배송과 반품 조건은 판매처에서 변경될 수 있으며 앱이 이를 보증하지 않습니다.',
            ),
          ],
        ),
    };
