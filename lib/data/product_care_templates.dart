import '../models/catalog_metadata.dart';
import '../models/zone_item.dart';

class ProductCareTemplate {
  const ProductCareTemplate({
    required this.categoryName,
    required this.type,
    required this.summary,
    required this.frequency,
    required this.recurrenceDays,
    required this.supplies,
    required this.recommendedSupplies,
    required this.cautions,
    required this.steps,
    required this.focusAreas,
  });

  final String categoryName;
  final ZoneItemType type;
  final String summary;
  final String frequency;
  final int recurrenceDays;
  final List<String> supplies;
  final List<String> recommendedSupplies;
  final List<String> cautions;
  final List<String> steps;
  final List<String> focusAreas;

  ZoneItem createProduct({
    required String id,
    required String zoneId,
    String? nickname,
    DateTime? purchaseDate,
    DateTime? installedDate,
    String? note,
    String? manufacturer,
    String? modelName,
    String? scannedCode,
    String? scannedCodeFormat,
    String? scannedSourceUrl,
  }) {
    final checkedAt = DateTime(2026, 6, 9);
    final hasModel = modelName?.trim().isNotEmpty == true;
    final sourceId = 'general-${_normalize(categoryName)}';
    return ZoneItem(
      id: id,
      zoneId: zoneId,
      name: categoryName,
      nickname: nickname,
      purchaseDate: purchaseDate,
      installedDate: installedDate,
      note: note,
      scannedCode: scannedCode,
      scannedCodeFormat: scannedCodeFormat,
      scannedSourceUrl: scannedSourceUrl,
      type: type,
      summary: summary,
      frequency: frequency,
      supplies: supplies,
      recommendedSupplies: recommendedSupplies,
      cautions: cautions,
      steps: steps,
      manufacturer: manufacturer,
      modelName: modelName,
      guideStatus: hasModel
          ? '입력한 모델의 공식 자료를 찾기 전까지 $categoryName 제품군의 일반 관리법을 안내해요.'
          : '모델 정보가 없어 $categoryName 제품군의 일반 관리법을 안내해요.',
      guideBasis: '$categoryName 제품군의 구조와 주요 관리 지점을 기준으로 만든 일반 가이드예요. '
          '분해, 필터 세척과 전용 코스는 제품 설명서를 우선하세요.',
      guideSourceType:
          hasModel ? GuideSourceType.similarProduct : GuideSourceType.general,
      matchLevelLabel: hasModel ? '사용자 입력 모델 · 제품군 가이드' : '제품군 기준',
      sourceTitle: '앱 $categoryName 일반 관리법',
      sourceCheckedAt: checkedAt,
      productSources: [
        ProductSource(
          id: sourceId,
          title: '앱 $categoryName 일반 관리법',
          type: ProductSourceType.generalGuidance,
          publisher: '앱 편집팀',
          checkedAt: checkedAt,
          supports: focusAreas,
          isOfficial: false,
          isActive: true,
        ),
      ],
      productSpecs: [
        if (manufacturer?.trim().isNotEmpty == true)
          '브랜드/제조사: ${manufacturer!.trim()}',
        if (hasModel) '모델명: ${modelName!.trim()}',
        '관리 기준: ${focusAreas.join(', ')}',
      ],
      recurrenceDays: recurrenceDays,
    );
  }
}

ProductCareTemplate? findProductCareTemplate(String categoryName) {
  final query = _normalize(categoryName);
  for (final template in productCareTemplates) {
    final category = _normalize(template.categoryName);
    if (query == category ||
        query.contains(category) ||
        category.contains(query)) {
      return template;
    }
  }
  return null;
}

