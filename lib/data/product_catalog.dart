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
    this.guideVideoUrl,
    this.guideVideoTitle,
    this.guideVideoChannel,
    this.keywords = const [],
  });

  final String id;
  final String name;
  final ZoneItemType type;
  final String categoryName;
  final String brand;
  final String manufacturer;
  final String modelName;
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
  final String? guideVideoUrl;
  final String? guideVideoTitle;
  final String? guideVideoChannel;
  final List<String> keywords;

  factory ProductCatalogEntry.fromJson(Map<String, Object?> json) {
    return ProductCatalogEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ZoneItemType.values.byName(json['type'] as String),
      categoryName: json['categoryName'] as String,
      brand: json['brand'] as String,
      manufacturer: json['manufacturer'] as String,
      modelName: json['modelName'] as String,
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
      guideVideoUrl: json['guideVideoUrl'] as String?,
      guideVideoTitle: json['guideVideoTitle'] as String?,
      guideVideoChannel: json['guideVideoChannel'] as String?,
      keywords: (json['keywords'] as List<dynamic>? ?? const []).cast<String>(),
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
      name: name,
      type: type,
      summary: summary,
      frequency: frequency,
      supplies: supplies,
      cautions: cautions,
      steps: steps,
      estimatedMinutes: estimatedMinutes,
      manufacturer: manufacturer,
      modelName: modelName,
      productMethod: productMethod,
      guideStatus: guideStatus,
      guideVideoUrl: guideVideoUrl,
      guideVideoTitle: guideVideoTitle,
      guideVideoChannel: guideVideoChannel,
      guideBasis: guideBasis,
      guideSourceType: guideSourceType,
      recurrenceDays: recurrenceDays,
      nextDueAt: DateTime.now(),
      recommendedSupplies: recommendedSupplies,
      recommendedProducts: recommendedProducts,
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
      name: catalogItem.name,
      type: catalogItem.type,
      summary: catalogItem.summary,
      frequency: catalogItem.frequency,
      supplies: catalogItem.supplies,
      cautions: catalogItem.cautions,
      steps: catalogItem.steps,
      estimatedMinutes: catalogItem.estimatedMinutes,
      manufacturer: catalogItem.manufacturer,
      modelName: catalogItem.modelName,
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
      nextDueAt: item.nextDueAt,
      recommendedSupplies: catalogItem.recommendedSupplies,
      recommendedProducts: catalogItem.recommendedProducts,
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
      modelName,
      productMethod,
      ...keywords,
    ].map(_normalize).join(' ');
    return haystack.contains(normalizedQuery);
  }
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
    guideStatus: '모델명과 처리방식을 확인했어요. 청소법은 공식 영상과 유사 제품군 기준을 함께 참고해요.',
    guideBasis: '동일 모델명 DCS-HM4AG-W의 공개 스펙과 에코업 분쇄기 세척 영상을 기준으로 정리했어요.',
    guideSourceType: GuideSourceType.officialVideo,
    matchLevelLabel: '모델명 일치',
    sourceTitle: '다나와/에누리 공개 스펙 및 에코업 세척 영상',
    sourceUrl: 'https://prod.danawa.com/info/?pcode=96061655',
    sourceCheckedAt: DateTime.parse(_checkedAt),
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
    summary: '싱크대 배수구 투입 방식의 에코업 하이브리드 음식물처리기예요.',
    frequency: '주 1회 가볍게 · 냄새나 이상 소음이 있으면 사용 중단 후 문의',
    recurrenceDays: 7,
    estimatedMinutes: 12,
    supplies: const ['부드러운 천', '작은 솔', '고무장갑'],
    recommendedSupplies: const [
      '입구 주변을 닦기 쉬운 부드러운 틈새 솔',
      '방수성이 좋은 니트릴 장갑',
      '싱크대 주변 물기를 닦을 극세사 천',
    ],
    recommendedProducts: const [
      CleaningProduct(
        brand: '스카치브라이트',
        name: '베이직 제로 스크래치 스펀지 수세미',
        reason: '투입구 주변처럼 흠집이 걱정되는 곳을 부드럽게 닦을 때 참고하기 좋아요.',
        url: 'https://www.coupang.com/np/categories/127929',
      ),
      CleaningProduct(
        brand: '탐사',
        name: '니트릴장갑 100매입',
        reason: '음식물처리기 주변을 만질 때 위생과 냄새 부담을 줄이는 일회용 장갑이에요.',
        url: 'https://www.coupang.com/np/categories/399685',
      ),
    ],
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
      '배수구 주변에 물고임, 누수 흔적, 변색이 없는지 눈으로 확인해요.',
      '냄새나 소음이 평소와 다르면 사용을 멈추고 제조사 안내를 확인해요.',
      '미생물 보충, 내부 세척, 배관 관리는 공식 설명서나 설치업체 안내에 따라 진행해요.',
    ],
    keywords: const ['음처기', '음식물', '처리기', 'DCS', 'HM4AG', '에코업'],
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
];

List<ProductCatalogEntry> searchProductCatalog(String query) {
  return productCatalog.where((entry) => entry.matches(query)).toList();
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
      if (entry.categoryName == categoryName && entry.brand.isNotEmpty)
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
      options.addAll(['RF85C90F1AP', 'RF85C9141AP', 'RF60C9013AP']);
    }
    if (brand == 'LG전자') {
      options.addAll(['M874GBB031', 'T873MEE312', 'S834MTE10']);
    }
  }
  return options.toList()..sort();
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

String _normalize(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+|-|_'), '');
}
