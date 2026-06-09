enum ProductSourceType {
  officialProduct('공식 제품 페이지'),
  officialManual('공식 설명서'),
  officialVideo('공식 영상'),
  officialSupport('공식 고객지원'),
  retailer('판매 페이지'),
  priceComparison('가격비교 스펙'),
  installer('설치업체 자료'),
  similarProduct('유사 제품 참고'),
  generalGuidance('일반 제품군 관리법');

  const ProductSourceType(this.label);

  final String label;
}

class ProductSource {
  const ProductSource({
    required this.id,
    required this.title,
    required this.type,
    required this.publisher,
    required this.checkedAt,
    required this.supports,
    required this.isOfficial,
    required this.isActive,
    this.url,
  });

  final String id;
  final String title;
  final String? url;
  final ProductSourceType type;
  final String publisher;
  final DateTime checkedAt;
  final List<String> supports;
  final bool isOfficial;
  final bool isActive;

  bool needsReview(
    DateTime now, {
    int maxAgeDays = 180,
  }) {
    return !isActive || now.difference(checkedAt).inDays > maxAgeDays;
  }

  factory ProductSource.fromJson(Map<String, Object?> json) {
    return ProductSource(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String?,
      type: ProductSourceType.values.byName(json['type'] as String),
      publisher: json['publisher'] as String,
      checkedAt: DateTime.parse(json['checkedAt'] as String),
      supports: (json['supports'] as List<dynamic>? ?? const []).cast<String>(),
      isOfficial: json['isOfficial'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'type': type.name,
      'publisher': publisher,
      'checkedAt': checkedAt.toIso8601String(),
      'supports': supports,
      'isOfficial': isOfficial,
      'isActive': isActive,
    };
  }
}

class CatalogReviewRecord {
  const CatalogReviewRecord({
    required this.status,
    required this.reviewer,
    required this.reviewedAt,
    required this.note,
  });

  final String status;
  final String reviewer;
  final DateTime reviewedAt;
  final String note;

  factory CatalogReviewRecord.fromJson(Map<String, Object?> json) {
    return CatalogReviewRecord(
      status: json['status'] as String,
      reviewer: json['reviewer'] as String,
      reviewedAt: DateTime.parse(json['reviewedAt'] as String),
      note: json['note'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'status': status,
      'reviewer': reviewer,
      'reviewedAt': reviewedAt.toIso8601String(),
      'note': note,
    };
  }
}
