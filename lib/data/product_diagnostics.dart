import '../models/product_diagnostic.dart';

List<ProductDiagnostic> diagnosticsForProduct(String productName) {
  final name = productName.replaceAll(' ', '');
  if (name.contains('세면대')) {
    return const [
      ProductDiagnostic(
        id: 'washbasin-scale',
        symptom: '하얀 물때·비누때가 보여요',
        question: '표면이 일반 도기이고 금속 수전의 도금이 벗겨지거나 갈라진 곳은 없나요?',
        safeAction: '중성 욕실 세정제와 부드러운 도구로 짧게 닦은 뒤 물로 충분히 헹구고 마른 천으로 물기를 제거하세요.',
        outcome: DiagnosticOutcome.selfCare,
        steps: [
          '세면대 위 물건과 머리카락을 먼저 치워요.',
          '세정제를 눈에 띄지 않는 곳에 소량 시험해요.',
          '부드러운 스펀지나 솔로 물때 부위를 가볍게 문질러요.',
          '깨끗한 물로 충분히 헹군 뒤 마른 극세사 천으로 닦아요.',
        ],
        tools: ['고무장갑', '부드러운 욕실용 스펀지', '틈새 솔', '극세사 천'],
        recommendedProducts: [
          DiagnosticProductRecommendation(
            brand: '홈스타',
            name: '욕실용 세정제',
            reason: '세면대의 일반적인 비누때와 물때를 닦는 욕실용 세정제예요.',
            url:
                'https://www.coupang.com/np/search?q=%ED%99%88%EC%8A%A4%ED%83%80+%EC%9A%95%EC%8B%A4%EC%9A%A9+%EC%84%B8%EC%A0%95%EC%A0%9C',
          ),
          DiagnosticProductRecommendation(
            brand: '3M 스카치브라이트',
            name: '욕실 청소용 브러쉬',
            reason: '수전 주변과 배수구 테두리의 좁은 부분을 닦기 편해요.',
            url:
                'https://www.coupang.com/np/search?q=3M+%EC%8A%A4%EC%B9%B4%EC%B9%98%EB%B8%8C%EB%9D%BC%EC%9D%B4%ED%8A%B8+%EC%9A%95%EC%8B%A4+%EB%B8%8C%EB%9F%AC%EC%89%AC',
          ),
        ],
        caution:
            '천연 대리석·인조석·특수 코팅 제품에는 산성 세정제나 거친 수세미를 사용하지 마세요. 락스와 산성 세정제를 섞으면 안 됩니다.',
      ),
      ProductDiagnostic(
        id: 'washbasin-hair-clog',
        symptom: '머리카락 때문에 물이 천천히 내려가요',
        question: '물이 역류하지 않고 세면대 한 곳에서만 천천히 내려가나요?',
        safeAction:
            '배수 마개와 입구에서 보이는 머리카락을 먼저 물리적으로 제거하세요. 배관 분해나 여러 약품의 혼합은 피하세요.',
        outcome: DiagnosticOutcome.selfCare,
        steps: [
          '고무장갑을 끼고 세면대의 고인 물을 가능한 만큼 덜어내요.',
          '분리 가능한 배수 마개를 들어 올려 붙은 머리카락을 제거해요.',
          '플라스틱 배수구 클리너를 얕게 넣고 천천히 당겨 이물질을 꺼내요.',
          '물을 조금씩 흘려 배수 속도를 확인하고 도구를 세척해요.',
        ],
        tools: ['고무장갑', '집게', '플라스틱 배수구 클리너', '쓰레기봉투'],
        recommendedProducts: [
          DiagnosticProductRecommendation(
            brand: '코멧',
            name: '배수구 청소용 클리너',
            reason: '약품 없이 입구 가까이에 걸린 머리카락을 먼저 제거할 때 사용해요.',
            url:
                'https://www.coupang.com/np/search?q=%EC%BD%94%EB%A9%A7+%EB%B0%B0%EC%88%98%EA%B5%AC+%ED%81%B4%EB%A6%AC%EB%84%88',
          ),
          DiagnosticProductRecommendation(
            brand: '3M',
            name: '니트릴 위생장갑',
            reason: '머리카락과 배수구 오염물을 직접 만지지 않도록 보호해요.',
            url:
                'https://www.coupang.com/np/search?q=3M+%EB%8B%88%ED%8A%B8%EB%A6%B4+%EC%9E%A5%EA%B0%91',
          ),
        ],
        warningSigns: ['여러 배수구가 동시에 막힘', '오수가 역류함', '배관 연결부에서 물이 샘'],
        caution:
            '끓는 물을 붓거나 락스·산성 세정제·배수관 세정제를 서로 섞지 마세요. 깊은 막힘이나 반복되는 역류는 배관 전문가에게 맡기세요.',
      ),
      ProductDiagnostic(
        id: 'washbasin-odor',
        symptom: '배수구에서 냄새가 나요',
        question: '눈에 보이는 머리카락과 배수 마개 오염을 제거한 뒤에도 냄새가 계속되나요?',
        safeAction:
            '배수 마개와 입구를 세척하고 물을 충분히 흘려보세요. 냄새가 반복되면 트랩이나 배관 상태를 점검받으세요.',
        outcome: DiagnosticOutcome.professionalSupport,
        steps: [
          '배수 마개에 붙은 비누 찌꺼기와 머리카락을 제거해요.',
          '중성 세정제와 작은 솔로 배수구 입구만 닦아요.',
          '물을 흘려보낸 뒤 환기하고 냄새가 다시 생기는지 확인해요.',
        ],
        tools: ['고무장갑', '작은 틈새 솔', '중성 세정제'],
        caution: '배관 내부에 세정제를 반복해서 붓기보다 악취 차단 트랩과 누수 여부를 점검하세요.',
      ),
      ProductDiagnostic(
        id: 'washbasin-leak',
        symptom: '금이 갔거나 아래로 물이 새요',
        question: '물을 사용하지 않아도 균열이나 배관 연결부에서 물기가 계속 생기나요?',
        safeAction:
            '세면대 사용을 중단하고 아래 수납물을 치운 뒤 급수 밸브를 잠그세요. 도기 균열과 배관 누수는 전문가에게 맡기세요.',
        outcome: DiagnosticOutcome.stopUsing,
        warningSigns: ['도기 균열이 커짐', '세면대가 흔들림', '전기 콘센트 주변 누수'],
      ),
    ];
  }
  if (name.contains('식기세척기')) {
    return const [
      ProductDiagnostic(
        id: 'dishwasher-leak',
        symptom: '물이 새요',
        question: '바닥이나 전원 연결부 주변에 물이 보이나요?',
        safeAction:
            '전원과 급수를 차단하고 제품을 사용하지 마세요. 본체와 배관을 분해하지 말고 설치업체나 서비스센터에 문의하세요.',
        outcome: DiagnosticOutcome.stopUsing,
        warningSigns: ['전원부 주변 물기', '계속되는 누수', '타는 냄새'],
      ),
      ProductDiagnostic(
        id: 'dishwasher-drain',
        symptom: '물이 빠지지 않아요',
        question: '필터를 사용설명서에 나온 방식으로 다시 조립해도 물이 남아 있나요?',
        safeAction:
            '사용자가 분리할 수 있는 필터의 조립 상태만 확인하세요. 배수 호스나 펌프 분해는 서비스센터에 맡기세요.',
        outcome: DiagnosticOutcome.professionalSupport,
      ),
      ProductDiagnostic(
        id: 'dishwasher-cleaning',
        symptom: '세척이 잘 안 돼요',
        question: '필터, 분사 노즐 구멍과 전용 세제 사용량을 확인했나요?',
        safeAction: '전원을 끈 뒤 분리 가능한 필터의 이물질과 노즐 구멍 막힘을 확인하고 설명서의 적재 방법을 따라주세요.',
        outcome: DiagnosticOutcome.selfCare,
        steps: [
          '전원을 끄고 하단 바구니를 비워요.',
          '설명서에서 허용한 필터만 분리해 음식물 찌꺼기를 제거해요.',
          '분사 날개 구멍을 부드러운 솔로 확인하고 원래대로 조립해요.',
        ],
        tools: ['고무장갑', '부드러운 필터 솔', '극세사 천'],
        recommendedProducts: [
          DiagnosticProductRecommendation(
            brand: '피니시',
            name: '식기세척기 전용 클리너',
            reason: '제조사 설명서에서 세척 코스 사용이 허용된 경우 내부 관리에 사용해요.',
            url:
                'https://www.coupang.com/np/search?q=%ED%94%BC%EB%8B%88%EC%8B%9C+%EC%8B%9D%EA%B8%B0%EC%84%B8%EC%B2%99%EA%B8%B0+%ED%81%B4%EB%A6%AC%EB%84%88',
          ),
        ],
        caution: '일반 주방세제는 거품과 누수 원인이 될 수 있으므로 식기세척기에 넣지 마세요.',
      ),
      ProductDiagnostic(
        id: 'dishwasher-odor',
        symptom: '냄새가 나요',
        question: '필터나 문 패킹에 음식물 찌꺼기와 물기가 남아 있나요?',
        safeAction:
            '필터와 배수구 주변의 찌꺼기를 제거하고 문 패킹의 물기를 닦으세요. 임의의 배수관 세정제는 사용하지 마세요.',
        outcome: DiagnosticOutcome.selfCare,
      ),
    ];
  }
  if (name.contains('냉장고')) {
    return const [
      ProductDiagnostic(
        id: 'refrigerator-power',
        symptom: '냉각이 안 돼요',
        question: '전원, 온도 설정과 문 닫힘을 확인해도 내부 온도가 계속 높나요?',
        safeAction:
            '상하기 쉬운 식품을 안전한 곳으로 옮기고 내부 부품이나 뒷면 기계실을 분해하지 마세요. 서비스센터에 문의하세요.',
        outcome: DiagnosticOutcome.professionalSupport,
        warningSigns: ['타는 냄새', '차단기 반복 작동', '비정상적으로 뜨거운 전원 플러그'],
      ),
      ProductDiagnostic(
        id: 'refrigerator-water',
        symptom: '바닥에 물이 보여요',
        question: '외부에서 흘린 물이 아닌데도 제품 아래로 물이 계속 나오나요?',
        safeAction:
            '젖은 전원부를 만지지 말고 필요하면 차단기를 내려 사용을 중단하세요. 급수형 제품은 급수 밸브를 잠그고 전문가에게 문의하세요.',
        outcome: DiagnosticOutcome.stopUsing,
      ),
      ProductDiagnostic(
        id: 'refrigerator-door',
        symptom: '문이 잘 닫히지 않아요',
        question: '수납물이나 고무패킹의 이물질이 문을 막고 있나요?',
        safeAction:
            '문을 막는 식품을 정리하고 고무패킹을 부드러운 천으로 닦으세요. 패킹이 찢어졌다면 부품 교체를 문의하세요.',
        outcome: DiagnosticOutcome.selfCare,
      ),
      ProductDiagnostic(
        id: 'refrigerator-odor',
        symptom: '냄새가 나요',
        question: '상한 식품이나 선반·서랍에 흘린 음식물이 있나요?',
        safeAction:
            '식품을 확인하고 분리 가능한 선반과 서랍을 설명서 방식으로 세척하세요. 탈취 필터가 있는 모델은 교체 조건을 확인하세요.',
        outcome: DiagnosticOutcome.replaceConsumable,
        steps: [
          '상한 식품과 흘린 내용물을 먼저 제거해요.',
          '분리 가능한 선반과 서랍을 중성 세제로 닦아 완전히 말려요.',
          '고무패킹의 음식물과 물기를 부드러운 천으로 닦아요.',
        ],
        tools: ['부드러운 스펀지', '극세사 천', '작은 틈새 솔'],
        recommendedProducts: [
          DiagnosticProductRecommendation(
            brand: '3M 스카치브라이트',
            name: '제로스크래치 수세미',
            reason: '분리 가능한 선반과 서랍의 오염을 부드럽게 닦을 때 사용해요.',
            url:
                'https://www.coupang.com/np/search?q=3M+%EC%A0%9C%EB%A1%9C%EC%8A%A4%ED%81%AC%EB%9E%98%EC%B9%98+%EC%88%98%EC%84%B8%EB%AF%B8',
          ),
        ],
      ),
    ];
  }
  if (name.contains('세탁기')) {
    return const [
      ProductDiagnostic(
        id: 'washer-leak',
        symptom: '물이 새요',
        question: '급수·배수 호스나 제품 아래에서 물이 계속 나오나요?',
        safeAction:
            '전원 플러그를 젖은 손으로 만지지 말고 급수 밸브를 잠그세요. 사용을 중단하고 설치 상태를 점검받으세요.',
        outcome: DiagnosticOutcome.stopUsing,
      ),
      ProductDiagnostic(
        id: 'washer-drain',
        symptom: '배수가 안 돼요',
        question: '설명서에 따라 배수 필터와 배수 호스 꺾임을 확인했나요?',
        safeAction: '설명서에서 허용한 배수 필터만 확인하세요. 펌프나 본체 분해가 필요하면 서비스센터에 문의하세요.',
        outcome: DiagnosticOutcome.checkManual,
      ),
      ProductDiagnostic(
        id: 'washer-noise',
        symptom: '심하게 흔들리거나 소음이 나요',
        question: '세탁물이 한쪽에 몰렸거나 제품이 수평이 아닌 상태인가요?',
        safeAction: '작동을 멈추고 세탁물을 고르게 펴세요. 빈 통에서도 충격음이 지속되면 사용을 중단하고 점검받으세요.',
        outcome: DiagnosticOutcome.professionalSupport,
      ),
      ProductDiagnostic(
        id: 'washer-odor',
        symptom: '통에서 냄새가 나요',
        question: '세제함, 고무패킹과 배수 필터를 최근에 확인했나요?',
        safeAction: '설명서의 통세척 코스를 사용하고 세제함과 고무패킹의 잔여물을 제거하세요. 세정제를 혼합하지 마세요.',
        outcome: DiagnosticOutcome.selfCare,
        steps: [
          '세제함과 고무패킹의 잔여물을 제거해요.',
          '배수 필터를 설명서에 따라 확인해요.',
          '제조사가 허용한 통세척 코스와 전용 세정제를 사용해요.',
          '완료 후 문과 세제함을 열어 충분히 건조해요.',
        ],
        tools: ['고무장갑', '고무패킹용 틈새 솔', '극세사 천'],
        recommendedProducts: [
          DiagnosticProductRecommendation(
            brand: '홈스타',
            name: '세탁조 클리너',
            reason: '제조사가 세탁조 세정제 사용을 허용한 경우 통세척 코스에 사용해요.',
            url:
                'https://www.coupang.com/np/search?q=%ED%99%88%EC%8A%A4%ED%83%80+%EC%84%B8%ED%83%81%EC%A1%B0+%ED%81%B4%EB%A6%AC%EB%84%88',
          ),
        ],
        caution: '세탁조 세정제와 표백제·산성 세정제를 섞지 마세요.',
      ),
    ];
  }
  if (name.contains('음식물처리기')) {
    return const [
      ProductDiagnostic(
        id: 'food-processor-noise',
        symptom: '평소와 다른 소음이 나요',
        question: '금속, 유리, 뼈처럼 투입이 금지된 물질이 들어갔을 가능성이 있나요?',
        safeAction: '즉시 작동을 멈추고 전원을 분리하세요. 손이나 도구를 내부에 넣지 말고 제조사에 문의하세요.',
        outcome: DiagnosticOutcome.stopUsing,
      ),
      ProductDiagnostic(
        id: 'food-processor-leak',
        symptom: '누수 흔적이 있어요',
        question: '본체 또는 연결 배관 주변에 물기가 반복해서 생기나요?',
        safeAction: '전원과 급수를 차단하고 본체나 배관을 분해하지 마세요. 설치업체 또는 제조사에 문의하세요.',
        outcome: DiagnosticOutcome.stopUsing,
      ),
      ProductDiagnostic(
        id: 'food-processor-odor',
        symptom: '냄새가 심해졌어요',
        question: '처리통, 투입구 또는 필터의 공식 관리 주기를 확인했나요?',
        safeAction:
            '제품 처리 방식에 맞는 공식 세척법과 필터·미생물 관리 조건을 확인하세요. 락스나 강한 약품을 임의로 사용하지 마세요.',
        outcome: DiagnosticOutcome.checkManual,
        steps: [
          '작동을 멈추고 제품 방식과 공식 세척 영상을 확인해요.',
          '투입구 주변의 눈에 보이는 찌꺼기만 작은 솔로 제거해요.',
          '부드러운 천으로 외부 물기를 닦고 이상 냄새가 지속되는지 확인해요.',
        ],
        tools: ['고무장갑', '작은 틈새 솔', '극세사 천'],
        recommendedProducts: [
          DiagnosticProductRecommendation(
            brand: '3M',
            name: '니트릴 위생장갑',
            reason: '투입구 주변의 오염물을 직접 만지지 않도록 보호해요.',
            url:
                'https://www.coupang.com/np/search?q=3M+%EB%8B%88%ED%8A%B8%EB%A6%B4+%EC%9E%A5%EA%B0%91',
          ),
        ],
        caution: '락스·배수관 세정제·뜨거운 물을 임의로 넣지 말고 내부에 손이나 도구를 넣지 마세요.',
      ),
    ];
  }
  if (_containsAny(name, const ['변기', '샤워부스', '욕조', '싱크대'])) {
    return _wetFixtureDiagnostics(productName);
  }
  if (_containsAny(
    name,
    const ['전자레인지', '오븐', '인덕션', '가스레인지', '전기밥솥', '토스터', '믹서기', '커피머신'],
  )) {
    return _kitchenApplianceDiagnostics(productName);
  }
  if (_containsAny(
    name,
    const ['공기청정기', '가습기', '제습기', '에어컨', '선풍기', '환풍기', '실외기'],
  )) {
    return _airCareDiagnostics(productName);
  }
  if (_containsAny(name, const ['건조기', '세탁조', '빨래건조대'])) {
    return _laundryDiagnostics(productName);
  }
  if (_containsAny(name, const ['청소기', '로봇청소기'])) {
    return _cleanerDiagnostics(productName);
  }
  if (_containsAny(
    name,
    const ['소파', '매트리스', '침대', '러그', '현관매트', '커튼', '전기장판'],
  )) {
    return _fabricDiagnostics(productName);
  }
  if (_containsAny(
    name,
    const ['TV', '모니터', '컴퓨터', '스피커', '프로젝터', '게임기', '공유기', '프린터'],
  )) {
    return _electronicsDiagnostics(productName);
  }
  if (_containsAny(
    name,
    const ['창문', '방충망', '현관문', '중문', '블라인드', '거울'],
  )) {
    return _openingDiagnostics(productName);
  }
  if (_containsAny(
    name,
    const [
      '테이블',
      '식탁',
      '협탁',
      '책상',
      '의자',
      '옷장',
      '화장대',
      '책장',
      '신발장',
      '수납장',
      '욕실장',
      '서랍장',
      '안마의자',
    ],
  )) {
    return _furnitureDiagnostics(productName);
  }
  if (name.contains('정수기')) {
    return _waterApplianceDiagnostics(productName);
  }
  return const [
    ProductDiagnostic(
      id: 'generic-electric',
      symptom: '전기 냄새, 연기 또는 불꽃이 보여요',
      question: '타는 냄새나 연기, 반복되는 차단기 작동이 있나요?',
      safeAction: '제품을 만지지 말고 안전하게 전원을 차단하세요. 다시 작동하지 말고 제조사나 전문가에게 문의하세요.',
      outcome: DiagnosticOutcome.stopUsing,
    ),
    ProductDiagnostic(
      id: 'generic-leak',
      symptom: '누수 또는 작동 이상이 있어요',
      question: '사용을 멈춘 뒤에도 누수나 이상 상태가 계속되나요?',
      safeAction: '전원과 급수를 안전하게 차단하고 제품을 분해하지 마세요. 공식 고객지원에 문의하세요.',
      outcome: DiagnosticOutcome.professionalSupport,
    ),
    ProductDiagnostic(
      id: 'generic-care',
      symptom: '오염이나 냄새가 생겼어요',
      question: '사용자가 분리할 수 있는 부품의 공식 관리법을 확인했나요?',
      safeAction: '공식 설명서에서 분리 가능한 부품과 사용 가능한 세정제를 먼저 확인하세요.',
      outcome: DiagnosticOutcome.checkManual,
    ),
  ];
}

