import '../models/catalog_metadata.dart';
import '../models/catalog_model_option.dart';
import '../models/product_consumable.dart';
import '../models/zone_item.dart';

class ProductCatalogEntry {
  const ProductCatalogEntry({
    required this.id,
    required this.name,
    required this.type,
    required this.categoryName,
    required this.brand,
    required this.manufacturer,
    required this.modelName,
    this.seriesName = '',
    required this.summary,
    required this.frequency,
    required this.recurrenceDays,
    required this.estimatedMinutes,
    required this.productMethod,
    required this.guideStatus,
    required this.guideBasis,
    required this.guideSourceType,
    required this.matchLevelLabel,
    required this.sourceTitle,
    required this.sourceUrl,
    required this.sourceCheckedAt,
    required this.productSpecs,
    required this.supplies,
    required this.recommendedSupplies,
    required this.recommendedProducts,
    required this.cautions,
    required this.steps,
    this.sources = const [],
    this.specSourceIds = const {},
    this.stepSourceIds = const {},
    this.reviewHistory = const [],
    this.officialManualUrl,
    this.supportUrl,
    this.servicePhone,
    this.releaseYear,
    this.isDiscontinued,
    this.imageUrl,
    this.modelFeatures = const [],
    this.consumables = const [],
    this.consumableDetails = const [],
    this.installationType,
    this.guideVideoUrl,
    this.guideVideoTitle,
    this.guideVideoChannel,
    this.keywords = const [],
    this.reviewStatus = 'reviewed',
  });

  final String id;
  final String name;
  final ZoneItemType type;
  final String categoryName;
  final String brand;
  final String manufacturer;
  final String modelName;
  final String seriesName;
  final String summary;
  final String frequency;
  final int recurrenceDays;
  final int estimatedMinutes;
  final String productMethod;
  final String guideStatus;
  final String guideBasis;
  final GuideSourceType guideSourceType;
  final String matchLevelLabel;
  final String sourceTitle;
  final String sourceUrl;
  final DateTime sourceCheckedAt;
  final List<String> productSpecs;
  final List<String> supplies;
  final List<String> recommendedSupplies;
  final List<CleaningProduct> recommendedProducts;
  final List<String> cautions;
  final List<String> steps;
  final List<ProductSource> sources;
  final Map<String, List<String>> specSourceIds;
  final Map<String, List<String>> stepSourceIds;
  final List<CatalogReviewRecord> reviewHistory;
  final String? officialManualUrl;
  final String? supportUrl;
  final String? servicePhone;
  final int? releaseYear;
  final bool? isDiscontinued;
  final String? imageUrl;
  final List<String> modelFeatures;
  final List<String> consumables;
  final List<ProductConsumable> consumableDetails;
  final String? installationType;
  final String? guideVideoUrl;
  final String? guideVideoTitle;
  final String? guideVideoChannel;
  final List<String> keywords;
  final String reviewStatus;

  factory ProductCatalogEntry.fromJson(Map<String, Object?> json) {
    return ProductCatalogEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ZoneItemType.values.byName(json['type'] as String),
      categoryName: json['categoryName'] as String,
      brand: json['brand'] as String,
      manufacturer: json['manufacturer'] as String,
      modelName: json['modelName'] as String,
      seriesName: json['seriesName'] as String? ?? '',
      summary: json['summary'] as String,
      frequency: json['frequency'] as String,
      recurrenceDays: json['recurrenceDays'] as int,
      estimatedMinutes: json['estimatedMinutes'] as int,
      productMethod: json['productMethod'] as String,
      guideStatus: json['guideStatus'] as String,
      guideBasis: json['guideBasis'] as String,
      guideSourceType: GuideSourceType.values.byName(
        json['guideSourceType'] as String,
      ),
      matchLevelLabel: json['matchLevelLabel'] as String,
      sourceTitle: json['sourceTitle'] as String,
      sourceUrl: json['sourceUrl'] as String,
      sourceCheckedAt: DateTime.parse(json['sourceCheckedAt'] as String),
      productSpecs: (json['productSpecs'] as List<dynamic>).cast<String>(),
      supplies: (json['supplies'] as List<dynamic>).cast<String>(),
      recommendedSupplies:
          (json['recommendedSupplies'] as List<dynamic>).cast<String>(),
      recommendedProducts:
          (json['recommendedProducts'] as List<dynamic>? ?? const [])
              .map(
                (item) => CleaningProduct.fromJson(
                  Map<String, Object?>.from(item as Map),
                ),
              )
              .toList(),
      cautions: (json['cautions'] as List<dynamic>).cast<String>(),
      steps: (json['steps'] as List<dynamic>).cast<String>(),
      sources: (json['sources'] as List<dynamic>? ?? const [])
          .map(
            (source) => ProductSource.fromJson(
              Map<String, Object?>.from(source as Map),
            ),
          )
          .toList(),
      specSourceIds: _sourceReferencesFromJson(json['specSourceIds']),
      stepSourceIds: _sourceReferencesFromJson(json['stepSourceIds']),
      reviewHistory: (json['reviewHistory'] as List<dynamic>? ?? const [])
          .map(
            (record) => CatalogReviewRecord.fromJson(
              Map<String, Object?>.from(record as Map),
            ),
          )
          .toList(),
      officialManualUrl: json['officialManualUrl'] as String?,
      supportUrl: json['supportUrl'] as String?,
      servicePhone: json['servicePhone'] as String?,
      releaseYear: json['releaseYear'] as int?,
      isDiscontinued: json['isDiscontinued'] as bool?,
      imageUrl: json['imageUrl'] as String?,
      modelFeatures:
          (json['modelFeatures'] as List<dynamic>? ?? const []).cast<String>(),
      consumables:
          (json['consumables'] as List<dynamic>? ?? const []).cast<String>(),
      consumableDetails:
          (json['consumableDetails'] as List<dynamic>? ?? const [])
              .map(
                (item) => ProductConsumable.fromJson(
                  Map<String, Object?>.from(item as Map),
                ),
              )
              .toList(),
      installationType: json['installationType'] as String?,
      guideVideoUrl: json['guideVideoUrl'] as String?,
      guideVideoTitle: json['guideVideoTitle'] as String?,
      guideVideoChannel: json['guideVideoChannel'] as String?,
      keywords: (json['keywords'] as List<dynamic>? ?? const []).cast<String>(),
      reviewStatus: json['reviewStatus'] as String? ?? 'reviewed',
    );
  }

  ZoneItem toZoneItem({
    required String id,
    required String zoneId,
  }) {
    return ZoneItem(
      id: id,
      zoneId: zoneId,
      catalogProductId: this.id,
      productSources: sources,
      name: name,
      type: type,
      summary: summary,
      frequency: frequency,
      supplies: supplies,
      cautions: cautions,
      steps: steps,
      estimatedMinutes: estimatedMinutes,
      manufacturer: manufacturer,
      seriesName: seriesName,
      modelName: modelName,
      modelDisplayName: modelName.isEmpty ? null : name,
      modelReleaseYear: releaseYear,
      modelImageUrl: imageUrl,
      officialProductUrl: sourceUrl.isEmpty ? null : sourceUrl,
      officialManualUrl: officialManualUrl,
      supportUrl: supportUrl,
      servicePhone: servicePhone,
      modelFeatures: modelFeatures,
      productMethod: productMethod,
      guideStatus: guideStatus,
      guideVideoUrl: guideVideoUrl,
      guideVideoTitle: guideVideoTitle,
      guideVideoChannel: guideVideoChannel,
      guideBasis: guideBasis,
      guideSourceType: guideSourceType,
      recurrenceDays: recurrenceDays,
      recommendedSupplies: recommendedSupplies,
      recommendedProducts: recommendedProducts,
      consumables: consumableDetails,
      sourceTitle: sourceTitle,
      sourceUrl: sourceUrl,
      sourceCheckedAt: sourceCheckedAt,
      matchLevelLabel: matchLevelLabel,
      productSpecs: productSpecs,
    );
  }

  ZoneItem mergeInto(ZoneItem item) {
    final catalogItem = toZoneItem(id: item.id, zoneId: item.zoneId);
    return ZoneItem(
      id: catalogItem.id,
      zoneId: catalogItem.zoneId,
      catalogProductId: catalogItem.catalogProductId,
      productSources: catalogItem.productSources,
      nickname: item.nickname,
      purchaseDate: item.purchaseDate,
      installedDate: item.installedDate,
      note: item.note,
      name: catalogItem.name,
      type: catalogItem.type,
      summary: catalogItem.summary,
      frequency: catalogItem.frequency,
      supplies: catalogItem.supplies,
      cautions: catalogItem.cautions,
      steps: catalogItem.steps,
      estimatedMinutes: catalogItem.estimatedMinutes,
      manufacturer: catalogItem.manufacturer,
      seriesName: catalogItem.seriesName,
      modelName: catalogItem.modelName,
      modelDisplayName: catalogItem.modelDisplayName,
      modelReleaseYear: catalogItem.modelReleaseYear,
      modelImageUrl: catalogItem.modelImageUrl,
      officialProductUrl: catalogItem.officialProductUrl,
      officialManualUrl: catalogItem.officialManualUrl,
      supportUrl: catalogItem.supportUrl,
      servicePhone: catalogItem.servicePhone,
      modelFeatures: catalogItem.modelFeatures,
      productMethod: catalogItem.productMethod,
      guideStatus: catalogItem.guideStatus,
      guideVideoUrl: catalogItem.guideVideoUrl,
      guideVideoTitle: catalogItem.guideVideoTitle,
      guideVideoChannel: catalogItem.guideVideoChannel,
      guideBasis: catalogItem.guideBasis,
      sourceTitle: catalogItem.sourceTitle,
      sourceUrl: catalogItem.sourceUrl,
      sourceCheckedAt: catalogItem.sourceCheckedAt,
      matchLevelLabel: catalogItem.matchLevelLabel,
      productSpecs: catalogItem.productSpecs,
      guideSourceType: catalogItem.guideSourceType,
      recurrenceDays: catalogItem.recurrenceDays,
      lastCleanedAt: item.lastCleanedAt,
      nextDueAt: catalogItem.recurrenceDays > 0 ? item.nextDueAt : null,
      recommendedSupplies: catalogItem.recommendedSupplies,
      recommendedProducts: catalogItem.recommendedProducts,
      consumables: catalogItem.consumables.isEmpty
          ? item.consumables
          : catalogItem.consumables,
    );
  }

  bool matches(String query) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) {
      return true;
    }

    final haystack = [
      name,
      categoryName,
      brand,
      manufacturer,
      seriesName,
      modelName,
      productMethod,
      ...keywords,
    ].map(_normalize).join(' ');
    return haystack.contains(normalizedQuery);
  }

  List<String> validateForPublication() {
    final issues = <String>[];
    if (id.trim().isEmpty ||
        name.trim().isEmpty ||
        categoryName.trim().isEmpty ||
        productMethod.trim().isEmpty ||
        guideStatus.trim().isEmpty ||
        sourceCheckedAt.isAfter(DateTime.now())) {
      issues.add('필수 제품 정보가 비어 있거나 확인일이 올바르지 않습니다.');
    }
    if (!const {'reviewed', 'verified'}.contains(reviewStatus)) {
      issues.add('공개 제품은 reviewed 또는 verified 상태여야 합니다.');
    }
    if (sources.isEmpty) {
      issues.add('하나 이상의 출처가 필요합니다.');
    }
    final sourceIds = {for (final source in sources) source.id};
    for (final references in [
      ...specSourceIds.values,
      ...stepSourceIds.values
    ]) {
      if (references.any((id) => !sourceIds.contains(id))) {
        issues.add('존재하지 않는 출처를 참조하고 있습니다.');
        break;
      }
    }
    if (reviewHistory.isEmpty) {
      issues.add('검수 이력이 필요합니다.');
    }
    for (final spec in productSpecs) {
      if (!RegExp(r'\d').hasMatch(spec)) {
        continue;
      }
      final label = spec.split(':').first.trim();
      if (specSourceIds[label]?.isNotEmpty != true) {
        issues.add('숫자 스펙 "$label"에 연결된 출처가 없습니다.');
      }
    }
    return issues;
  }

  bool needsSourceReview(
    DateTime now, {
    int maxAgeDays = 180,
  }) {
    return sources.any(
      (source) => source.needsReview(now, maxAgeDays: maxAgeDays),
    );
  }
}

