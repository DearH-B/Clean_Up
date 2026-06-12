import 'catalog_metadata.dart';
import 'product_consumable.dart';

enum ZoneItemType {
  appliance('가전'),
  furniture('가구'),
  fixture('시설'),
  other('기타');

  const ZoneItemType(this.label);

  final String label;
}

enum GuideSourceType {
  official('공식 자료'),
  officialVideo('공식 영상 참고'),
  similarProduct('유사 제품 참고'),
  general('일반 관리법');

  const GuideSourceType(this.label);

  final String label;
}

class CleaningProduct {
  const CleaningProduct({
    required this.brand,
    required this.name,
    required this.reason,
    required this.url,
    this.isSponsored = false,
  });

  final String brand;
  final String name;
  final String reason;
  final String url;
  final bool isSponsored;

  factory CleaningProduct.fromJson(Map<String, Object?> json) {
    return CleaningProduct(
      brand: json['brand'] as String,
      name: json['name'] as String,
      reason: json['reason'] as String,
      url: json['url'] as String,
      isSponsored: json['isSponsored'] as bool? ?? false,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'brand': brand,
      'name': name,
      'reason': reason,
      'url': url,
      'isSponsored': isSponsored,
    };
  }
}

class ZoneItem {
  const ZoneItem({
    required this.id,
    required this.zoneId,
    required this.name,
    required this.type,
    required this.summary,
    required this.frequency,
    required this.supplies,
    required this.cautions,
    required this.steps,
    this.catalogProductId,
    this.productSources = const [],
    this.scannedCode,
    this.scannedCodeFormat,
    this.scannedSourceUrl,
    this.visualCandidateId,
    this.releasePeriod,
    this.nickname,
    this.purchaseDate,
    this.installedDate,
    this.note,
    this.estimatedMinutes = 10,
    this.manufacturer,
    this.seriesName,
    this.modelName,
    this.productMethod,
    this.guideStatus,
    this.guideVideoUrl,
    this.guideVideoTitle,
    this.guideVideoChannel,
    this.guideBasis,
    this.sourceTitle,
    this.sourceUrl,
    this.sourceCheckedAt,
    this.matchLevelLabel,
    this.productSpecs = const [],
    this.guideSourceType = GuideSourceType.general,
    this.recurrenceDays = 7,
    this.lastCleanedAt,
    this.nextDueAt,
    this.recommendedSupplies = const [],
    this.recommendedProducts = const [],
    this.consumables = const [],
  });

  final String id;
  final String zoneId;
  final String? catalogProductId;
  final List<ProductSource> productSources;
  final String? scannedCode;
  final String? scannedCodeFormat;
  final String? scannedSourceUrl;
  final String? visualCandidateId;
  final String? releasePeriod;
  final String? nickname;
  final DateTime? purchaseDate;
  final DateTime? installedDate;
  final String? note;
  final String name;
  final ZoneItemType type;
  final String summary;
  final String frequency;
  final List<String> supplies;
  final List<String> cautions;
  final List<String> steps;
  final int estimatedMinutes;
  final String? manufacturer;
  final String? seriesName;
  final String? modelName;
  final String? productMethod;
  final String? guideStatus;
  final String? guideVideoUrl;
  final String? guideVideoTitle;
  final String? guideVideoChannel;
  final String? guideBasis;
  final String? sourceTitle;
  final String? sourceUrl;
  final DateTime? sourceCheckedAt;
  final String? matchLevelLabel;
  final List<String> productSpecs;
  final GuideSourceType guideSourceType;
  final int recurrenceDays;
  final DateTime? lastCleanedAt;
  final DateTime? nextDueAt;
  final List<String> recommendedSupplies;
  final List<CleaningProduct> recommendedProducts;
  final List<ProductConsumable> consumables;

  bool get hasProductInfo =>
      (manufacturer?.trim().isNotEmpty ?? false) ||
      (seriesName?.trim().isNotEmpty ?? false) ||
      (modelName?.trim().isNotEmpty ?? false);

  String get displayName =>
      nickname?.trim().isNotEmpty == true ? nickname!.trim() : name;