List<ProductDiagnostic> _wetFixtureDiagnostics(String productName) => [
      ProductDiagnostic(
        id: 'wet-fixture-scale',
        symptom: '물때·비누때가 생겼어요',
        question: '$productName 표면의 재질과 코팅 상태를 확인했나요?',
        safeAction: '중성 욕실 세정제를 눈에 띄지 않는 곳에 시험한 뒤 부드러운 도구로 닦고 충분히 헹구세요.',
        outcome: DiagnosticOutcome.selfCare,
        steps: [
          '머리카락과 큰 이물질을 먼저 치워요.',
          '중성 세정제를 작은 부위에 시험해요.',
          '부드러운 스펀지로 닦고 깨끗한 물로 헹궈요.',
          '마른 천으로 물기를 제거해 다시 생기는 물때를 줄여요.',
        ],
        tools: const ['고무장갑', '부드러운 스펀지', '틈새 솔', '극세사 천'],
        recommendedProducts: const [
          DiagnosticProductRecommendation(
            brand: '홈스타',
            name: '욕실용 세정제',
            reason: '욕실 시설의 일반적인 비누때와 물때 관리에 사용하는 제품이에요.',
            url:
                'https://www.coupang.com/np/search?q=%ED%99%88%EC%8A%A4%ED%83%80+%EC%9A%95%EC%8B%A4%EC%9A%A9+%EC%84%B8%EC%A0%95%EC%A0%9C',
          ),
        ],
        caution: '락스와 산성 세정제를 섞지 말고, 천연석이나 특수 코팅에는 산성 제품을 사용하지 마세요.',
      ),
      const ProductDiagnostic(
        id: 'wet-fixture-clog',
        symptom: '물이 잘 내려가지 않아요',
        question: '입구에 보이는 머리카락과 이물질을 제거해도 배수가 느린가요?',
        safeAction: '보이는 이물질을 물리적으로 먼저 제거하고 깊은 막힘이나 역류는 전문가에게 맡기세요.',
        outcome: DiagnosticOutcome.professionalSupport,
        steps: [
          '고인 물을 덜어내고 고무장갑을 껴요.',
          '거름망과 배수구 입구의 이물질을 집게로 제거해요.',
          '물을 조금씩 흘려 배수 상태를 확인해요.',
        ],
        tools: ['고무장갑', '집게', '플라스틱 배수구 클리너'],
        recommendedProducts: [
          DiagnosticProductRecommendation(
            brand: '코멧',
            name: '배수구 청소용 클리너',
            reason: '약품을 붓기 전에 입구 가까운 머리카락을 제거할 때 사용해요.',
            url:
                'https://www.coupang.com/np/search?q=%EC%BD%94%EB%A9%A7+%EB%B0%B0%EC%88%98%EA%B5%AC+%ED%81%B4%EB%A6%AC%EB%84%88',
          ),
        ],
        warningSigns: ['오수 역류', '여러 배수구 동시 막힘', '배관 연결부 누수'],
        caution: '끓는 물을 붓거나 서로 다른 배수관 약품을 혼합하지 마세요.',
      ),
      const ProductDiagnostic(
        id: 'wet-fixture-mold',
        symptom: '곰팡이·검은 얼룩이 보여요',
        question: '실리콘 안쪽까지 번졌거나 반복해서 다시 생기나요?',
        safeAction: '환기하고 표면 오염만 제품 표시사항에 따라 닦으세요. 실리콘 내부 곰팡이는 교체가 필요할 수 있어요.',
        outcome: DiagnosticOutcome.professionalSupport,
        tools: ['고무장갑', '보안경', '환기용 선풍기'],
        caution: '염소계 곰팡이 제거제를 다른 세정제와 함께 사용하지 마세요.',
      ),
    ];