Map<String, List<String>> _sourceReferencesFromJson(Object? value) {
  if (value is! Map) {
    return const {};
  }
  return {
    for (final entry in value.entries)
      entry.key.toString(): (entry.value as List<dynamic>).cast<String>(),
  };
}

const _checkedAt = '2026-06-08';

final productCatalog = <ProductCatalogEntry>[
  ProductCatalogEntry(
    id: 'eco-up-dcs-hm4ag-w',
    name: '에코업 음식물처리기',
    type: ZoneItemType.appliance,
    categoryName: '음식물처리기',
    brand: '에코업',
    manufacturer: '제이앤에이치컴퍼니',
    modelName: 'DCS-HM4AG-W',
    productMethod: '싱크대 내장형 · 습식분쇄 + 미생물',
    guideStatus:
        '모델명과 처리방식은 확인했지만 공식 사용설명서는 아직 확보하지 못했어요. 손이 닿는 외부의 안전한 일상 관리만 안내해요.',
    guideBasis:
        'DCS-HM4AG-W의 공개 스펙과 에코업 세척 영상을 분리해 확인했어요. 공식 관리 주기와 내부 작업은 미확인 상태예요.',
    guideSourceType: GuideSourceType.officialVideo,
    matchLevelLabel: '모델명 일치',
    sourceTitle: '다나와 공개 스펙 및 에코업 세척 영상',
    sourceUrl: 'https://prod.danawa.com/info/?pcode=96061655',
    sourceCheckedAt: DateTime(2026, 6, 12),
    sources: [
      ProductSource(
        id: 'eco-up-spec',
        title: '제이앤에이치컴퍼니 에코업 DCS-HM4AG-W 상세 스펙',
        url: 'https://prod.danawa.com/info/?pcode=96061655',
        type: ProductSourceType.priceComparison,
        publisher: '다나와',
        checkedAt: DateTime(2026, 6, 12),
        supports: const [
          '제조사',
          '모델명',
          '처리방식',
          '설치형태',
          '처리용량',
          '소음',
          '크기와 무게',
        ],
        isOfficial: false,
        isActive: true,
      ),
      ProductSource(
        id: 'eco-up-cleaning-video',
        title: '분쇄기 세척방법',
        url: 'https://www.youtube.com/watch?v=NhcPjcHIJkw',
        type: ProductSourceType.officialVideo,
        publisher: '에코업 음식물처리기',
        checkedAt: DateTime.parse(_checkedAt),
        supports: const ['투입구 주변 관리', '세척 시 주의사항', '이상 발생 시 대응'],
        isOfficial: true,
        isActive: true,
      ),
    ],
    specSourceIds: const {
      '처리방식': ['eco-up-spec'],
      '설치형태': ['eco-up-spec'],
      '처리용량': ['eco-up-spec'],
      '소음': ['eco-up-spec'],
      '크기': ['eco-up-spec'],
      '무게': ['eco-up-spec'],
    },
    stepSourceIds: const {
      '0': ['eco-up-cleaning-video'],
      '1': ['eco-up-cleaning-video'],
      '2': ['eco-up-cleaning-video'],
    },
    reviewHistory: [
      CatalogReviewRecord(
        status: 'reviewed',
        reviewer: 'catalog-editor',
        reviewedAt: DateTime(2026, 6, 8),
        note: '모델명과 공개 스펙을 확인하고 위험한 분해 단계를 제외함.',
      ),
      CatalogReviewRecord(
        status: 'reviewed',
        reviewer: 'catalog-editor',
        reviewedAt: DateTime(2026, 6, 12),
        note: '공식 설명서와 관리 주기를 확인하지 못해 외부 일상 관리 범위로 축소하고 미확인 값을 제거함.',
      ),
    ],
    installationType: '싱크대 내장형',
    guideVideoUrl: 'https://www.youtube.com/watch?v=NhcPjcHIJkw',
    guideVideoTitle: '분쇄기 세척방법',
    guideVideoChannel: '에코업 음식물처리기',
    productSpecs: const [
      '처리방식: 습식분쇄 + 미생물',
      '설치형태: 싱크대 내장형',
      '처리용량: 1kg',
      '소음: 약 40dB',
      '크기: 약 360 x 395 x 260mm',
      '무게: 약 10kg',
    ],
    summary:
        '싱크대 하부에 설치하는 습식분쇄·미생물 방식 음식물처리기예요. 공식 설명서를 확보하기 전에는 손이 닿는 외부만 관리해요.',
    frequency: '공식 관리 주기 미확인 · 오염은 발견 즉시 닦고 이상이 있으면 사용 중단',
    recurrenceDays: 0,
    estimatedMinutes: 0,
    supplies: const ['부드러운 천', '작은 솔', '고무장갑'],
    recommendedSupplies: const [
      '입구 주변을 닦기 쉬운 부드러운 틈새 솔',
      '방수성이 좋은 니트릴 장갑',
      '싱크대 주변 물기를 닦을 극세사 천',
    ],
    recommendedProducts: const [],
    cautions: const [
      '본체, 배관, 교반실을 임의로 분해하지 마세요.',
      '투입구 안에 손이나 청소 도구를 깊이 넣지 마세요.',
      '락스나 강한 배수관 세정제는 미생물과 부품에 영향을 줄 수 있어 제조사 확인 없이 사용하지 마세요.',
      '냄새, 누수, 이상 소음이 있으면 사용을 중단하고 설치업체나 제조사에 문의하세요.',
    ],
    steps: const [
      '제품이 작동 중이 아닌지 확인하고 투입구 주변을 비워요.',
      '투입구 가장자리에 남은 음식물 찌꺼기를 작은 솔로 조심스럽게 제거해요.',
      '부드러운 천에 소량의 물을 묻혀 투입구와 싱크대 접합부를 닦아요.',
    ],
    keywords: const [
      '음처기',
      '음식물',
      '처리기',
      'DCS',
      'HM4AG',
      '에코업',
      'DCS HM4AG W',
      'DCS-HM4AGW',
    ],
    reviewStatus: 'reviewed',
  ),
  _verifiedSamsungRefrigerator(
    id: 'samsung-rm70f63r2a',
    name: 'Bespoke AI 냉장고 4도어 키친핏 Max 640L',
    modelName: 'RM70F63R2A',
    productMethod: '4도어 · 키친핏 Max',
    productUrl:
        'https://www.samsung.com/sec/refrigerators/french-door-rm70f63r2a-d2c/RM70F63R2A/',
    imageUrl:
        'https://images.samsung.com/kdp/goods/2025/02/24/49dd1432-b1cc-4b81-b97d-ce0a7f8ef465.png',
    modelFeatures: const ['키친핏 Max', '640L', '4도어'],
    productSpecs: const [
      '용량: 640L',
      '도어: 4도어',
      '설치 형태: 키친핏 Max',
      '최소 좌우 설치 간격: 각 4mm',
      '출시 연도: 2025년',
    ],
    installationType: '키친핏 Max · 좌우 각 4mm 설치 간격',
  ),
  _verifiedSamsungRefrigerator(
    id: 'samsung-rm80f91h1w',
    name: 'Bespoke AI 하이브리드 4도어 874L',
    modelName: 'RM80F91H1W',
    productMethod: '4도어 · AI 하이브리드 · 오토오픈도어',
    productUrl:
        'https://www.samsung.com/sec/refrigerators/french-door-rm80f91h1w-d2c/RM80F91H1W/',
    imageUrl:
        'https://images.samsung.com/kdp/goods/2025/03/05/95443b88-5455-41d1-b3dd-8e9002e6d995.png',
    modelFeatures: const ['AI 하이브리드', '874L', '오토오픈도어'],
    productSpecs: const [
      '용량: 874L',
      '도어: 4도어',
      '주요 기능: AI 하이브리드 · 오토오픈도어 · 베버리지 존',
      'UV 청정탈취 필터 권장 사용기간: 10년',
      '출시 연도: 2025년',
    ],
    installationType: '프리스탠딩 4도어',
    consumables: const ['UV 청정탈취 필터'],
    consumableDetails: const [
      ProductConsumable(
        id: 'rm80f91h1w-uv-deodorizing-filter',
        name: 'UV 청정탈취 필터',
        type: ConsumableType.filter,
        replacementDays: 3650,
        compatibilityLabel: 'RM80F91H1W 공식 확인',
        note: '삼성전자 권장 사용기간은 10년이며 실제 수명은 사용 환경에 따라 달라질 수 있어요. '
            '정확한 부품번호와 교체 가능 여부는 서비스센터에서 확인하세요.',
      ),
    ],
    installationGuideUrls: const [
      'https://downloadcenter.samsung.com/content/EM/202604/20260401071252508/DA68-04370A-05_IB_REF_KO_KO_260304.pdf',
      'https://downloadcenter.samsung.com/content/EM/202211/20221125151638571/DA68-02624H-02_MANUAL_INSTRUCTION_TTYPE_KO_220725.pdf',
    ],
  ),
  _verifiedSamsungRefrigerator(
    id: 'samsung-rm70f90m1zd',
    name: 'Bespoke AI 냉장고 4도어 902L',
    modelName: 'RM70F90M1ZD',
    productMethod: '4도어 · 대용량',
    productUrl:
        'https://www.samsung.com/sec/refrigerators/french-door-rm70f90m1zd-d2c/RM70F90M1ZD/',
    imageUrl:
        'https://images.samsung.com/kdp/goods/2025/06/27/75ffe596-f6fc-4119-827f-675e5ff47e09.png',
    modelFeatures: const ['대용량', '902L', '4도어'],
    productSpecs: const [
      '용량: 902L',
      '도어: 4도어',
      '설치 형태: 프리스탠딩',
      '출시 연도: 2025년',
    ],
    installationType: '프리스탠딩 4도어',
    installationGuideUrls: const [
      'https://downloadcenter.samsung.com/content/EM/202604/20260401071252508/DA68-04370A-05_IB_REF_KO_KO_260304.pdf',
      'https://downloadcenter.samsung.com/content/EM/202211/20221125151638571/DA68-02624H-02_MANUAL_INSTRUCTION_TTYPE_KO_220725.pdf',
    ],
  ),
  ProductCatalogEntry(
    id: 'generic-refrigerator',
    name: '냉장고',
    type: ZoneItemType.appliance,
    categoryName: '냉장고',
    brand: '브랜드 미상',
    manufacturer: '',
    modelName: '',
    productMethod: '일반 가정용 냉장고',
    guideStatus: '모델 정보가 없어 냉장고 공통 관리법을 안내해요.',
    guideBasis: '냉장고 선반, 문 고무패킹, 내부 물기 제거에 공통으로 적용되는 일반 관리법이에요.',
    guideSourceType: GuideSourceType.general,
    matchLevelLabel: '제품군 기준',
    sourceTitle: '앱 기본 관리법',
    sourceUrl: '',
    sourceCheckedAt: DateTime.parse(_checkedAt),
    sources: [
      ProductSource(
        id: 'generic-refrigerator-guide',
        title: '앱 냉장고 일반 관리법',
        type: ProductSourceType.generalGuidance,
        publisher: '앱 편집팀',
        checkedAt: DateTime.parse(_checkedAt),
        supports: const ['선반과 서랍 관리', '고무패킹 관리', '유리 선반 주의사항'],
        isOfficial: false,
        isActive: true,
      ),
    ],
    stepSourceIds: const {
      '0': ['generic-refrigerator-guide'],
      '1': ['generic-refrigerator-guide'],
      '2': ['generic-refrigerator-guide'],
      '3': ['generic-refrigerator-guide'],
    },
    reviewHistory: [
      CatalogReviewRecord(
        status: 'reviewed',
        reviewer: 'catalog-editor',
        reviewedAt: DateTime(2026, 6, 8),
        note: '제품군 공통 관리법이며 모델별 설명서를 우선하도록 표시함.',
      ),
    ],
    productSpecs: const ['모델 정보 없음'],
    summary: '선반과 문 고무패킹까지 닦아 냄새와 음식물 흔적을 줄여요.',
    frequency: '한 달마다',
    recurrenceDays: 30,
    estimatedMinutes: 20,
    supplies: const ['중성세제', '부드러운 천', '마른 수건'],
    recommendedSupplies: const [
      '부직포 행주 또는 극세사 천',
      '향이 강하지 않은 주방용 중성세제',
      '문 고무패킹을 닦기 좋은 작은 솔',
    ],
    recommendedProducts: const [
      CleaningProduct(
        brand: '코멧',
        name: '부직포 행주 20개입',
        reason: '냉장고 선반과 내부 물기를 닦고 바로 교체하기 쉬운 일상용 행주예요.',
        url: 'https://www.coupang.com/np/categories/105949',
      ),
    ],
    cautions: const ['유리 선반은 실온에 두었다가 닦아 급격한 온도 변화를 피하세요.'],
    steps: const [
      '상하기 쉬운 식품을 보냉 가방에 옮겨요.',
      '선반과 서랍을 분리해 중성세제로 닦아요.',
      '내부 벽면과 문 고무패킹을 부드러운 천으로 닦아요.',
      '물기를 완전히 제거한 뒤 식품을 다시 정리해요.',
    ],
    keywords: const ['냉장고', '김치냉장고', 'refrigerator'],
  ),
  ProductCatalogEntry(
    id: 'generic-air-purifier',
    name: '공기청정기',
    type: ZoneItemType.appliance,
    categoryName: '공기청정기',
    brand: '브랜드 미상',
    manufacturer: '',
    modelName: '',
    productMethod: '필터형 공기청정기',
    guideStatus: '모델 정보가 없어 필터형 공기청정기 공통 관리법을 안내해요.',
    guideBasis: '대부분의 필터형 공기청정기에 공통으로 적용되는 외부 먼지와 프리필터 관리법이에요.',
    guideSourceType: GuideSourceType.general,
    matchLevelLabel: '제품군 기준',
    sourceTitle: '앱 기본 관리법',
    sourceUrl: '',
    sourceCheckedAt: DateTime.parse(_checkedAt),
    sources: [
      ProductSource(
        id: 'generic-air-purifier-guide',
        title: '앱 공기청정기 일반 관리법',
        type: ProductSourceType.generalGuidance,
        publisher: '앱 편집팀',
        checkedAt: DateTime.parse(_checkedAt),
        supports: const ['외부 흡입구 관리', '프리필터 관리', '필터 물세척 주의'],
        isOfficial: false,
        isActive: true,
      ),
    ],
    stepSourceIds: const {
      '0': ['generic-air-purifier-guide'],
      '1': ['generic-air-purifier-guide'],
      '2': ['generic-air-purifier-guide'],
      '3': ['generic-air-purifier-guide'],
    },
    reviewHistory: [
      CatalogReviewRecord(
        status: 'reviewed',
        reviewer: 'catalog-editor',
        reviewedAt: DateTime(2026, 6, 8),
        note: '필터형 제품군의 안전한 외부 관리 범위만 포함함.',
      ),
    ],
    productSpecs: const ['모델 정보 없음'],
    summary: '외부 먼지와 프리필터를 관리해 흡입 효율을 유지해요.',
    frequency: '한 달마다',
    recurrenceDays: 30,
    estimatedMinutes: 15,
    supplies: const ['청소기 브러시', '마른 천'],
    recommendedSupplies: const ['먼지 제거용 브러시', '정전기 먼지떨이'],
    recommendedProducts: const [],
    cautions: const [
      '헤파필터는 물세척 가능 여부를 반드시 설명서에서 확인하세요.',
      '전원을 분리한 뒤 필터 커버를 여세요.',
    ],
    steps: const [
      '전원을 끄고 플러그를 분리해요.',
      '외부 흡입구 먼지를 청소기 브러시로 제거해요.',
      '프리필터가 분리되면 설명서에 맞게 먼지를 털거나 세척해요.',
      '완전히 건조한 뒤 다시 장착해요.',
    ],
    keywords: const ['공청기', '공기청정', '필터'],
  ),
  ..._representativeApplianceCatalog,
];

