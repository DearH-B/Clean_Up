import '../models/product_consumable.dart';

List<ProductConsumable> defaultConsumablesFor(String productName) {
  final name = productName.replaceAll(' ', '');

  if (name.contains('공기청정기')) {
    return const [
      ProductConsumable(
        id: 'air-purifier-main-filter',
        name: '집진·탈취 필터',
        type: ConsumableType.filter,
        replacementDays: 365,
        compatibilityLabel: '모델별 전용 필터 확인 필요',
        note: '사용 환경과 제조사 알림에 따라 교체 시기가 달라질 수 있어요.',
      ),
    ];
  }
  if (name.contains('정수기')) {
    return const [
      ProductConsumable(
        id: 'water-purifier-filter',
        name: '정수 필터',
        type: ConsumableType.filter,
        replacementDays: 180,
        compatibilityLabel: '모델별 전용 필터 확인 필요',
      ),
    ];
  }
  if (name.contains('에어컨')) {
    return const [
      ProductConsumable(
        id: 'air-conditioner-special-filter',
        name: '기능성 필터',
        type: ConsumableType.filter,
        replacementDays: 365,
        compatibilityLabel: '교체형 필터가 있는 모델만 해당',
        note: '일반 먼지 필터는 교체보다 세척 대상인 경우가 많아요.',
      ),
    ];
  }
  if (name.contains('냉장고')) {
    return const [
      ProductConsumable(
        id: 'refrigerator-water-filter',
        name: '정수 필터',
        type: ConsumableType.filter,
        replacementDays: 180,
        compatibilityLabel: '정수·제빙 기능이 있는 모델만 해당',
      ),
      ProductConsumable(
        id: 'refrigerator-deodorizing-filter',
        name: '탈취 필터',
        type: ConsumableType.filter,
        replacementDays: 365,
        compatibilityLabel: '교체형 탈취 필터가 있는 모델만 해당',
      ),
    ];
  }
  if (name.contains('식기세척기')) {
    return const [
      ProductConsumable(
        id: 'dishwasher-rinse-aid',
        name: '린스 보충제',
        type: ConsumableType.refill,
        replacementDays: 60,
        compatibilityLabel: '린스 투입구가 있는 모델에 사용',
      ),
      ProductConsumable(
        id: 'dishwasher-cleaner',
        name: '식기세척기 전용 클리너',
        type: ConsumableType.cleaner,
        replacementDays: 30,
        compatibilityLabel: '제조사가 허용한 전용 제품 확인',
      ),
    ];
  }
  if (name.contains('세탁기')) {
    return const [
      ProductConsumable(
        id: 'washing-machine-cleaner',
        name: '세탁조 클리너',
        type: ConsumableType.cleaner,
        replacementDays: 30,
        compatibilityLabel: '제조사가 허용한 세탁조 클리너 확인',
      ),
    ];
  }
  if (name.contains('건조기')) {
    return const [
      ProductConsumable(
        id: 'dryer-scent-sheet',
        name: '건조기 시트',
        type: ConsumableType.refill,
        replacementDays: 30,
        compatibilityLabel: '선택 사용품 · 제조사 사용 가능 여부 확인',
      ),
    ];
  }
  return const [];
}