List<ProductDiagnostic> _kitchenApplianceDiagnostics(String productName) => [
      ProductDiagnostic(
        id: 'kitchen-grease',
        symptom: '기름때·음식물이 눌어붙었어요',
        question: '$productName의 전원이 꺼지고 표면이 완전히 식었나요?',
        safeAction: '전원을 분리하고 분리 가능한 부품만 중성 주방 세제와 부드러운 도구로 닦으세요.',
        outcome: DiagnosticOutcome.selfCare,
        steps: [
          '전원을 끄고 열이 완전히 식을 때까지 기다려요.',
          '마른 키친타월로 큰 음식물과 기름을 걷어내요.',
          '중성 세제를 묻힌 부드러운 천으로 닦아요.',
          '세제와 물기가 남지 않도록 마른 천으로 마무리해요.',
        ],
        tools: const ['고무장갑', '부드러운 스펀지', '극세사 천', '키친타월'],
        recommendedProducts: const [
          DiagnosticProductRecommendation(
            brand: '퐁퐁',
            name: '주방세제',
            reason: '분리 가능한 조리 부품의 일반적인 기름때를 닦을 때 사용해요.',
            url:
                'https://www.coupang.com/np/search?q=%ED%90%81%ED%90%81+%EC%A3%BC%EB%B0%A9%EC%84%B8%EC%A0%9C',
          ),
          DiagnosticProductRecommendation(
            brand: '3M 스카치브라이트',
            name: '제로스크래치 수세미',
            reason: '표면 흠집 위험을 줄이며 눌어붙은 오염을 닦는 데 도움을 줘요.',
            url:
                'https://www.coupang.com/np/search?q=3M+%EC%A0%9C%EB%A1%9C%EC%8A%A4%ED%81%AC%EB%9E%98%EC%B9%98+%EC%88%98%EC%84%B8%EB%AF%B8',
          ),
        ],
        caution: '조작부·통풍구·전기 연결부에 세정제를 직접 분사하지 마세요.',
      ),
      const ProductDiagnostic(
        id: 'kitchen-odor',
        symptom: '냄새가 남아요',
        question: '음식물 찌꺼기와 분리 가능한 받침·용기를 제거했나요?',
        safeAction: '찌꺼기와 물기를 제거하고 문이나 뚜껑을 열어 충분히 건조하세요.',
        outcome: DiagnosticOutcome.selfCare,
        tools: ['부드러운 솔', '극세사 천'],
      ),
      const ProductDiagnostic(
        id: 'kitchen-power',
        symptom: '가열이 안 되거나 타는 냄새가 나요',
        question: '연기·불꽃·반복되는 차단기 작동이 있나요?',
        safeAction: '즉시 전원을 차단하고 다시 사용하지 마세요. 가스 제품은 밸브를 잠그고 환기한 뒤 점검받으세요.',
        outcome: DiagnosticOutcome.stopUsing,
        warningSigns: ['연기 또는 불꽃', '가스 냄새', '전원 플러그 과열'],
      ),
    ];