final _representativeApplianceCatalog = <ProductCatalogEntry>[
  _representativeAppliance(
    id: 'samsung-bespoke-ai-refrigerator-4door',
    name: '삼성 Bespoke AI 냉장고 4도어',
    categoryName: '냉장고',
    seriesName: 'Bespoke AI 4도어',
    productMethod: '상냉장·하냉동 4도어 냉장고 시리즈',
    summary: '선반, 서랍, 문 고무패킹과 내부 물기를 중심으로 관리해요.',
    frequency: '내부 오염은 발견 즉시 · 전체 내부는 한 달마다',
    recurrenceDays: 30,
    estimatedMinutes: 20,
    officialTitle: '삼성전자 Bespoke AI 4도어 냉장고 공식 제품군',
    officialUrl: 'https://www.samsung.com/sec/refrigerators/all-refrigerators/',
    supplies: const ['부드러운 천', '중성세제', '마른 수건'],
    cautions: const [
      '유리 선반은 실온에 둔 뒤 닦아 급격한 온도 변화를 피하세요.',
      '내부에 세제를 직접 분사하지 마세요.',
    ],
    steps: const [
      '상하기 쉬운 식품을 보냉 가방에 옮겨요.',
      '분리 가능한 선반과 서랍을 제품 설명서에 따라 꺼내요.',
      '중성세제를 묻힌 부드러운 천으로 내부와 문 고무패킹을 닦아요.',
      '물기를 완전히 제거한 뒤 부품과 식품을 다시 넣어요.',
    ],
    productSpecs: const [
      '시리즈: Bespoke AI',
      '형태: 4도어 냉장고',
      '정확한 모델명은 제품 내부 라벨에서 확인',
    ],
    keywords: const [
      '냉장고',
      '비스포크',
      '비스포크 AI',
      'Bespoke AI',
      '4도어',
      'refrigerator',
      '삼성',
    ],
  ),
  _representativeAppliance(
    id: 'lg-dios-objet-refrigerator-top-bottom',
    name: 'LG 디오스 오브제컬렉션 냉장고',
    categoryName: '냉장고',
    brand: 'LG전자',
    seriesName: '디오스 오브제컬렉션 상냉장·하냉동',
    productMethod: '상냉장·하냉동 냉장고 시리즈',
    summary: '선반, 서랍, 도어 패킹과 내부의 음식물 흔적을 안전하게 관리해요.',
    frequency: '내부 오염은 발견 즉시 · 전체 내부는 한 달마다',
    recurrenceDays: 30,
    estimatedMinutes: 20,
    officialTitle: 'LG전자 냉장고 공식 제품군',
    officialUrl: 'https://www.lge.co.kr/category/refrigerators',
    supplies: const ['부드러운 천', '중성세제', '마른 수건'],
    cautions: const [
      '유리 선반은 차가운 상태에서 뜨거운 물로 씻지 마세요.',
      '조작부와 냉기 토출구에 물이나 세제를 직접 분사하지 마세요.',
    ],
    steps: const [
      '상하기 쉬운 식품을 보냉 가방이나 다른 냉장 공간으로 옮겨요.',
      '분리 가능한 선반과 서랍만 모델 설명서에 따라 꺼내요.',
      '희석한 중성세제를 묻힌 부드러운 천으로 내부와 도어 패킹을 닦아요.',
      '깨끗한 천으로 한 번 더 닦고 물기를 완전히 제거한 뒤 식품을 넣어요.',
    ],
    productSpecs: const [
      '시리즈: LG 디오스 오브제컬렉션',
      '형태: 상냉장·하냉동',
      '정확한 모델명은 제품 내부 라벨에서 확인',
    ],
    keywords: const [
      '냉장고',
      '디오스',
      '오브제컬렉션',
      '상냉장',
      '하냉동',
      'refrigerator',
      'LG',
    ],
  ),
  _representativeAppliance(
    id: 'samsung-bespoke-ai-washer',
    name: '삼성 Bespoke AI 세탁기',
    categoryName: '세탁기',
    seriesName: 'Bespoke AI 세탁기',
    productMethod: '삼성 드럼 세탁기 시리즈',
    summary: '세제함, 도어 패킹과 배수 필터를 관리하고 모델의 통세척 코스를 확인해요.',
    frequency: '세제함과 패킹은 오염 시 · 배수 필터는 한 달마다',
    recurrenceDays: 30,
    estimatedMinutes: 20,
    officialTitle: '삼성전자 Bespoke AI 세탁기 공식 제품군',
    officialUrl:
        'https://www.samsung.com/sec/washers-and-dryers/all-washers-and-dryers/',
    officialSupports: const ['브랜드', '시리즈', '제품 유형'],
    productSpecs: const [
      '시리즈: Bespoke AI 세탁기',
      '제품 유형: 드럼 세탁기',
      '정확한 모델명과 용량은 도어 안쪽 라벨에서 확인',
    ],
    supplies: const ['부드러운 천', '작은 솔', '고무장갑'],
    cautions: const [
      '필터를 열기 전에 전원을 끄고 잔수가 나올 수 있도록 수건을 준비하세요.',
      '세탁조 전용 기능과 세정제 사용 여부는 설명서를 우선 확인하세요.',
    ],
    steps: const [
      '세제함을 분리해 남은 세제와 섬유유연제를 씻어내요.',
      '도어 고무패킹의 이물질과 물기를 닦아요.',
      '배수 필터는 설명서의 분리 순서와 잔수 배출 방법을 따라 관리해요.',
      '빈 통 상태에서 모델 설명서에 표시된 통세척 코스를 실행해요.',
    ],
    keywords: const ['세탁기', '드럼', '비스포크 AI', 'Bespoke AI', '삼성'],
  ),
  _representativeAppliance(
    id: 'lg-tromm-objet-drum-washer',
    name: 'LG 트롬 오브제컬렉션 세탁기',
    categoryName: '세탁기',
    brand: 'LG전자',
    seriesName: '트롬 오브제컬렉션 드럼세탁기',
    productMethod: 'LG 드럼 세탁기 시리즈',
    summary: '세제통, 도어 고무패킹과 배수 필터를 관리하고 통살균 코스를 모델별로 확인해요.',
    frequency: '세제통과 패킹은 오염 시 · 배수 필터는 한 달마다 확인',
    recurrenceDays: 30,
    estimatedMinutes: 20,
    officialTitle: 'LG전자 드럼세탁기 공식 제품군',
    officialUrl:
        'https://www.lge.co.kr/category/washing-machines?subCateId=CT50000102',
    supplies: const ['부드러운 천', '작은 솔', '고무장갑', '낮은 받침 용기'],
    cautions: const [
      '배수 필터를 열기 전 전원을 끄고 잔수가 나올 수 있도록 용기와 수건을 준비하세요.',
      '염소계 세정제나 임의 세정제 사용은 모델 설명서를 먼저 확인하세요.',
    ],
    steps: const [
      '세제통을 모델 설명서에 따라 분리해 남은 세제와 섬유유연제를 씻어내요.',
      '도어 고무패킹 주름 안쪽의 이물질과 물기를 부드러운 천으로 닦아요.',
      '잔수를 먼저 배출한 뒤 배수 필터의 이물질을 제거하고 정확히 잠가요.',
      '빈 통 상태에서 모델에 표시된 통살균 또는 통세척 코스를 실행해요.',
    ],
    productSpecs: const [
      '시리즈: LG 트롬 오브제컬렉션',
      '제품 유형: 드럼 세탁기',
      '정확한 모델명과 용량은 도어 안쪽 라벨에서 확인',
    ],
    keywords: const [
      '세탁기',
      '드럼',
      '트롬',
      '오브제컬렉션',
      'TROMM',
      'LG',
    ],
  ),
  _representativeAppliance(
    id: 'samsung-kq65qnf70afxkr',
    name: '삼성 Neo QLED QNF70 TV',
    categoryName: 'TV',
    modelName: 'KQ65QNF70AFXKR',
    productMethod: '2025 Neo QLED 4K 163cm',
    summary: '화면에는 액체를 직접 뿌리지 않고 마른 극세사 천으로 가볍게 관리해요.',
    frequency: '화면 먼지는 필요할 때 · 통풍구는 한 달마다',
    recurrenceDays: 30,
    estimatedMinutes: 10,
    officialTitle: '2025 Neo QLED QNF70 공식 지원',
    officialUrl: 'https://www.samsung.com/sec/support/model/KQ65QNF70AFXKR/',
    officialSupports: const ['모델명', '163cm 화면', '4K 해상도', '2025 제품군'],
    productSpecs: const [
      '모델명: KQ65QNF70AFXKR',
      '화면 크기: 163cm',
      '해상도: 4K',
      '제품군: 2025 Neo QLED QNF70',
    ],
    specSourceIds: const {
      '모델명': ['samsung-kq65qnf70afxkr-official'],
      '화면 크기': ['samsung-kq65qnf70afxkr-official'],
      '해상도': ['samsung-kq65qnf70afxkr-official'],
      '제품군': ['samsung-kq65qnf70afxkr-official'],
    },
    supplies: const ['마른 극세사 천', '부드러운 먼지 브러시'],
    cautions: const [
      '화면에 물이나 세정제를 직접 분사하지 마세요.',
      '화면을 강하게 누르거나 거친 천으로 문지르지 마세요.',
    ],
    steps: const [
      'TV 전원을 끄고 화면의 열이 식을 때까지 기다려요.',
      '마른 극세사 천으로 화면 먼지를 힘주지 않고 닦아요.',
      '후면 통풍구와 스탠드의 먼지를 부드러운 브러시로 제거해요.',
      '케이블이 눌리거나 통풍구를 가리지 않는지 확인해요.',
    ],
    keywords: const ['TV', '텔레비전', 'QNF70', 'KQ65QNF70AFXKR', '삼성'],
    releaseYear: 2025,
  ),
  _representativeAppliance(
    id: 'samsung-bespoke-ai-windfree-classic',
    name: '삼성 Bespoke AI 무풍클래식',
    categoryName: '에어컨',
    seriesName: 'Bespoke AI 무풍클래식',
    productMethod: '삼성 스탠드형 무풍 에어컨 시리즈',
    summary: '흡입 필터의 먼지를 제거하고 완전히 건조한 뒤 다시 장착해요.',
    frequency: '흡입 필터는 2주마다 · 사용 전후 상태 확인',
    recurrenceDays: 14,
    estimatedMinutes: 20,
    officialTitle: '삼성전자 스탠드 에어컨 공식 제품군',
    officialUrl:
        'https://www.samsung.com/sec/air-conditioners/all-air-conditioners/',
    supplies: const ['청소기 브러시', '부드러운 천', '고무장갑'],
    cautions: const [
      '전원을 끄고 플러그 또는 차단기를 확인한 뒤 필터를 분리하세요.',
      '열교환기나 전기 부품에 물을 직접 뿌리지 마세요.',
    ],
    steps: const [
      '전원을 끄고 제품이 완전히 멈춘 것을 확인해요.',
      '설명서에 따라 흡입 필터를 분리해 먼지를 제거해요.',
      '물세척 가능한 필터만 세척하고 그늘에서 완전히 말려요.',
      '냄새, 누수 또는 이상 소음이 있으면 전문 서비스를 요청해요.',
    ],
    productSpecs: const [
      '시리즈: Bespoke AI 무풍클래식',
      '제품 유형: 스탠드 에어컨',
      '정확한 모델명은 측면 또는 하단 라벨에서 확인',
    ],
    keywords: const [
      '에어컨',
      '스탠드',
      '무풍',
      '무풍클래식',
      '비스포크 AI',
      'Bespoke AI',
      'air conditioner',
      '삼성',
    ],
  ),
  _representativeAppliance(
    id: 'samsung-ms23c3535ak',
    name: '삼성 전자레인지',
    categoryName: '전자레인지',
    modelName: 'MS23C3535AK',
    productMethod: '삼성 23L 전자레인지',
    summary: '내부 음식물 흔적과 회전판을 닦고 충분히 건조해 냄새를 줄여요.',
    frequency: '오염은 사용 후 · 내부 전체는 주 1회',
    recurrenceDays: 7,
    estimatedMinutes: 10,
    officialTitle: 'MS23C3535AK 공식 지원',
    officialUrl: 'https://www.samsung.com/sec/support/model/MS23C3535AK/',
    officialSupports: const ['모델명', '전자레인지 제품 유형'],
    productSpecs: const ['모델명: MS23C3535AK', '제품 유형: 전자레인지'],
    specSourceIds: const {
      '모델명': ['samsung-ms23c3535ak-official'],
    },
    supplies: const ['부드러운 천', '중성세제', '마른 수건'],
    cautions: const [
      '전원 플러그를 분리하고 내부가 식은 뒤 관리하세요.',
      '통풍구와 전기 부품에 물이 들어가지 않게 하세요.',
    ],
    steps: const [
      '전원을 분리하고 내부가 식었는지 확인해요.',
      '회전판과 받침을 분리해 중성세제로 닦아요.',
      '내부 벽면과 문 안쪽의 음식물 흔적을 부드러운 천으로 닦아요.',
      '모든 부품을 완전히 말린 뒤 다시 장착해요.',
    ],
    keywords: const ['전자레인지', 'microwave', 'MS23C3535AK', '삼성'],
  ),
  _representativeAppliance(
    id: 'samsung-vacuum-family',
    name: '삼성 무선청소기',
    categoryName: '청소기',
    productMethod: '삼성 Bespoke Jet 무선청소기 대표 제품군',
    summary: '먼지통, 브러시와 세척 가능한 필터를 제품 설명서에 맞게 관리해요.',
    frequency: '먼지통은 사용 후 · 브러시와 필터는 한 달마다',
    recurrenceDays: 30,
    estimatedMinutes: 15,
    officialTitle: '삼성전자 청소기 공식 제품군',
    officialUrl:
        'https://www.samsung.com/sec/vacuum-cleaners/all-vacuum-cleaners/',
    supplies: const ['마른 천', '작은 솔', '가위'],
    cautions: const [
      '배터리와 모터부는 물로 세척하지 마세요.',
      '세척한 필터는 완전히 건조한 뒤 장착하세요.',
    ],
    steps: const [
      '전원을 끄고 먼지통을 비워요.',
      '브러시에 감긴 머리카락과 실을 제거해요.',
      '설명서에서 물세척 가능하다고 표시된 부품만 세척해요.',
      '부품을 완전히 건조한 뒤 정확히 조립해요.',
    ],
    keywords: const ['청소기', '무선청소기', '비스포크 제트', 'vacuum', '삼성'],
  ),
  _representativeAppliance(
    id: 'samsung-dryer-family',
    name: '삼성 건조기',
    categoryName: '건조기',
    productMethod: '삼성 Bespoke AI 건조기 대표 제품군',
    summary: '보풀 필터는 사용할 때마다 비우고 센서와 열교환기는 설명서에 맞게 관리해요.',
    frequency: '보풀 필터는 사용할 때마다 · 센서는 한 달마다',
    recurrenceDays: 7,
    estimatedMinutes: 10,
    officialTitle: '삼성전자 세탁기·건조기 공식 제품군',
    officialUrl:
        'https://www.samsung.com/sec/washers-and-dryers/all-washers-and-dryers/',
    supplies: const ['부드러운 솔', '마른 천', '청소기 브러시'],
    cautions: const [
      '젖은 필터를 장착하거나 열교환기 핀을 강하게 누르지 마세요.',
      '제품 내부를 임의로 분해하지 마세요.',
    ],
    steps: const [
      '사용 후 보풀 필터를 꺼내 먼지를 제거해요.',
      '필터를 세척했다면 완전히 건조해 다시 장착해요.',
      '습도 센서를 부드러운 마른 천으로 닦아요.',
      '열교환기 관리는 모델별 설명서의 주기와 방법을 확인해요.',
    ],
    keywords: const ['건조기', '의류건조기', 'dryer', '비스포크', '삼성'],
  ),
  _representativeAppliance(
    id: 'samsung-air-purifier-family',
    name: '삼성 공기청정기',
    categoryName: '공기청정기',
    productMethod: '삼성 Bespoke 큐브 공기청정기 대표 제품군',
    summary: '흡입구와 프리필터의 먼지를 제거하고 교체 필터 상태를 확인해요.',
    frequency: '외부와 프리필터는 한 달마다',
    recurrenceDays: 30,
    estimatedMinutes: 15,
    officialTitle: '삼성전자 공기청정기 공식 제품군',
    officialUrl: 'https://www.samsung.com/sec/air-cleaner/all-air-cleaner/',
    supplies: const ['청소기 브러시', '마른 천'],
    cautions: const [
      '집진·탈취 필터의 물세척 가능 여부를 설명서에서 확인하세요.',
      '전원을 분리한 뒤 필터 커버를 여세요.',
    ],
    steps: const [
      '전원을 끄고 플러그를 분리해요.',
      '외부 흡입구의 먼지를 청소기 브러시로 제거해요.',
      '프리필터를 분리해 먼지를 털거나 허용된 경우 세척해요.',
      '필터를 완전히 건조하고 교체 필터의 상태를 확인해요.',
    ],
    keywords: const ['공기청정기', '공청기', '큐브', 'air purifier', '삼성'],
  ),
  _representativeAppliance(
    id: 'samsung-dishwasher-family',
    name: '삼성 식기세척기',
    categoryName: '식기세척기',
    productMethod: '삼성 Bespoke 식기세척기 대표 제품군',
    summary: '필터, 배수구 주변과 분사 노즐의 음식물 찌꺼기를 관리해요.',
    frequency: '필터는 주 1회 확인 · 내부 전체는 한 달마다',
    recurrenceDays: 7,
    estimatedMinutes: 15,
    officialTitle: '삼성전자 식기세척기 공식 제품군',
    officialUrl: 'https://www.samsung.com/sec/dishwashers/all-dishwashers/',
    supplies: const ['부드러운 솔', '마른 천', '고무장갑'],
    cautions: const [
      '필터와 분사 노즐을 분리하기 전에 전원을 끄세요.',
      '배수 펌프와 내부 배관은 임의로 분해하지 마세요.',
    ],
    steps: const [
      '전원을 끄고 내부가 식은 것을 확인해요.',
      '하단 필터를 설명서 순서에 따라 분리해 음식물 찌꺼기를 제거해요.',
      '분사 노즐 구멍과 문 패킹의 오염을 부드러운 솔로 닦아요.',
      '부품을 정확히 조립하고 빈 상태에서 허용된 관리 코스를 실행해요.',
    ],
    keywords: const ['식기세척기', 'dishwasher', '비스포크', '삼성'],
  ),
  _representativeAppliance(
    id: 'samsung-kimchi-refrigerator-family',
    name: '삼성 김치냉장고',
    categoryName: '김치냉장고',
    productMethod: '삼성 Bespoke 김치플러스 대표 제품군',
    summary: '김치통, 선반과 문 고무패킹의 음식물 흔적과 물기를 관리해요.',
    frequency: '오염은 발견 즉시 · 내부 전체는 한 달마다',
    recurrenceDays: 30,
    estimatedMinutes: 20,
    officialTitle: '삼성전자 김치냉장고 공식 제품군',
    officialUrl:
        'https://www.samsung.com/sec/kimchi-refrigerators/all-kimchi-refrigerators/',
    supplies: const ['부드러운 천', '중성세제', '마른 수건'],
    cautions: const [
      '김치통과 선반의 세척 가능 온도와 방법을 설명서에서 확인하세요.',
      '성에를 날카로운 도구나 열로 제거하지 마세요.',
    ],
    steps: const [
      '보관 식품을 다른 냉장 공간으로 옮겨요.',
      '김치통과 분리 가능한 선반을 중성세제로 닦아요.',
      '내부 벽면과 문 고무패킹의 국물 흔적을 부드러운 천으로 닦아요.',
      '물기를 완전히 제거하고 설정 온도를 확인한 뒤 식품을 넣어요.',
    ],
    keywords: const ['김치냉장고', '김치플러스', 'kimchi refrigerator', '삼성'],
  ),
];

