enum DiagnosticOutcome {
  selfCare,
  checkManual,
  replaceConsumable,
  stopUsing,
  professionalSupport,
}

enum DiagnosticReviewStatus {
  draft('안전 편집 초안'),
  reviewed('자료 검수 완료'),
  verified('공식 자료 확인');

  const DiagnosticReviewStatus(this.label);

  final String label;
}

enum DiagnosticBasisType {
  generalSafety('일반 안전 원칙'),
  manufacturerGuide('제조사 안내'),
  publicSafetyGuide('공공기관 안전 안내'),
  expertReview('전문가 검토');

  const DiagnosticBasisType(this.label);

  final String label;
}

class ProductDiagnostic {
  const ProductDiagnostic({
    required this.id,
    required this.symptom,
    required this.question,
    required this.safeAction,
    required this.outcome,
    this.warningSigns = const [],
    this.steps = const [],
    this.tools = const [],
    this.recommendedProducts = const [],
    this.caution,
    this.reviewStatus = DiagnosticReviewStatus.draft,
    this.basisType = DiagnosticBasisType.generalSafety,
    this.sourceTitle = '앱 생활 관리 안전 기준',
    this.sourceUrl,
    this.reviewedAt = '2026-06-15',
    this.applicableMaterials = const ['제품 재질과 제조사 안내를 먼저 확인'],
    this.sources = const [],
  });

  final String id;
  final String symptom;
  final String question;
  final String safeAction;
  final DiagnosticOutcome outcome;
  final List<String> warningSigns;
  final List<String> steps;
  final List<String> tools;
  final List<DiagnosticProductRecommendation> recommendedProducts;
  final String? caution;
  final DiagnosticReviewStatus reviewStatus;
  final DiagnosticBasisType basisType;
  final String sourceTitle;
  final String? sourceUrl;
  final String reviewedAt;
  final List<String> applicableMaterials;
  final List<DiagnosticSource> sources;

  bool get requiresStop =>
      outcome == DiagnosticOutcome.stopUsing ||
      outcome == DiagnosticOutcome.professionalSupport;

  factory ProductDiagnostic.fromJson(Map<String, Object?> json) {
    return ProductDiagnostic(
      id: json['id']! as String,
      symptom: json['symptom']! as String,
      question: json['question']! as String,
      safeAction: json['safeAction']! as String,
      outcome: DiagnosticOutcome.values.byName(json['outcome']! as String),
      warningSigns: _stringList(json['warningSigns']),
      steps: _stringList(json['steps']),
      tools: _stringList(json['tools']),
      recommendedProducts: (json['recommendedProducts'] as List? ?? const [])
          .map(
            (item) => DiagnosticProductRecommendation.fromJson(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .toList(),
      caution: json['caution'] as String?,
      reviewStatus: DiagnosticReviewStatus.values.byName(
        json['reviewStatus'] as String? ?? 'draft',
      ),
      basisType: DiagnosticBasisType.values.byName(
        json['basisType'] as String? ?? 'generalSafety',
      ),
      sourceTitle: json['sourceTitle'] as String? ?? '앱 생활 관리 안전 기준',
      sourceUrl: json['sourceUrl'] as String?,
      reviewedAt: json['reviewedAt'] as String? ?? '2026-06-15',
      applicableMaterials: _stringList(json['applicableMaterials']),
      sources: (json['sources'] as List? ?? const [])
          .map(
            (item) => DiagnosticSource.fromJson(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'symptom': symptom,
        'question': question,
        'safeAction': safeAction,
        'outcome': outcome.name,
        'warningSigns': warningSigns,
        'steps': steps,
        'tools': tools,
        'recommendedProducts':
            recommendedProducts.map((item) => item.toJson()).toList(),
        'caution': caution,
        'reviewStatus': reviewStatus.name,
        'basisType': basisType.name,
        'sourceTitle': sourceTitle,
        'sourceUrl': sourceUrl,
        'reviewedAt': reviewedAt,
        'applicableMaterials': applicableMaterials,
        'sources': sources.map((item) => item.toJson()).toList(),
      };
}

class DiagnosticSource {
  const DiagnosticSource({
    required this.id,
    required this.title,
    required this.url,
    required this.publisher,
    required this.type,
    required this.checkedAt,
    required this.isOfficial,
    this.supports = const [],
  });

  final String id;
  final String title;
  final String url;
  final String publisher;
  final String type;
  final String checkedAt;
  final bool isOfficial;
  final List<String> supports;

  factory DiagnosticSource.fromJson(Map<String, Object?> json) {
    return DiagnosticSource(
      id: json['id']! as String,
      title: json['title']! as String,
      url: json['url']! as String,
      publisher: json['publisher']! as String,
      type: json['type']! as String,
      checkedAt: json['checkedAt']! as String,
      isOfficial: json['isOfficial'] as bool? ?? false,
      supports: _stringList(json['supports']),
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'publisher': publisher,
        'type': type,
        'checkedAt': checkedAt,
        'isOfficial': isOfficial,
        'supports': supports,
      };
}

class DiagnosticProductRecommendation {
  const DiagnosticProductRecommendation({
    required this.brand,
    required this.name,
    required this.reason,
    required this.url,
    this.isSearchLink = true,
    this.isSponsored = false,
    this.suitableMaterials = const [],
  });

  final String brand;
  final String name;
  final String reason;
  final String url;
  final bool isSearchLink;
  final bool isSponsored;
  final List<String> suitableMaterials;

  factory DiagnosticProductRecommendation.fromJson(
    Map<String, Object?> json,
  ) {
    return DiagnosticProductRecommendation(
      brand: json['brand']! as String,
      name: json['name']! as String,
      reason: json['reason']! as String,
      url: json['url']! as String,
      isSearchLink: json['isSearchLink'] as bool? ?? true,
      isSponsored: json['isSponsored'] as bool? ?? false,
      suitableMaterials: _stringList(json['suitableMaterials']),
    );
  }

  Map<String, Object?> toJson() => {
        'brand': brand,
        'name': name,
        'reason': reason,
        'url': url,
        'isSearchLink': isSearchLink,
        'isSponsored': isSponsored,
        'suitableMaterials': suitableMaterials,
      };
}

List<String> _stringList(Object? value) =>
    (value as List? ?? const []).cast<String>();