List<ProductDiagnostic> _airCareDiagnostics(String productName) => [
      ProductDiagnostic(
        id: 'air-dust',
        symptom: '먼지가 많거나 바람이 약해졌어요',
        question: '$productName의 흡입구와 사용자가 청소할 수 있는 필터를 확인했나요?',
        safeAction: '전원을 끄고 흡입구 먼지를 제거한 뒤 설명서에서 허용한 필터만 청소하거나 교체하세요.',
        outcome: DiagnosticOutcome.replaceConsumable,
        steps: [
          '전원을 끄고 플러그를 분리해요.',
          '흡입구와 외부 먼지를 청소기로 제거해요.',
          '필터의 물세척 가능 여부를 설명서에서 확인해요.',
          '완전히 건조하거나 새 필터로 교체한 뒤 조립해요.',
        ],
        tools: const ['청소기 브러시 노즐', '부드러운 솔', '마른 극세사 천'],
        recommendedProducts: const [
          DiagnosticProductRecommendation(
            brand: '3M',
            name: '정전기 청소포',
            reason: '흡입구와 외부에 쌓인 마른 먼지를 닦기 편해요.',
            url:
                'https://www.coupang.com/np/search?q=3M+%EC%A0%95%EC%A0%84%EA%B8%B0+%EC%B2%AD%EC%86%8C%ED%8F%AC',
          ),
        ],
        caution: 'HEPA·탈취 필터는 물세척이 금지된 경우가 많으니 설명서를 먼저 확인하세요.',
      ),
      const ProductDiagnostic(
        id: 'air-odor',
        symptom: '퀴퀴한 냄새가 나요',
        question: '필터나 물통에 습기·오염이 남아 있나요?',
        safeAction: '물통과 세척 가능한 부품을 비우고 완전히 건조하세요. 내부 곰팡이나 전기부 냄새는 점검받으세요.',
        outcome: DiagnosticOutcome.checkManual,
        tools: ['부드러운 병솔', '마른 천'],
      ),
      const ProductDiagnostic(
        id: 'air-leak-noise',
        symptom: '물이 새거나 이상 소음이 나요',
        question: '평평한 곳에 두고 물통·필터를 다시 조립해도 문제가 계속되나요?',
        safeAction: '전원을 분리하고 물기를 닦은 뒤 사용을 중단하세요. 모터나 냉매 계통은 분해하지 마세요.',
        outcome: DiagnosticOutcome.professionalSupport,
        warningSigns: ['전원부 주변 물기', '타는 냄새', '금속 마찰음'],
      ),
    ];