ProductCatalogEntry _verifiedSamsungRefrigerator({
  required String id,
  required String name,
  required String modelName,
  required String productMethod,
  required String productUrl,
  required String imageUrl,
  required List<String> modelFeatures,
  required List<String> productSpecs,
  required String installationType,
  List<String> consumables = const [],
  List<ProductConsumable> consumableDetails = const [],
  List<String> installationGuideUrls = const [],
}) {
  const manualUrl =
      'https://downloadcenter.samsung.com/content/UM/202605/20260519113115223/DA68-04836T-01_RF9000F_2025_KO_260515.pdf';
  const htmlManualUrl =
      'https://downloadcenter.samsung.com/content/PM/202605/20260519113245024/KO/start_here.html';
  final productSourceId = '$id-product';
  final manualSourceId = '$id-manual';
  return ProductCatalogEntry(
    id: id,
    name: name,
    type: ZoneItemType.appliance,
    categoryName: '냉장고',
    brand: '삼성전자',
    manufacturer: '삼성전자',
    modelName: modelName,
    seriesName: 'Bespoke AI 4도어',
    summary: '삼성전자 공식 RF9000F 2025 사용설명서에 따라 문, 내부 부속품, 고무 패킹과 후면 먼지를 관리해요.',
    frequency: '오염은 발견 즉시 · 제품 뒷면 먼지는 1년에 한 번',
    recurrenceDays: 0,
    estimatedMinutes: 25,
    productMethod: productMethod,
    guideStatus: '정확한 모델과 공식 사용설명서를 확인했어요. 기능별 항목은 내 제품에 해당할 때만 적용하세요.',
    guideBasis: '삼성전자 공식 제품 페이지와 RF9000F 2025 사용자 매뉴얼 ver.4.0을 '
        '2026년 6월 13일 교차 확인했어요.',
    guideSourceType: GuideSourceType.official,
    matchLevelLabel: '공식 설명서 확인 모델',
    sourceTitle: '$name 공식 제품 페이지',
    sourceUrl: productUrl,
    sourceCheckedAt: DateTime(2026, 6, 13),
    sources: [
      ProductSource(
        id: productSourceId,
        title: '$name 공식 제품 페이지',
        url: productUrl,
        type: ProductSourceType.officialProduct,
        publisher: '삼성전자',
        checkedAt: DateTime(2026, 6, 13),
        supports: const ['제품명', '모델명', '용량', '주요 기능', '출시 연도', '대표 이미지'],
        isOfficial: true,
        isActive: true,
      ),
      ProductSource(
        id: manualSourceId,
        title: 'RF9000F 2025 사용자 매뉴얼 ver.4.0',
        url: manualUrl,
        type: ProductSourceType.officialManual,
        publisher: '삼성전자',
        checkedAt: DateTime(2026, 6, 13),
        supports: const [
          '청소 안전사항',
          '문 재질별 청소',
          '내부와 부속품 관리',
          '고무 패킹 관리',
          '제품 후면 먼지 관리',
          '기능별 조건부 관리',
        ],
        isOfficial: true,
        isActive: true,
      ),
      ProductSource(
        id: '$id-html-manual',
        title: 'RF9000F 2025 HTML 사용설명서',
        url: htmlManualUrl,
        type: ProductSourceType.officialManual,
        publisher: '삼성전자',
        checkedAt: DateTime(2026, 6, 13),
        supports: const ['모바일용 사용설명서'],
        isOfficial: true,
        isActive: true,
      ),
      for (var index = 0; index < installationGuideUrls.length; index++)
        ProductSource(
          id: '$id-install-${index + 1}',
          title: '삼성 냉장고 설치 안내 ${index + 1}',
          url: installationGuideUrls[index],
          type: ProductSourceType.officialManual,
          publisher: '삼성전자',
          checkedAt: DateTime(2026, 6, 13),
          supports: const ['설치 안전사항'],
          isOfficial: true,
          isActive: true,
        ),
    ],
    specSourceIds: {
      for (final spec in productSpecs)
        if (spec.contains(':')) spec.split(':').first.trim(): [productSourceId],
    },
    stepSourceIds: {
      '0': [manualSourceId],
      '1': [manualSourceId],
      '2': [manualSourceId],
      '3': [manualSourceId],
      '4': [manualSourceId],
    },
    reviewHistory: [
      CatalogReviewRecord(
        status: 'verified',
        reviewer: 'catalog-editor',
        reviewedAt: DateTime(2026, 6, 13),
        note: '공식 제품 페이지, 공통 사용자 매뉴얼과 설치 안내를 확인하고 '
            '사용자가 직접 수행할 수 있는 관리 범위만 반영함.',
      ),
    ],
    officialManualUrl: manualUrl,
    supportUrl: productUrl,
    servicePhone: '1588-3366',
    releaseYear: 2025,
    isDiscontinued: false,
    imageUrl: imageUrl,
    modelFeatures: modelFeatures,
    consumables: consumables,
    consumableDetails: consumableDetails,
    installationType: installationType,
    productSpecs: productSpecs,
    supplies: const ['부드러운 천', '마른 천 또는 수건', '면봉', '진공청소기'],
    recommendedSupplies: const [
      '표면이 거칠지 않은 극세사 천',
      '문 고무 패킹 홈을 닦을 면봉',
      '제품 후면 먼지를 제거할 진공청소기',
    ],
    recommendedProducts: const [],
    cautions: const [
      '청소 전에는 전원 플러그를 빼세요.',
      '제품에 물을 직접 뿌리지 마세요.',
      '락스, 아세톤, 시너, 알코올, 염화물, 벤젠을 사용하지 마세요.',
      '솔, 수세미, 거친 헝겊처럼 표면이 거친 도구를 사용하지 마세요.',
      '유리 선반은 따뜻한 물로 씻거나 충격을 가하지 마세요.',
      'LED 램프와 제품 내부 부품을 임의로 분리하지 마세요.',
    ],
    steps: const [
      '전원 플러그를 빼고 상하기 쉬운 식품을 다른 냉장 공간으로 옮겨요.',
      '문 재질을 확인해요. 스테인리스는 깨끗한 물을 묻힌 극세사 천으로, 유리는 유리 세정제 또는 중성세제를 묻힌 천으로 가볍게 닦고 마른 천으로 마무리해요.',
      '제품 내부와 분리한 박스·선반은 깨끗한 물을 묻힌 부드러운 천으로 닦고 완전히 말려요.',
      '문 고무 패킹은 깨끗한 물을 묻힌 부드러운 천으로 닦고 홈 사이는 면봉으로 닦아요.',
      '제품 뒷면은 1년에 한 번 정도 진공청소기로 먼지를 제거해요.',
    ],
    keywords: [
      modelName,
      modelName.replaceAll('-', ''),
      '비스포크 냉장고',
      'Bespoke AI 냉장고',
      'RF9000F',
    ],
    reviewStatus: 'verified',
  );
}

