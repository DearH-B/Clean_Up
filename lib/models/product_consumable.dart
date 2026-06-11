enum ConsumableType {
  filter('필터'),
  cleaner('세척제'),
  refill('보충품'),
  part('교체 부품'),
  other('기타');

  const ConsumableType(this.label);

  final String label;
}

class ProductConsumable {
  const ProductConsumable({
    required this.id,
    required this.name,
    required this.type,
    required this.replacementDays,
    required this.compatibilityLabel,
    this.partNumber,
    this.lastReplacedAt,
    this.nextReplacementAt,
    this.purchaseUrl,
    this.isSponsored = false,
    this.note,
  });

  final String id;
  final String name;
  final ConsumableType type;
  final int replacementDays;
  final String compatibilityLabel;
  final String? partNumber;
  final DateTime? lastReplacedAt;
  final DateTime? nextReplacementAt;
  final String? purchaseUrl;
  final bool isSponsored;
  final String? note;

  bool isDue(DateTime now) {
    final dueAt = nextReplacementAt;
    return dueAt != null && !dueAt.isAfter(now);
  }

  ProductConsumable markReplaced(DateTime replacedAt) {
    return copyWith(
      lastReplacedAt: replacedAt,
      nextReplacementAt: replacedAt.add(Duration(days: replacementDays)),
    );
  }

  ProductConsumable copyWith({
    String? name,
    ConsumableType? type,
    int? replacementDays,
    String? compatibilityLabel,
    String? partNumber,
    DateTime? lastReplacedAt,
    DateTime? nextReplacementAt,
    String? purchaseUrl,
    bool? isSponsored,
    String? note,
    bool clearPartNumber = false,
    bool clearLastReplacedAt = false,
    bool clearNextReplacementAt = false,
    bool clearPurchaseUrl = false,
    bool clearNote = false,
  }) {
    return ProductConsumable(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      replacementDays: replacementDays ?? this.replacementDays,
      compatibilityLabel: compatibilityLabel ?? this.compatibilityLabel,
      partNumber: clearPartNumber ? null : partNumber ?? this.partNumber,
      lastReplacedAt:
          clearLastReplacedAt ? null : lastReplacedAt ?? this.lastReplacedAt,
      nextReplacementAt: clearNextReplacementAt
          ? null
          : nextReplacementAt ?? this.nextReplacementAt,
      purchaseUrl: clearPurchaseUrl ? null : purchaseUrl ?? this.purchaseUrl,
      isSponsored: isSponsored ?? this.isSponsored,
      note: clearNote ? null : note ?? this.note,
    );
  }

  factory ProductConsumable.fromJson(Map<String, Object?> json) {
    return ProductConsumable(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ConsumableType.values.byName(
        json['type'] as String? ?? ConsumableType.other.name,
      ),
      replacementDays: json['replacementDays'] as int? ?? 90,
      compatibilityLabel:
          json['compatibilityLabel'] as String? ?? '제품 설명서 확인 필요',
      partNumber: json['partNumber'] as String?,
      lastReplacedAt: json['lastReplacedAt'] == null
          ? null
          : DateTime.parse(json['lastReplacedAt'] as String),
      nextReplacementAt: json['nextReplacementAt'] == null
          ? null
          : DateTime.parse(json['nextReplacementAt'] as String),
      purchaseUrl: json['purchaseUrl'] as String?,
      isSponsored: json['isSponsored'] as bool? ?? false,
      note: json['note'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'replacementDays': replacementDays,
      'compatibilityLabel': compatibilityLabel,
      'partNumber': partNumber,
      'lastReplacedAt': lastReplacedAt?.toIso8601String(),
      'nextReplacementAt': nextReplacementAt?.toIso8601String(),
      'purchaseUrl': purchaseUrl,
      'isSponsored': isSponsored,
      'note': note,
    };
  }
}