List<ProductDiagnostic> _laundryDiagnostics(String productName) => [
      ProductDiagnostic(
        id: 'laundry-lint',
        symptom: '먼지·보풀·세제 찌꺼기가 많아요',
        question: '$productName의 필터나 물받이를 최근에 비웠나요?',
        safeAction: '전원을 끄고 사용자가 분리할 수 있는 필터와 물받이만 비우고 완전히 건조하세요.',
        outcome: DiagnosticOutcome.selfCare,
        steps: [
          '전원을 끄고 남은 열과 물기를 확인해요.',
          '필터·물받이·고무패킹의 이물질을 제거해요.',
          '부드러운 솔로 마른 먼지를 털고 완전히 건조해요.',
        ],
        tools: const ['필터 청소솔', '극세사 천', '고무장갑'],
        recommendedProducts: const [
          DiagnosticProductRecommendation(
            brand: '3M 스카치브라이트',
            name: '틈새 청소 브러쉬',
            reason: '필터와 고무패킹 주변의 보풀을 제거하기 편해요.',
            url:
                'https://www.coupang.com/np/search?q=3M+%ED%8B%88%EC%83%88+%EC%B2%AD%EC%86%8C+%EB%B8%8C%EB%9F%AC%EC%89%AC',
          ),
        ],
      ),
      const ProductDiagnostic(
        id: 'laundry-odor',
        symptom: '눅눅하거나 곰팡이 냄새가 나요',
        question: '사용 후 문과 필터를 열어 건조하고 있나요?',
        safeAction: '제품 설명서의 통세척·필터 관리 방법을 따르고 세정제를 혼합하지 마세요.',
        outcome: DiagnosticOutcome.checkManual,
        caution: '염소계 표백제와 산성·산소계 세정제를 함께 사용하지 마세요.',
      ),
      const ProductDiagnostic(
        id: 'laundry-heat',
        symptom: '과열되거나 작동이 멈춰요',
        question: '필터를 비워도 타는 냄새나 과열이 계속되나요?',
        safeAction: '즉시 전원을 끄고 다시 작동하지 말고 서비스센터에 문의하세요.',
        outcome: DiagnosticOutcome.stopUsing,
        warningSigns: ['타는 냄새', '전원 플러그 과열', '연기'],
      ),
    ];