ProductCatalogEntry _representativeAppliance({
  required String id,
  required String name,
  required String categoryName,
  required String productMethod,
  required String summary,
  required String frequency,
  required int recurrenceDays,
  required int estimatedMinutes,
  required String officialTitle,
  required String officialUrl,
  required List<String> supplies,
  required List<String> cautions,
  required List<String> steps,
  required List<String> keywords,
  String brand = '삼성전자',
  String seriesName = '',
  String modelName = '',
  List<String> officialSupports = const ['브랜드', '제품군'],
  List<String> productSpecs = const ['정확한 모델명은 제품 라벨에서 확인'],
  Map<String, List<String>> specSourceIds = const {},
  int? releaseYear,
}) {
  final officialSourceId = '$id-official';
  final guideSourceId = '$id-editorial-guide';
  final effectiveSpecSourceIds = specSourceIds.isNotEmpty
      ? specSourceIds
      : {
          for (final spec in productSpecs)
            if (spec.contains(':'))
              spec.split(':').first.trim(): [officialSourceId],
        };
  return ProductCatalogEntry(
    id: id,
    name: name,
    type: ZoneItemType.appliance,
    categoryName: categoryName,
    brand: brand,
    manufacturer: brand,
    seriesName: seriesName,
    modelName: modelName,
    summary: summary,
    frequency: frequency,
    recurrenceDays: recurrenceDays,
    estimatedMinutes: estimatedMinutes,
    productMethod: productMethod,
    guideStatus: modelName.isNotEmpty
        ? '공식 지원 페이지에서 모델을 확인했어요. 관리 순서는 안전한 제품군 공통 범위로 안내해요.'
        : seriesName.isNotEmpty
            ? '$brand 공식 시리즈를 확인했어요. 정확한 모델별 분해·세척 방법은 제품 라벨과 설명서를 우선해요.'
            : '$brand 공식 제품군을 확인했어요. 정확한 시리즈와 모델은 제품 라벨과 설명서를 우선해요.',
    guideBasis: '공식 페이지는 제품 식별 근거로, 관리 순서는 앱 편집팀의 제품군 가이드로 분리해 표시해요.',
    guideSourceType:
        modelName.isEmpty ? GuideSourceType.general : GuideSourceType.official,
    matchLevelLabel: modelName.isNotEmpty
        ? '모델명 일치'
        : seriesName.isNotEmpty
            ? '시리즈 기준'
            : '브랜드 제품군 기준',
    sourceTitle: officialTitle,
    sourceUrl: officialUrl,
    sourceCheckedAt: DateTime(2026, 6, 12),
    sources: [
      ProductSource(
        id: officialSourceId,
        title: officialTitle,
        url: officialUrl,
        type: modelName.isEmpty
            ? ProductSourceType.officialProduct
            : ProductSourceType.officialSupport,
        publisher: brand,
        checkedAt: DateTime(2026, 6, 12),
        supports: officialSupports,
        isOfficial: true,
        isActive: true,
      ),
      ProductSource(
        id: guideSourceId,
        title: '$categoryName 안전 관리 가이드',
        type: ProductSourceType.generalGuidance,
        publisher: '앱 편집팀',
        checkedAt: DateTime(2026, 6, 12),
        supports: const ['준비물', '안전 주의사항', '외부 관리 순서', '권장 확인 주기'],
        isOfficial: false,
        isActive: true,
      ),
    ],
    specSourceIds: effectiveSpecSourceIds,
    stepSourceIds: {
      for (var index = 0; index < steps.length; index++)
        '$index': [guideSourceId],
    },
    reviewHistory: [
      CatalogReviewRecord(
        status: 'reviewed',
        reviewer: 'catalog-editor',
        reviewedAt: DateTime(2026, 6, 12),
        note: '공식 제품 식별 정보와 일반 관리 가이드의 근거 범위를 분리해 검수함.',
      ),
    ],
    productSpecs: productSpecs,
    supplies: supplies,
    recommendedSupplies: supplies,
    recommendedProducts: const [],
    cautions: cautions,
    steps: steps,
    keywords: keywords,
    reviewStatus: 'reviewed',
    releaseYear: releaseYear,
    supportUrl: officialUrl,
    servicePhone: '1588-3366',
  );
}

