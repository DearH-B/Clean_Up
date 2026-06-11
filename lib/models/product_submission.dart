enum ProductSubmissionType {
  missingProduct,
  incorrectInfo,
  brokenLink,
  incorrectGuide,
  unsafeGuide,
  officialSource;

  String get label => switch (this) {
        ProductSubmissionType.missingProduct => '검색되지 않는 제품',
        ProductSubmissionType.incorrectInfo => '제품 정보가 다름',
        ProductSubmissionType.brokenLink => '링크가 열리지 않음',
        ProductSubmissionType.incorrectGuide => '관리법이 맞지 않음',
        ProductSubmissionType.unsafeGuide => '위험한 안내가 있음',
        ProductSubmissionType.officialSource => '새 공식 자료 제보',
      };
}

enum ProductSubmissionStatus {
  pendingUpload,
  uploadFailed,
  received,
  investigating,
  confirmed,
  completed,
  rejected;

  String get label => switch (this) {
        ProductSubmissionStatus.pendingUpload => '전송 대기',
        ProductSubmissionStatus.uploadFailed => '전송 확인 필요',
        ProductSubmissionStatus.received => '접수',
        ProductSubmissionStatus.investigating => '조사 중',
        ProductSubmissionStatus.confirmed => '정보 확인',
        ProductSubmissionStatus.completed => '반영 완료',
        ProductSubmissionStatus.rejected => '반영 불가',
      };

  bool get canUpload => this == pendingUpload || this == uploadFailed;

  bool get canRefresh =>
      this != pendingUpload && this != uploadFailed && this != completed;
}

class ProductSubmission {
  const ProductSubmission({
    required this.id,
    required this.type,
    required this.title,
    required this.details,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.trackingToken,
    this.productId,
    this.productName,
    this.categoryName,
    this.brand,
    this.modelName,
    this.sourceUrl,
    this.statusMessage,
  });

  final String id;
  final String? trackingToken;
  final ProductSubmissionType type;
  final String title;
  final String details;
  final String? productId;
  final String? productName;
  final String? categoryName;
  final String? brand;
  final String? modelName;
  final String? sourceUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProductSubmissionStatus status;
  final String? statusMessage;

  ProductSubmission copyWith({
    String? trackingToken,
    DateTime? updatedAt,
    ProductSubmissionStatus? status,
    String? statusMessage,
  }) {
    return ProductSubmission(
      id: id,
      trackingToken: trackingToken ?? this.trackingToken,
      type: type,
      title: title,
      details: details,
      productId: productId,
      productName: productName,
      categoryName: categoryName,
      brand: brand,
      modelName: modelName,
      sourceUrl: sourceUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  factory ProductSubmission.fromJson(Map<String, Object?> json) {
    return ProductSubmission(
      id: json['id'] as String,
      trackingToken: json['trackingToken'] as String?,
      type: ProductSubmissionType.values.byName(json['type'] as String),
      title: json['title'] as String,
      details: json['details'] as String? ?? '',
      productId: json['productId'] as String?,
      productName: json['productName'] as String?,
      categoryName: json['categoryName'] as String?,
      brand: json['brand'] as String?,
      modelName: json['modelName'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ?? json['createdAt'] as String,
      ),
      status: ProductSubmissionStatus.values.byName(
        json['status'] as String? ?? ProductSubmissionStatus.pendingUpload.name,
      ),
      statusMessage: json['statusMessage'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'trackingToken': trackingToken,
      'type': type.name,
      'title': title,
      'details': details,
      'productId': productId,
      'productName': productName,
      'categoryName': categoryName,
      'brand': brand,
      'modelName': modelName,
      'sourceUrl': sourceUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.name,
      'statusMessage': statusMessage,
    };
  }

  Map<String, Object?> toApiJson() {
    return {
      'clientSubmissionId': id,
      'type': type.name,
      'title': title,
      'details': details,
      'productId': productId,
      'productName': productName,
      'categoryName': categoryName,
      'brand': brand,
      'modelName': modelName,
      'sourceUrl': sourceUrl,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }
}