List<ProductDiagnostic> _cleanerDiagnostics(String productName) => [
      const ProductDiagnostic(
        id: 'cleaner-suction',
        symptom: '흡입력이 약해졌어요',
        question: '먼지통·필터·브러시의 막힘을 확인했나요?',
        safeAction: '전원을 끄고 먼지통을 비운 뒤 브러시의 머리카락과 설명서에서 허용한 필터를 관리하세요.',
        outcome: DiagnosticOutcome.selfCare,
        steps: [
          '먼지통을 비우고 큰 이물질을 제거해요.',
          '브러시에 감긴 머리카락을 안전가위로 끊어 빼요.',
          '필터의 세척·교체 조건을 확인해요.',
        ],
        tools: ['청소용 안전가위', '브러시 청소솔', '고무장갑'],
        recommendedProducts: [
          DiagnosticProductRecommendation(
            brand: '코멧',
            name: '청소기 브러시 청소도구',
            reason: '롤러에 감긴 머리카락과 실을 제거할 때 사용해요.',
            url:
                'https://www.coupang.com/np/search?q=%EC%B2%AD%EC%86%8C%EA%B8%B0+%EB%B8%8C%EB%9F%AC%EC%8B%9C+%EC%B2%AD%EC%86%8C%EB%8F%84%EA%B5%AC',
          ),
        ],
      ),
      const ProductDiagnostic(
        id: 'cleaner-odor',
        symptom: '배기 냄새가 나요',
        question: '먼지통과 필터를 관리해도 냄새가 계속되나요?',
        safeAction: '완전히 건조된 필터를 사용하고 냄새가 지속되면 필터를 교체하세요.',
        outcome: DiagnosticOutcome.replaceConsumable,
      ),
      const ProductDiagnostic(
        id: 'cleaner-battery',
        symptom: '충전이 안 되거나 배터리가 뜨거워요',
        question: '정품 충전기를 사용해도 과열이나 부풀음이 있나요?',
        safeAction: '충전을 중단하고 가연물에서 떨어진 곳에 두세요. 배터리를 분해하지 말고 점검받으세요.',
        outcome: DiagnosticOutcome.stopUsing,
        warningSigns: ['배터리 부풀음', '화학 냄새', '비정상 과열'],
      ),
    ];

