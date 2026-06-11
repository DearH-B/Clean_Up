enum CareRecordType {
  cleaning('청소'),
  inspection('점검'),
  filterReplacement('필터 교체'),
  consumableReplacement('소모품 교체'),
  issue('문제 발생'),
  service('AS'),
  note('기타 메모');

  const CareRecordType(this.label);

  final String label;
}

class CareRecord {
  const CareRecord({
    required this.id,
    required this.title,
    required this.spaceName,
    required this.completedAt,
    required this.minutes,
    this.type = CareRecordType.cleaning,
    this.productId,
    this.productName,
    this.spaceId,
    this.guideTitle,
    this.usedSupplies = const [],
    this.symptom,
    this.result,
    this.note,
    this.photoPaths = const [],
    this.nextCheckAt,
  });

  final String id;
  final String title;
  final String spaceName;
  final DateTime completedAt;
  final int minutes;
  final CareRecordType type;
  final String? productId;
  final String? productName;
  final String? spaceId;
  final String? guideTitle;
  final List<String> usedSupplies;
  final String? symptom;
  final String? result;
  final String? note;
  final List<String> photoPaths;
  final DateTime? nextCheckAt;

  bool get affectsCareSchedule => {
        CareRecordType.cleaning,
        CareRecordType.inspection,
        CareRecordType.filterReplacement,
        CareRecordType.consumableReplacement,
      }.contains(type);

  String get displayProductName {
    final name = productName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return title.replaceAll(' 관리 완료', '').replaceAll(' 청소 완료', '').trim();
  }

  factory CareRecord.fromJson(Map<String, Object?> json) {
    return CareRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      spaceName:
          json['spaceName'] as String? ?? json['zoneName'] as String? ?? '',
      completedAt: DateTime.parse(json['completedAt'] as String),
      minutes: json['minutes'] as int? ?? 0,
      type: _recordTypeFromJson(json['type']),
      productId: json['productId'] as String?,
      productName: json['productName'] as String?,
      spaceId: json['spaceId'] as String?,
      guideTitle: json['guideTitle'] as String?,
      usedSupplies:
          (json['usedSupplies'] as List<dynamic>? ?? const []).cast<String>(),
      symptom: json['symptom'] as String?,
      result: json['result'] as String?,
      note: json['note'] as String?,
      photoPaths:
          (json['photoPaths'] as List<dynamic>? ?? const []).cast<String>(),
      nextCheckAt: json['nextCheckAt'] == null
          ? null
          : DateTime.parse(json['nextCheckAt'] as String),
    );
  }

  CareRecord copyWith({
    String? title,
    String? spaceName,
    DateTime? completedAt,
    int? minutes,
    CareRecordType? type,
    String? productId,
    String? productName,
    String? spaceId,
    String? guideTitle,
    List<String>? usedSupplies,
    String? symptom,
    String? result,
    String? note,
    List<String>? photoPaths,
    DateTime? nextCheckAt,
    bool clearNextCheckAt = false,
  }) {
    return CareRecord(
      id: id,
      title: title ?? this.title,
      spaceName: spaceName ?? this.spaceName,
      completedAt: completedAt ?? this.completedAt,
      minutes: minutes ?? this.minutes,
      type: type ?? this.type,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      spaceId: spaceId ?? this.spaceId,
      guideTitle: guideTitle ?? this.guideTitle,
      usedSupplies: usedSupplies ?? this.usedSupplies,
      symptom: symptom ?? this.symptom,
      result: result ?? this.result,
      note: note ?? this.note,
      photoPaths: photoPaths ?? this.photoPaths,
      nextCheckAt: clearNextCheckAt ? null : nextCheckAt ?? this.nextCheckAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'spaceName': spaceName,
      'completedAt': completedAt.toIso8601String(),
      'minutes': minutes,
      'type': type.name,
      'productId': productId,
      'productName': productName,
      'spaceId': spaceId,
      'guideTitle': guideTitle,
      'usedSupplies': usedSupplies,
      'symptom': symptom,
      'result': result,
      'note': note,
      'photoPaths': photoPaths,
      'nextCheckAt': nextCheckAt?.toIso8601String(),
    };
  }
}

CareRecord? latestScheduledCareRecord(
  Iterable<CareRecord> records,
  String productId,
) {
  final matching = records
      .where(
        (record) => record.productId == productId && record.affectsCareSchedule,
      )
      .toList()
    ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  return matching.isEmpty ? null : matching.first;
}

CareRecordType _recordTypeFromJson(Object? value) {
  final name = value as String?;
  if (name == null) {
    return CareRecordType.cleaning;
  }
  return CareRecordType.values.firstWhere(
    (type) => type.name == name,
    orElse: () => CareRecordType.cleaning,
  );
}