List<ProductCatalogEntry> searchProductCatalog(String query) {
  final matches =
      productCatalog.where((entry) => entry.matches(query)).toList();
  return sortProductCatalogResults(matches, query);
}

List<ProductCatalogEntry> sortProductCatalogResults(
  Iterable<ProductCatalogEntry> entries,
  String query,
) {
  final sorted = entries.toList();
  sorted
      .sort((a, b) => _searchScore(b, query).compareTo(_searchScore(a, query)));
  return sorted;
}

int _searchScore(ProductCatalogEntry entry, String query) {
  final normalizedQuery = _normalize(query);
  if (normalizedQuery.isEmpty) {
    return 0;
  }
  final model = _normalize(entry.modelName);
  final series = _normalize(entry.seriesName);
  final brand = _normalize(entry.brand);
  final category = _normalize(entry.categoryName);
  final name = _normalize(entry.name);
  if (model == normalizedQuery) {
    return 600;
  }
  if (model.contains(normalizedQuery)) {
    return 500;
  }
  if (series == normalizedQuery) {
    return 480;
  }
  if (series.contains(normalizedQuery)) {
    return 460;
  }
  if (normalizedQuery.contains(brand) && normalizedQuery.contains(category)) {
    return 400;
  }
  if (name == normalizedQuery || name.contains(normalizedQuery)) {
    return 300;
  }
  if (entry.keywords.any((keyword) => _normalize(keyword) == normalizedQuery)) {
    return 200;
  }
  return 100;
}