List<ProductDiagnostic> _fabricDiagnostics(String productName) => [
      ProductDiagnostic(
        id: 'fabric-stain',
        symptom: '얼룩이나 음식물을 흘렸어요',
        question: '$productName의 세탁 라벨과 소재를 확인했나요?',
        safeAction: '마른 천으로 눌러 오염을 흡수하고 세탁 라벨에서 허용한 세정 방법만 사용하세요.',
        outcome: DiagnosticOutcome.selfCare,
        steps: [
          '문지르지 말고 마른 흰 천으로 오염을 눌러 흡수해요.',
          '숨은 부분에 세정제를 소량 시험해요.',
          '바깥쪽에서 안쪽 방향으로 가볍게 닦아요.',
          '통풍이 잘되는 곳에서 완전히 건조해요.',
        ],
        tools: const ['흰색 극세사 천', '부드러운 솔', '흡수용 타월'],
        recommendedProducts: const [
          DiagnosticProductRecommendation(
            brand: '아스토니쉬',
            name: '패브릭 얼룩 제거제',
            reason: '세탁 라벨에서 습식 관리가 허용된 패브릭의 부분 얼룩에 사용해요.',
            url:
                'https://www.coupang.com/np/search?q=%EC%95%84%EC%8A%A4%ED%86%A0%EB%8B%88%EC%89%AC+%ED%8C%A8%EB%B8%8C%EB%A6%AD+%EC%96%BC%EB%A3%A9+%EC%A0%9C%EA%B1%B0%EC%A0%9C',
          ),
        ],
        caution: '가죽·스웨이드·전기장판에는 일반 패브릭 세정제를 바로 사용하지 마세요.',
      ),
      const ProductDiagnostic(
        id: 'fabric-dust',
        symptom: '먼지·털·진드기가 신경 쓰여요',
        question: '커버 분리 세탁 또는 청소기 사용이 가능한 소재인가요?',
        safeAction: '흡입력을 낮춘 청소기로 표면 먼지를 제거하고 분리 가능한 커버만 라벨에 따라 세탁하세요.',
        outcome: DiagnosticOutcome.selfCare,
        tools: ['침구용 청소기 노즐', '돌돌이 테이프', '보풀 제거 브러시'],
      ),
      const ProductDiagnostic(
        id: 'fabric-mold',
        symptom: '눅눅하거나 곰팡이 냄새가 나요',
        question: '검은 반점이 보이거나 내부까지 젖었나요?',
        safeAction: '사용을 멈추고 환기·건조하세요. 내부 충전재까지 곰팡이가 번지면 전문 세척이나 교체를 검토하세요.',
        outcome: DiagnosticOutcome.professionalSupport,
      ),
    ];

List<ProductDiagnostic> _electronicsDiagnostics(String productName) => [
      ProductDiagnostic(
        id: 'electronics-dust',
        symptom: '먼지·지문이 많이 보여요',
        question: '$productName의 전원이 꺼지고 열이 식었나요?',
        safeAction: '전원을 분리하고 마른 극세사 천으로 닦으세요. 액체를 화면이나 통풍구에 직접 분사하지 마세요.',
        outcome: DiagnosticOutcome.selfCare,
        steps: [
          '전원을 끄고 케이블을 분리해요.',
          '마른 극세사 천으로 먼지를 가볍게 걷어내요.',
          '통풍구는 부드러운 브러시로 바깥쪽 먼지만 제거해요.',
        ],
        tools: const ['전자기기용 극세사 천', '부드러운 먼지 브러시'],
        recommendedProducts: const [
          DiagnosticProductRecommendation(
            brand: '3M',
            name: '전자기기용 극세사 천',
            reason: '화면과 외관의 마른 먼지와 지문을 닦을 때 사용해요.',
            url:
                'https://www.coupang.com/np/search?q=3M+%EC%A0%84%EC%9E%90%EA%B8%B0%EA%B8%B0+%EA%B7%B9%EC%84%B8%EC%82%AC+%EC%B2%9C',
          ),
        ],
        caution: '알코올 사용 가능 여부는 제조사 안내를 확인하고, 종이타월과 거친 천은 화면에 사용하지 마세요.',
      ),
      const ProductDiagnostic(
        id: 'electronics-heat',
        symptom: '뜨겁거나 팬 소음이 커졌어요',
        question: '통풍구를 막는 물건을 치워도 과열과 소음이 계속되나요?',
        safeAction: '전원을 끄고 주변 통풍 공간을 확보하세요. 내부 분해 청소는 전문가에게 맡기세요.',
        outcome: DiagnosticOutcome.professionalSupport,
      ),
      const ProductDiagnostic(
        id: 'electronics-power',
        symptom: '전원이 꺼지거나 타는 냄새가 나요',
        question: '연기·불꽃·플러그 과열이 있나요?',
        safeAction: '전원을 차단하고 다시 켜지 마세요. 젖었거나 타는 냄새가 나면 점검받으세요.',
        outcome: DiagnosticOutcome.stopUsing,
        warningSigns: ['연기', '불꽃', '타는 냄새', '전원 플러그 과열'],
      ),
    ];

List<ProductDiagnostic> _openingDiagnostics(String productName) => [
      ProductDiagnostic(
        id: 'opening-dust',
        symptom: '먼지·손자국·빗물 자국이 보여요',
        question: '$productName의 재질과 코팅을 확인했나요?',
        safeAction: '마른 먼지를 먼저 제거한 뒤 중성 세제를 묽게 사용하고 물기를 바로 닦으세요.',
        outcome: DiagnosticOutcome.selfCare,
        steps: [
          '브러시나 청소기로 마른 먼지를 먼저 제거해요.',
          '중성 세제를 묻힌 천으로 위에서 아래로 닦아요.',
          '깨끗한 물수건과 마른 천으로 마무리해요.',
        ],
        tools: const ['먼지 브러시', '극세사 천', '창틀용 틈새 솔'],
        recommendedProducts: const [
          DiagnosticProductRecommendation(
            brand: '3M 스카치브라이트',
            name: '유리 청소용 극세사',
            reason: '유리와 문 표면의 물자국을 닦고 보풀을 줄이는 데 도움을 줘요.',
            url:
                'https://www.coupang.com/np/search?q=3M+%EC%9C%A0%EB%A6%AC+%EC%B2%AD%EC%86%8C+%EA%B7%B9%EC%84%B8%EC%82%AC',
          ),
        ],
      ),
      const ProductDiagnostic(
        id: 'opening-mold',
        symptom: '결로·곰팡이가 생겨요',
        question: '실리콘 안쪽이나 벽지까지 번졌나요?',
        safeAction: '환기하고 표면 물기를 제거하세요. 반복되는 결로는 단열·누수 원인을 함께 점검해야 해요.',
        outcome: DiagnosticOutcome.professionalSupport,
        caution: '곰팡이 제거제를 사용할 때 다른 세정제와 혼합하지 말고 충분히 환기하세요.',
      ),
      const ProductDiagnostic(
        id: 'opening-damage',
        symptom: '잘 움직이지 않거나 흔들려요',
        question: '레일 이물질을 제거해도 문·창·블라인드가 걸리나요?',
        safeAction: '무리하게 힘을 주지 말고 사용을 중단하세요. 유리 균열이나 탈락 위험은 즉시 수리받으세요.',
        outcome: DiagnosticOutcome.professionalSupport,
        warningSigns: ['유리 균열', '문짝 처짐', '부품 탈락'],
      ),
    ];