final productCareTemplates = <ProductCareTemplate>[
  const ProductCareTemplate(
    categoryName: '냉장고',
    type: ZoneItemType.appliance,
    summary: '식품을 비운 뒤 선반, 서랍, 내부 벽면과 문 고무패킹을 구분해 관리해요.',
    frequency: '내부 오염은 발견 즉시 · 전체 내부는 한 달마다 · 뒷면 먼지는 6개월마다',
    recurrenceDays: 30,
    supplies: ['부드러운 천', '주방용 중성세제', '마른 수건', '작은 솔'],
    recommendedSupplies: ['고무패킹용 작은 솔', '흡수력이 좋은 극세사 천', '보냉 가방'],
    cautions: [
      '유리 선반은 차가운 상태에서 뜨거운 물로 씻지 마세요.',
      '내부에 세제를 직접 분사하지 말고 천에 묻혀 사용하세요.',
      '냉각부와 전기 부품에 물이 닿지 않게 하세요.',
    ],
    steps: [
      '상하기 쉬운 식품을 보냉 가방으로 옮기고 전원을 분리해요.',
      '선반과 서랍을 꺼내 실온에 둔 뒤 중성세제로 닦아요.',
      '내부 벽면은 위에서 아래 방향으로 닦고 음식물 흔적을 제거해요.',
      '문 고무패킹의 홈을 작은 솔이나 천으로 닦아요.',
      '모든 부품의 물기를 완전히 제거한 뒤 조립하고 식품을 정리해요.',
    ],
    focusAreas: ['선반과 서랍', '내부 벽면', '문 고무패킹', '후면 통풍부'],
  ),
  const ProductCareTemplate(
    categoryName: '식기세척기',
    type: ZoneItemType.appliance,
    summary: '필터, 배수구 주변, 분사 노즐과 문 패킹의 음식물 찌꺼기를 각각 관리해요.',
    frequency: '필터는 주 1회 확인 · 내부와 분사 노즐은 한 달마다',
    recurrenceDays: 7,
    supplies: ['고무장갑', '부드러운 솔', '극세사 천', '제품 허용 세척제'],
    recommendedSupplies: ['필터 틈새용 작은 솔', '문 패킹용 부드러운 천', '식기세척기 전용 클리너'],
    cautions: [
      '필터와 분사 날개 분리 방법은 모델 설명서를 먼저 확인하세요.',
      '일반 주방세제는 거품이 과도하게 발생할 수 있어 사용하지 마세요.',
      '락스, 식초와 다른 세제를 섞지 마세요.',
      '배수구 세정제를 식기세척기 내부에 사용하지 마세요.',
    ],
    steps: [
      '전원을 끄고 하단 바스켓을 꺼낸 뒤 내부의 큰 음식물 찌꺼기를 제거해요.',
      '설명서에 따라 필터를 분리하고 흐르는 물과 부드러운 솔로 닦아요.',
      '필터 아래 배수구 주변에 이물질이 없는지 눈으로 확인해요.',
      '분사 날개 구멍의 막힘을 확인하고 분리 가능한 경우에만 부드럽게 닦아요.',
      '문 가장자리와 고무패킹을 젖은 천으로 닦고 물기를 제거해요.',
      '필터를 정확히 조립한 뒤 필요하면 제조사가 허용한 전용 코스로 빈 통 운전해요.',
    ],
    focusAreas: ['필터', '배수구 주변', '분사 노즐', '문 고무패킹'],
  ),
  const ProductCareTemplate(
    categoryName: '음식물처리기',
    type: ZoneItemType.appliance,
    summary: '처리 방식에 따라 내부 관리법이 크게 달라 투입구와 외부 점검을 우선해요.',
    frequency: '투입구는 주 1회 · 냄새, 누수, 이상 소음이 있으면 즉시 점검',
    recurrenceDays: 7,
    supplies: ['고무장갑', '작은 솔', '부드러운 천'],
    recommendedSupplies: ['투입구용 틈새 솔', '방수 장갑', '흡수용 극세사 천'],
    cautions: [
      '작동부 안에 손이나 도구를 깊이 넣지 마세요.',
      '본체, 배관과 교반실을 임의로 분해하지 마세요.',
      '락스나 강한 배수관 세정제는 제조사 확인 없이 사용하지 마세요.',
    ],
    steps: [
      '제품이 작동 중이 아닌지 확인하고 투입구 주변을 비워요.',
      '투입구 가장자리의 눈에 보이는 찌꺼기만 안전하게 제거해요.',
      '부드러운 천과 작은 솔로 외부 접합부를 닦아요.',
      '본체와 배관 주변의 누수, 변색과 이상 냄새를 확인해요.',
      '내부 세척과 미생물 보충은 정확한 처리 방식과 설명서를 확인한 뒤 진행해요.',
    ],
    focusAreas: ['투입구', '외부 접합부', '배관 누수', '처리 방식별 내부 관리'],
  ),
  const ProductCareTemplate(
    categoryName: '전자레인지',
    type: ZoneItemType.appliance,
    summary: '회전판과 내부 음식물 자국을 불린 뒤 전기 부품에 물이 닿지 않게 닦아요.',
    frequency: '오염은 발견 즉시 · 내부 전체는 주 1회',
    recurrenceDays: 7,
    supplies: ['전자레인지용 내열 용기', '부드러운 천', '중성세제'],
    recommendedSupplies: ['내열 유리용기', '기름때용 극세사 천'],
    cautions: [
      '금속 수세미와 연마제는 내부 코팅을 손상시킬 수 있어요.',
      '통풍구와 조작부에 물이나 세제를 직접 분사하지 마세요.',
      '가열한 물과 증기에 화상을 입지 않도록 주의하세요.',
    ],
    steps: [
      '내열 용기에 물을 담아 짧게 가열하고 문을 닫은 채 오염을 불려요.',
      '플러그를 분리하고 회전판과 받침을 꺼내 따로 닦아요.',
      '내부 벽면과 천장을 부드러운 천으로 닦아요.',
      '문 안쪽과 손잡이를 닦고 모든 물기를 제거해요.',
    ],
    focusAreas: ['회전판', '내부 벽면', '문 안쪽', '통풍구 주변'],
  ),
  const ProductCareTemplate(
    categoryName: '세탁기',
    type: ZoneItemType.appliance,
    summary: '세제함, 도어 패킹, 배수 필터와 세탁조를 서로 다른 주기로 관리해요.',
    frequency: '세제함과 패킹은 주 1회 · 배수 필터는 한 달마다 · 세탁조는 모델 권장 주기',
    recurrenceDays: 30,
    supplies: ['고무장갑', '부드러운 솔', '마른 천', '세탁조 전용 세정제'],
    recommendedSupplies: ['배수 필터 물받이', '패킹용 작은 솔', '제조사 허용 세탁조 클리너'],
    cautions: [
      '배수 필터를 열기 전에 잔수가 나올 수 있으므로 설명서를 확인하세요.',
      '염소계와 산성 세제를 섞지 마세요.',
      '세탁조 세정제는 드럼과 통돌이용을 구분하세요.',
    ],
    steps: [
      '세제함을 분리할 수 있으면 꺼내 잔여 세제를 씻어내요.',
      '도어 유리와 고무패킹 안쪽의 이물질과 물기를 닦아요.',
      '설명서에 따라 배수 필터를 열고 이물질을 제거해요.',
      '필터를 정확히 조립하고 누수가 없는지 확인해요.',
      '모델에 맞는 통세척 코스와 전용 세정제로 세탁조를 관리해요.',
      '사용 후 문과 세제함을 열어 내부를 건조해요.',
    ],
    focusAreas: ['세제함', '도어 패킹', '배수 필터', '세탁조'],
  ),
  const ProductCareTemplate(
    categoryName: '건조기',
    type: ZoneItemType.appliance,
    summary: '보풀 필터, 열교환기 또는 콘덴서와 습도 센서를 모델 구조에 맞게 관리해요.',
    frequency: '보풀 필터는 사용할 때마다 · 센서는 한 달마다 · 열교환기는 모델 권장 주기',
    recurrenceDays: 7,
    supplies: ['부드러운 솔', '마른 천', '청소기 좁은 노즐'],
    recommendedSupplies: ['보풀 필터용 브러시', '센서용 부드러운 천'],
    cautions: [
      '열교환기의 얇은 핀을 누르거나 구부리지 마세요.',
      '물세척 가능 여부를 확인하지 않고 필터를 씻지 마세요.',
      '내부가 뜨거울 때 바로 청소하지 마세요.',
    ],
    steps: [
      '제품이 충분히 식은 뒤 전원을 분리해요.',
      '보풀 필터를 꺼내 먼지를 제거하고 손상 여부를 확인해요.',
      '필터 장착부 주변의 보풀을 청소기나 부드러운 솔로 제거해요.',
      '습도 센서 위치를 설명서에서 확인해 부드러운 천으로 닦아요.',
      '열교환기 또는 콘덴서는 모델이 허용하는 방법으로만 관리해요.',
    ],
    focusAreas: ['보풀 필터', '필터 장착부', '습도 센서', '열교환기'],
  ),
  const ProductCareTemplate(
    categoryName: '공기청정기',
    type: ZoneItemType.appliance,
    summary: '흡입구, 프리필터와 센서를 관리하고 교체형 필터는 물세척하지 않아요.',
    frequency: '외부와 프리필터는 한 달마다 · 교체 필터는 앱 또는 설명서 주기',
    recurrenceDays: 30,
    supplies: ['청소기 브러시', '마른 천', '부드러운 솔'],
    recommendedSupplies: ['먼지 제거용 브러시', '센서용 면봉'],
    cautions: [
      '헤파 또는 탈취 필터의 물세척 가능 여부를 반드시 확인하세요.',
      '센서 구멍에 물이나 세제를 넣지 마세요.',
      '필터 방향과 앞뒤를 바꾸어 장착하지 마세요.',
    ],
    steps: [
      '전원을 분리하고 외부 흡입구의 먼지를 제거해요.',
      '프리필터를 분리해 먼지를 털거나 허용된 경우에만 물세척해요.',
      '센서 커버 주변을 마른 면봉이나 부드러운 솔로 닦아요.',
      '필터 교체 표시와 냄새를 확인하고 필요하면 교체해요.',
      '완전히 건조한 부품을 방향에 맞춰 다시 장착해요.',
    ],
    focusAreas: ['흡입구', '프리필터', '먼지 센서', '교체형 필터'],
  ),
  const ProductCareTemplate(
    categoryName: '에어컨',
    type: ZoneItemType.appliance,
    summary: '흡입 필터와 외부 패널은 사용자가 관리하고 내부 분해 세척은 전문가에게 맡겨요.',
    frequency: '흡입 필터는 2주마다 · 사용 전후 점검 · 냄새나 누수 시 전문가 문의',
    recurrenceDays: 14,
    supplies: ['청소기 브러시', '부드러운 천', '미지근한 물'],
    recommendedSupplies: ['필터용 부드러운 솔', '송풍구용 마른 천'],
    cautions: [
      '전원을 차단하고 필터 분리 방법을 설명서에서 확인하세요.',
      '열교환기 핀과 전기 부품에 물이나 세제를 직접 분사하지 마세요.',
      '곰팡이, 누수 또는 심한 냄새가 있으면 내부를 분해하지 말고 전문가에게 문의하세요.',
    ],
    steps: [
      '전원을 차단하고 외부 패널의 먼지를 마른 천으로 닦아요.',
      '설명서에 따라 흡입 필터를 분리해 먼지를 제거해요.',
      '물세척 가능한 필터만 미지근한 물로 씻고 그늘에서 완전히 말려요.',
      '송풍구의 손이 닿는 표면만 부드러운 천으로 닦아요.',
      '필터를 다시 장착하고 송풍 또는 건조 기능으로 내부 습기를 줄여요.',
    ],
    focusAreas: ['흡입 필터', '외부 패널', '송풍구', '누수와 냄새'],
  ),
  const ProductCareTemplate(
    categoryName: '소파',
    type: ZoneItemType.furniture,
    summary: '패브릭, 천연가죽과 인조가죽을 구분하고 틈새 먼지와 얼룩을 관리해요.',
    frequency: '틈새 먼지는 주 1회 · 표면 관리는 한 달마다',
    recurrenceDays: 14,
    supplies: ['청소기 틈새 노즐', '부드러운 천'],
    recommendedSupplies: ['재질에 맞는 전용 클리너', '흡수용 흰색 천'],
    cautions: [
      '관리 라벨과 소재를 확인하지 않고 물이나 세제를 사용하지 마세요.',
      '얼룩 제거제는 눈에 띄지 않는 곳에 먼저 시험하세요.',
      '가죽에 스팀과 과도한 물을 사용하지 마세요.',
    ],
    steps: [
      '쿠션을 분리하고 틈새 먼지를 청소기로 제거해요.',
      '표면 먼지를 마른 천이나 소재에 맞는 방법으로 정리해요.',
      '얼룩은 문지르지 말고 흰 천으로 눌러 흡수해요.',
      '소재 전용 제품을 시험한 뒤 필요한 부분에만 사용해요.',
      '충분히 건조하고 쿠션 위치를 바꾸어 마모를 고르게 해요.',
    ],
    focusAreas: ['쿠션 틈새', '표면 소재', '얼룩', '건조'],
  ),
  const ProductCareTemplate(
    categoryName: '매트리스',
    type: ZoneItemType.furniture,
    summary: '표면 먼지와 습기를 관리하고 물세척 대신 소재 라벨에 맞게 얼룩을 처리해요.',
    frequency: '침구 교체 때마다 먼지 제거 · 한 달마다 환기와 방향 전환',
    recurrenceDays: 30,
    supplies: ['청소기 패브릭 노즐', '마른 천'],
    recommendedSupplies: ['매트리스용 청소기 노즐', '방수 커버'],
    cautions: [
      '매트리스를 흠뻑 적시거나 스팀을 사용하기 전 제조사 지침을 확인하세요.',
      '곰팡이가 넓게 퍼졌거나 내부까지 젖었으면 전문 업체에 문의하세요.',
    ],
    steps: [
      '침구와 커버를 제거해 세탁 라벨에 맞게 세탁해요.',
      '매트리스 표면과 봉제선의 먼지를 천천히 흡입해요.',
      '얼룩은 물을 최소한으로 사용해 눌러 닦아요.',
      '창문을 열거나 제습해 완전히 건조해요.',
      '가능한 모델이면 방향을 바꾸어 사용해요.',
    ],
    focusAreas: ['표면 먼지', '봉제선', '얼룩', '습기와 환기'],
  ),
  const ProductCareTemplate(
    categoryName: '싱크대',
    type: ZoneItemType.fixture,
    summary: '싱크볼, 수전, 거름망과 배수구 입구를 나누어 음식물과 물때를 관리해요.',
    frequency: '싱크볼은 매일 · 거름망과 배수구 입구는 주 1회',
    recurrenceDays: 7,
    supplies: ['주방용 중성세제', '비연마 수세미', '배수구용 작은 솔'],
    recommendedSupplies: ['거름망용 작은 솔', '물자국 제거용 마른 천'],
    cautions: [
      '염소계와 산성 세제를 섞지 마세요.',
      '스테인리스 표면에 금속 수세미를 사용하지 마세요.',
      '강한 배수관 세정제는 배관 재질과 사용법을 확인하세요.',
    ],
    steps: [
      '거름망의 음식물 찌꺼기를 비워요.',
      '중성세제로 싱크볼과 수전을 결 방향에 맞춰 닦아요.',
      '거름망과 배수구 입구를 전용 솔로 닦아요.',
      '충분히 헹구고 마른 천으로 물기를 제거해요.',
    ],
    focusAreas: ['싱크볼', '수전', '거름망', '배수구 입구'],
  ),
];

String _normalize(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '');
}