List<String> catalogCategoryOptions() {
  return {
    for (final entry in productCatalog) entry.categoryName,
    '싱크대',
    '전자레인지',
    '세탁기',
    '에어컨',
  }.toList()
    ..sort();
}

List<String> catalogBrandOptionsFor(String categoryName) {
  final options = {
    for (final entry in productCatalog)
      if (entry.categoryName == categoryName &&
          entry.brand.isNotEmpty &&
          entry.brand != '브랜드 미상')
        entry.brand,
  };
  if (categoryName.contains('음식물')) {
    options.addAll(['에코업', '제이앤에이치컴퍼니', '쿠쿠', '스마트카라']);
  }
  if (categoryName.contains('냉장고')) {
    options.addAll(['삼성전자', 'LG전자', '위니아']);
  }
  if (categoryName.contains('공기청정')) {
    options.addAll(['삼성전자', 'LG전자', '다이슨', '샤오미']);
  }
  if (_normalize(categoryName) == 'tv' || categoryName.contains('텔레비전')) {
    options.addAll(['삼성전자', 'LG전자', '소니']);
  }
  return options.toList()..sort();
}

List<String> catalogModelOptionsFor(String categoryName, String brand) {
  final options = {
    for (final entry in productCatalog)
      if (entry.categoryName == categoryName &&
          (entry.brand == brand || entry.manufacturer == brand) &&
          entry.modelName.isNotEmpty)
        entry.modelName,
  };
  if (categoryName.contains('음식물') &&
      (brand == '에코업' || brand == '제이앤에이치컴퍼니')) {
    options.addAll(['DCS-HM4AG-W', 'DCS-HM4AG', 'ECO-UP']);
  }
  if (categoryName.contains('냉장고')) {
    if (brand == '삼성전자') {
      options.addAll(['RM70F63R2A', 'RM80F91H1W', 'RM70F90M1ZD']);
    }
    if (brand == 'LG전자') {
      options.addAll(['M874GBB031', 'T873MEE312', 'S834MTE10']);
    }
  }
  if ((_normalize(categoryName) == 'tv' || categoryName.contains('텔레비전')) &&
      brand == '삼성전자') {
    options.addAll([
      'KQ65QNF90AFXKR',
      'KQ65QNF70AFXKR',
      'KQ75QNF900FXKR',
    ]);
  }
  return options.toList()..sort();
}