  bool isDue(DateTime now) {
    final dueAt = nextDueAt;
    if (dueAt == null) {
      return false;
    }

    return !dueAt.isAfter(now);
  }

  factory ZoneItem.fromJson(Map<String, Object?> json) {
    return ZoneItem(
      id: json['id'] as String,
      zoneId: json['zoneId'] as String,
      catalogProductId: json['catalogProductId'] as String?,
      productSources: (json['productSources'] as List<dynamic>? ?? const [])
          .map(
            (source) => ProductSource.fromJson(
              Map<String, Object?>.from(source as Map),
            ),
          )
          .toList(),
      scannedCode: json['scannedCode'] as String?,
      scannedCodeFormat: json['scannedCodeFormat'] as String?,
      scannedSourceUrl: json['scannedSourceUrl'] as String?,
      visualCandidateId: json['visualCandidateId'] as String?,
      releasePeriod: json['releasePeriod'] as String?,
      nickname: json['nickname'] as String?,
      purchaseDate: json['purchaseDate'] == null
          ? null
          : DateTime.parse(json['purchaseDate'] as String),
      installedDate: json['installedDate'] == null
          ? null
          : DateTime.parse(json['installedDate'] as String),
      note: json['note'] as String?,
      name: json['name'] as String,
      type: ZoneItemType.values.byName(json['type'] as String),
      summary: json['summary'] as String,
      frequency: json['frequency'] as String,
      supplies: (json['supplies'] as List<dynamic>).cast<String>(),
      cautions: (json['cautions'] as List<dynamic>).cast<String>(),
      steps: (json['steps'] as List<dynamic>).cast<String>(),
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 10,
      manufacturer: json['manufacturer'] as String?,
      seriesName: json['seriesName'] as String?,
      modelName: json['modelName'] as String?,
      productMethod: json['productMethod'] as String?,
      guideStatus: json['guideStatus'] as String?,
      guideVideoUrl: json['guideVideoUrl'] as String?,
      guideVideoTitle: json['guideVideoTitle'] as String?,
      guideVideoChannel: json['guideVideoChannel'] as String?,
      guideBasis: json['guideBasis'] as String?,
      sourceTitle: json['sourceTitle'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      sourceCheckedAt: json['sourceCheckedAt'] == null
          ? null
          : DateTime.parse(json['sourceCheckedAt'] as String),
      matchLevelLabel: json['matchLevelLabel'] as String?,
      productSpecs:
          (json['productSpecs'] as List<dynamic>? ?? const []).cast<String>(),
      guideSourceType: GuideSourceType.values.byName(
        json['guideSourceType'] as String? ?? GuideSourceType.general.name,
      ),
      recurrenceDays: json['recurrenceDays'] as int? ?? 7,
      lastCleanedAt: json['lastCleanedAt'] == null
          ? null
          : DateTime.parse(json['lastCleanedAt'] as String),
      nextDueAt: json['nextDueAt'] == null
          ? null
          : DateTime.parse(json['nextDueAt'] as String),
      recommendedSupplies:
          (json['recommendedSupplies'] as List<dynamic>? ?? const [])
              .cast<String>(),
      recommendedProducts:
          (json['recommendedProducts'] as List<dynamic>? ?? const [])
              .map(
                (item) => CleaningProduct.fromJson(
                  Map<String, Object?>.from(item as Map),
                ),
              )
              .toList(),
      consumables: (json['consumables'] as List<dynamic>? ?? const [])
          .map(
            (item) => ProductConsumable.fromJson(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'zoneId': zoneId,
      'catalogProductId': catalogProductId,
      'productSources': [
        for (final source in productSources) source.toJson(),
      ],
      'scannedCode': scannedCode,
      'scannedCodeFormat': scannedCodeFormat,
      'scannedSourceUrl': scannedSourceUrl,
      'visualCandidateId': visualCandidateId,
      'releasePeriod': releasePeriod,
      'nickname': nickname,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'installedDate': installedDate?.toIso8601String(),
      'note': note,
      'name': name,
      'type': type.name,
      'summary': summary,
      'frequency': frequency,
      'supplies': supplies,
      'cautions': cautions,
      'steps': steps,
      'estimatedMinutes': estimatedMinutes,
      'manufacturer': manufacturer,
      'seriesName': seriesName,
      'modelName': modelName,
      'productMethod': productMethod,
      'guideStatus': guideStatus,
      'guideVideoUrl': guideVideoUrl,
      'guideVideoTitle': guideVideoTitle,
      'guideVideoChannel': guideVideoChannel,
      'guideBasis': guideBasis,
      'sourceTitle': sourceTitle,
      'sourceUrl': sourceUrl,
      'sourceCheckedAt': sourceCheckedAt?.toIso8601String(),
      'matchLevelLabel': matchLevelLabel,
      'productSpecs': productSpecs,
      'guideSourceType': guideSourceType.name,
      'recurrenceDays': recurrenceDays,
      'lastCleanedAt': lastCleanedAt?.toIso8601String(),
      'nextDueAt': nextDueAt?.toIso8601String(),
      'recommendedSupplies': recommendedSupplies,
      'recommendedProducts': [
        for (final product in recommendedProducts) product.toJson(),
      ],
      'consumables': [
        for (final consumable in consumables) consumable.toJson(),
      ],
    };
  }

  ZoneItem copyWith({
    String? catalogProductId,
    List<ProductSource>? productSources,
    String? scannedCode,
    String? scannedCodeFormat,
    String? scannedSourceUrl,
    String? visualCandidateId,
    String? releasePeriod,
    String? nickname,
    DateTime? purchaseDate,
    DateTime? installedDate,
    String? note,
    String? manufacturer,
    String? seriesName,
    String? modelName,
    String? guideStatus,
    String? sourceTitle,
    String? sourceUrl,
    DateTime? sourceCheckedAt,
    String? matchLevelLabel,
    List<String>? productSpecs,
    DateTime? lastCleanedAt,
    DateTime? nextDueAt,
    bool clearLastCleanedAt = false,
    bool clearNextDueAt = false,
    bool clearVisualCandidate = false,
    List<ProductConsumable>? consumables,
  }) {
    return ZoneItem(
      id: id,
      zoneId: zoneId,
      catalogProductId: catalogProductId ?? this.catalogProductId,
      productSources: productSources ?? this.productSources,
      scannedCode: scannedCode ?? this.scannedCode,
      scannedCodeFormat: scannedCodeFormat ?? this.scannedCodeFormat,
      scannedSourceUrl: scannedSourceUrl ?? this.scannedSourceUrl,
      visualCandidateId: clearVisualCandidate
          ? null
          : visualCandidateId ?? this.visualCandidateId,
      releasePeriod:
          clearVisualCandidate ? null : releasePeriod ?? this.releasePeriod,
      nickname: nickname ?? this.nickname,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      installedDate: installedDate ?? this.installedDate,
      note: note ?? this.note,
      name: name,
      type: type,
      summary: summary,
      frequency: frequency,
      supplies: supplies,
      cautions: cautions,
      steps: steps,
      estimatedMinutes: estimatedMinutes,
      manufacturer: manufacturer ?? this.manufacturer,
      seriesName: seriesName ?? this.seriesName,
      modelName: modelName ?? this.modelName,
      productMethod: productMethod,
      guideStatus: guideStatus ?? this.guideStatus,
      guideVideoUrl: guideVideoUrl,
      guideVideoTitle: guideVideoTitle,
      guideVideoChannel: guideVideoChannel,
      guideBasis: guideBasis,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceCheckedAt: sourceCheckedAt ?? this.sourceCheckedAt,
      matchLevelLabel: matchLevelLabel ?? this.matchLevelLabel,
      productSpecs: productSpecs ?? this.productSpecs,
      guideSourceType: guideSourceType,
      recurrenceDays: recurrenceDays,
      lastCleanedAt:
          clearLastCleanedAt ? null : lastCleanedAt ?? this.lastCleanedAt,
      nextDueAt: clearNextDueAt ? null : nextDueAt ?? this.nextDueAt,
      recommendedSupplies: recommendedSupplies,
      recommendedProducts: recommendedProducts,
      consumables: consumables ?? this.consumables,
    );
  }
}