List<ProductDiagnostic> _furnitureDiagnostics(String productName) => [
      ProductDiagnostic(
        id: 'furniture-stain',
        symptom: '먼지·손때·얼룩이 생겼어요',
        question: '$productName의 원목·무늬목·도장·유리 등 마감재를 확인했나요?',
        safeAction: '마른 먼지를 제거하고 마감재에 맞는 방법으로 최소한의 물기만 사용해 닦으세요.',
        outcome: DiagnosticOutcome.selfCare,
        steps: [
          '부드러운 마른 천으로 먼지를 먼저 제거해요.',
          '눈에 띄지 않는 곳에 세정 방법을 시험해요.',
          '결 방향으로 가볍게 닦고 물기를 바로 제거해요.',
        ],
        tools: const ['부드러운 먼지 브러시', '극세사 천', '면봉'],
        recommendedProducts: const [
          DiagnosticProductRecommendation(
            brand: '3M',
            name: '가구용 극세사 천',
            reason: '표면 흠집과 과도한 물기 사용을 줄이며 먼지를 닦기 좋아요.',
            url:
                'https://www.coupang.com/np/search?q=3M+%EA%B0%80%EA%B5%AC%EC%9A%A9+%EA%B7%B9%EC%84%B8%EC%82%AC',
          ),
        ],
        caution: '원목과 무늬목에는 물을 흠뻑 적시거나 강한 알칼리·알코올 세정제를 사용하지 마세요.',
      ),
      const ProductDiagnostic(
        id: 'furniture-odor',
        symptom: '퀴퀴한 냄새나 습기가 느껴져요',
        question: '벽과 가구 사이에 결로나 곰팡이 흔적이 있나요?',
        safeAction: '내용물을 비우고 환기·건조한 뒤 벽과 뒷면의 습기 원인을 확인하세요.',
        outcome: DiagnosticOutcome.selfCare,
        tools: ['제습제', '습도계', '마른 천'],
      ),
      const ProductDiagnostic(
        id: 'furniture-loose',
        symptom: '흔들리거나 문·서랍이 걸려요',
        question: '바닥 수평과 눈에 보이는 나사 풀림을 확인해도 불안정한가요?',
        safeAction: '무거운 물건을 내리고 사용을 멈추세요. 전도 위험이나 구조 손상은 수리받으세요.',
        outcome: DiagnosticOutcome.professionalSupport,
        warningSigns: ['기울어짐', '균열', '벽 고정장치 이탈'],
      ),
    ];

List<ProductDiagnostic> _waterApplianceDiagnostics(String productName) => [
      const ProductDiagnostic(
        id: 'water-appliance-taste',
        symptom: '물맛·냄새가 이상해요',
        question: '필터 교체 주기와 장기간 미사용 후 배수 방법을 확인했나요?',
        safeAction: '음용을 중단하고 공식 필터와 플러싱 방법을 확인하세요. 이상이 지속되면 점검받으세요.',
        outcome: DiagnosticOutcome.replaceConsumable,
        tools: ['깨끗한 물받이', '마른 천'],
      ),
      const ProductDiagnostic(
        id: 'water-appliance-outlet',
        symptom: '출수구에 물때가 보여요',
        question: '제조사가 출수구 분리 세척을 허용하나요?',
        safeAction: '외부 출수구만 깨끗한 천으로 닦고 분리 세척은 설명서에서 허용한 경우에만 하세요.',
        outcome: DiagnosticOutcome.checkManual,
        steps: [
          '출수를 멈추고 전원과 냉온수 상태를 확인해요.',
          '외부 출수구의 물기를 깨끗한 천으로 닦아요.',
          '분리 가능한 구조인지 설명서에서 확인한 뒤 작은 솔로 관리해요.',
          '충분히 헹구거나 물을 흘려보낸 뒤 사용해요.',
        ],
        tools: ['전용 출수구 브러시', '극세사 천'],
        recommendedProducts: [
          DiagnosticProductRecommendation(
            brand: '3M',
            name: '정수기 출수구 청소 브러시',
            reason: '출수구 외부의 좁은 부분을 닦을 때 사용하는 작은 브러시예요.',
            url:
                'https://www.coupang.com/np/search?q=%EC%A0%95%EC%88%98%EA%B8%B0+%EC%B6%9C%EC%88%98%EA%B5%AC+%EC%B2%AD%EC%86%8C+%EB%B8%8C%EB%9F%AC%EC%8B%9C',
          ),
        ],
      ),
      const ProductDiagnostic(
        id: 'water-appliance-leak',
        symptom: '물이 새거나 출수가 멈췄어요',
        question: '급수 밸브와 전원을 차단해도 누수가 계속되나요?',
        safeAction: '급수 밸브를 잠그고 전원을 안전하게 분리한 뒤 서비스센터에 문의하세요.',
        outcome: DiagnosticOutcome.stopUsing,
        warningSigns: ['전원부 주변 물기', '계속되는 누수', '바닥 고임'],
      ),
    ];

bool _containsAny(String value, List<String> keywords) {
  return keywords.any(value.contains);
}