List<CatalogModelOption> catalogModelDetailsFor(
  String categoryName,
  String brand,
) {
  if (categoryName.contains('냉장고') && brand == '삼성전자') {
    return const [
      CatalogModelOption(
        modelName: 'RM70F63R2A',
        displayName: 'Bespoke AI 냉장고 4도어 키친핏 Max 640L',
        releaseYear: 2025,
        imageUrl:
            'https://images.samsung.com/kdp/goods/2025/02/24/49dd1432-b1cc-4b81-b97d-ce0a7f8ef465.png',
        productUrl:
            'https://www.samsung.com/sec/refrigerators/french-door-rm70f63r2a-d2c/RM70F63R2A/',
        features: ['키친핏 Max', '640L', '4도어'],
      ),
      CatalogModelOption(
        modelName: 'RM80F91H1W',
        displayName: 'Bespoke AI 하이브리드 4도어 874L',
        releaseYear: 2025,
        imageUrl:
            'https://images.samsung.com/kdp/goods/2025/03/05/95443b88-5455-41d1-b3dd-8e9002e6d995.png',
        productUrl:
            'https://www.samsung.com/sec/refrigerators/french-door-rm80f91h1w-d2c/RM80F91H1W/',
        features: ['AI 하이브리드', '874L', '오토오픈도어'],
      ),
      CatalogModelOption(
        modelName: 'RM70F90M1ZD',
        displayName: 'Bespoke AI 냉장고 4도어 902L',
        releaseYear: 2025,
        imageUrl:
            'https://images.samsung.com/kdp/goods/2025/06/27/75ffe596-f6fc-4119-827f-675e5ff47e09.png',
        productUrl:
            'https://www.samsung.com/sec/refrigerators/french-door-rm70f90m1zd-d2c/RM70F90M1ZD/',
        features: ['대용량', '902L', '4도어'],
      ),
    ];
  }
  return [
    for (final model in catalogModelOptionsFor(categoryName, brand))
      CatalogModelOption(modelName: model, displayName: model),
  ];
}

ProductCatalogEntry? findCatalogEntry({
  required String categoryName,
  required String brand,
  required String modelName,
}) {
  final normalizedCategory = _normalize(categoryName);
  final normalizedBrand = _normalize(brand);
  final normalizedModel = _normalize(modelName);

  for (final entry in productCatalog) {
    final brandMatches = _normalize(entry.brand) == normalizedBrand ||
        _normalize(entry.manufacturer) == normalizedBrand;
    final entryCategory = _normalize(entry.categoryName);
    final categoryMatches = entryCategory == normalizedCategory ||
        normalizedCategory.contains(entryCategory) ||
        entryCategory.contains(normalizedCategory);
    if (categoryMatches &&
        brandMatches &&
        _normalize(entry.modelName) == normalizedModel) {
      return entry;
    }
  }
  return null;
}

ProductCatalogEntry? findCatalogEntryById(String id) {
  for (final entry in productCatalog) {
    if (entry.id == id) {
      return entry;
    }
  }
  return null;
}

String _normalize(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+|-|_'), '');
}
