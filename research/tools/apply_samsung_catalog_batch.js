const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "../..");
const inputDir = path.join(root, "catalog_input");
const researchPath = path.join(
  root,
  "research/catalog_batches/samsung_expansion_30.json",
);
const research = JSON.parse(fs.readFileSync(researchPath, "utf8").replace(/^\uFEFF/, ""));
const products = research.products;

const categoryNames = {
  refrigerator: "냉장고",
  kimchi_refrigerator: "김치냉장고",
  washer: "세탁기",
  air_conditioner: "에어컨",
  dishwasher: "식기세척기",
  induction: "인덕션",
  air_purifier: "공기청정기",
  vacuum: "청소기",
  dryer: "건조기",
};

const profiles = {
  refrigerator: {
    summary: "선반과 서랍을 분리 가능한 범위에서 닦고 도어 패킹과 내부를 완전히 말려 관리해요.",
    frequency: "오염이나 냄새가 느껴질 때",
    minutes: 25,
    method: "선반·서랍·도어 패킹 관리",
    installation: "제품 페이지의 설치 유형 확인",
    steps: [
      "식품을 다른 냉장 공간으로 옮기고 전원 플러그를 빼거나 설명서의 청소 준비 절차를 따라요.",
      "공식 설명서에서 사용자가 분리할 수 있다고 안내한 선반과 서랍만 꺼내요.",
      "분리한 부품은 급격한 온도 변화 없이 부드러운 천과 중성세제로 닦아요.",
      "냉장고 안쪽과 도어 패킹의 이물질을 부드러운 천으로 닦고 물기를 제거해요.",
      "부품을 완전히 말려 원래 위치에 장착하고 전원을 다시 연결해 온도를 확인해요.",
    ],
    supplies: ["부드러운 천", "부드러운 솔", "중성세제"],
    recommended: ["표면이 거칠지 않은 극세사 천", "패킹 틈새용 부드러운 브러시"],
    cautions: [
      "청소 전에는 전원 플러그를 빼거나 제품의 전원을 차단하세요.",
      "제품 안팎에 물을 직접 뿌리지 마세요.",
      "냉각 장치와 내부 배선을 임의로 분리하지 마세요.",
      "차가운 유리 선반에 뜨거운 물을 바로 사용하지 마세요.",
    ],
    keywords: ["냉장고", "선반", "서랍", "도어패킹"],
  },
  kimchi_refrigerator: {
    summary: "김치통과 저장실의 음식물 자국을 닦고 패킹과 냄새가 남지 않도록 충분히 건조해요.",
    frequency: "내용물을 교체하거나 냄새가 느껴질 때",
    minutes: 25,
    method: "김치통·저장실·도어 패킹 관리",
    installation: "스탠드형 또는 뚜껑형",
    steps: [
      "내용물을 다른 냉장 공간으로 옮기고 전원 플러그를 빼거나 설명서의 청소 준비 절차를 따라요.",
      "김치통과 사용자가 분리할 수 있는 선반·서랍만 꺼내 음식물 자국을 제거해요.",
      "분리한 김치통과 부품을 부드러운 천과 중성세제로 닦고 충분히 헹궈요.",
      "저장실 안쪽과 도어 패킹을 부드러운 천으로 닦고 남은 물기를 제거해요.",
      "모든 부품을 완전히 말려 원래 위치에 장착하고 설정 온도를 다시 확인해요.",
    ],
    supplies: ["부드러운 천", "부드러운 솔", "중성세제"],
    recommended: ["냄새가 남지 않는 주방용 중성세제", "패킹 틈새용 부드러운 브러시"],
    cautions: [
      "청소 전에는 전원 플러그를 빼거나 제품의 전원을 차단하세요.",
      "제품 안팎에 물을 직접 뿌리지 마세요.",
      "냉각 장치와 도어 부품을 임의로 분리하지 마세요.",
      "연마제와 강한 산성·알칼리성 세제를 사용하지 마세요.",
    ],
    keywords: ["김치냉장고", "김치통", "저장실", "도어패킹"],
  },
  washer: {
    summary: "세제함과 필터를 모델 안내에 맞게 관리하고 전용 통세척 코스로 내부를 관리해요.",
    frequency: "통세척 알림 또는 냄새·이물질이 느껴질 때",
    minutes: 20,
    method: "세제함·필터·세탁조 관리",
    installation: "드럼·통돌이·콤보형",
    steps: [
      "작동을 멈추고 전원 플러그를 뺀 뒤 급수와 내부 회전이 멈췄는지 확인해요.",
      "세제함을 설명서에 따라 분리해 남은 세제와 섬유유연제를 씻어내요.",
      "사용자가 관리하도록 안내된 배수필터나 거름망이 있는 경우 이물질을 제거해요.",
      "도어와 고무 패킹 또는 세탁조 가장자리를 부드러운 천으로 닦아요.",
      "제품이 안내하는 무세제통세척·통세척 코스를 실행하고 끝난 뒤 내부를 환기해요.",
    ],
    supplies: ["부드러운 천", "부드러운 솔"],
    recommended: ["세제함 틈새용 부드러운 브러시", "세탁기 전용 통세척제"],
    cautions: [
      "청소 전에는 전원 플러그를 빼세요.",
      "제품에 물을 직접 뿌리지 마세요.",
      "배수펌프와 전기 부품을 임의로 분리하지 마세요.",
      "필터를 열기 전에는 내부의 뜨거운 물을 충분히 식히세요.",
    ],
    keywords: ["세탁기", "세제함", "배수필터", "통세척"],
  },
  air_conditioner: {
    summary: "필터와 흡입구를 중심으로 관리하고 완전히 건조한 뒤 다시 조립해요.",
    frequency: "필터 알림 또는 오염 발견 시",
    minutes: 20,
    method: "필터 분리 세척과 외관 관리",
    installation: "스탠드형·벽걸이형 또는 멀티형",
    steps: [
      "운전을 정지하고 전원 플러그를 빼거나 차단기를 내린 뒤 제품이 멈춘 것을 확인해요.",
      "공식 설명서에 따라 사용자가 관리할 수 있는 필터만 분리해요.",
      "필터의 먼지를 제거하고 물세척이 허용된 필터만 흐르는 물로 세척해요.",
      "필터를 직사광선을 피해 완전히 말리고 흡입구와 외관은 부드러운 천으로 닦아요.",
      "필터를 원래 위치에 장착하고 실외기 주변의 통풍을 막는 물건이 없는지 확인해요.",
    ],
    supplies: ["부드러운 천", "부드러운 솔", "진공청소기"],
    recommended: ["표면이 거칠지 않은 극세사 천", "필터 먼지 제거용 부드러운 브러시"],
    cautions: [
      "청소 전에는 전원 플러그를 빼거나 차단기를 내리세요.",
      "제품에 물을 직접 뿌리지 마세요.",
      "냉매 배관과 전기 부품을 임의로 분리하지 마세요.",
      "물세척이 금지된 필터는 물에 담그지 마세요.",
    ],
    keywords: ["에어컨", "필터", "흡입구", "실외기"],
  },
  dishwasher: {
    summary: "필터와 분사 노즐의 이물질을 제거하고 도어 주변을 닦아 세척 성능을 유지해요.",
    frequency: "필터 오염 또는 냄새가 느껴질 때",
    minutes: 20,
    method: "필터·분사 노즐·도어 패킹 관리",
    installation: "빌트인 또는 트루빌트인",
    steps: [
      "작동을 멈추고 전원을 끈 뒤 내부가 충분히 식었는지 확인해요.",
      "하단 필터를 공식 설명서의 방향대로 분리하고 음식물과 이물질을 제거해요.",
      "세척이 허용된 필터를 흐르는 물과 부드러운 솔로 닦고 원래 위치에 단단히 장착해요.",
      "분사 노즐의 구멍이 막히지 않았는지 확인하고 사용자가 분리할 수 있는 노즐만 관리해요.",
      "도어 가장자리와 패킹을 부드러운 천으로 닦고 내부 물기를 말려요.",
      "제품이 안내하는 전용 관리 코스와 허용된 세정제만 사용해 내부를 관리해요.",
    ],
    supplies: ["부드러운 천", "부드러운 솔"],
    recommended: ["식기세척기 전용 클리너", "필터 틈새용 부드러운 브러시"],
    cautions: [
      "청소 전에는 전원을 끄고 뜨거운 물과 내부 부품이 식을 때까지 기다리세요.",
      "제품에 물을 직접 뿌리지 마세요.",
      "펌프와 배수 부품을 임의로 분리하지 마세요.",
      "일반 주방세제처럼 거품이 많이 나는 세제는 사용하지 마세요.",
    ],
    keywords: ["식기세척기", "필터", "분사노즐", "도어패킹"],
  },
  induction: {
    summary: "상판이 완전히 식은 뒤 음식물 자국을 닦고 조작부와 흡기구를 건조하게 관리해요.",
    frequency: "사용 후 상판이 식었을 때",
    minutes: 10,
    method: "상판·조작부·흡기구 관리",
    installation: "빌트인 또는 이동형",
    steps: [
      "전원을 끄고 잔열 표시가 사라져 상판이 완전히 식었는지 확인해요.",
      "마른 부드러운 천으로 부스러기와 가벼운 오염을 먼저 제거해요.",
      "제품이 허용한 전용 세정제를 부드러운 천에 소량 묻혀 상판을 닦아요.",
      "눌어붙은 오염은 설명서에서 허용한 스크래퍼를 낮은 각도로 사용해 제거해요.",
      "깨끗한 천으로 세정제와 물기를 닦고 흡기구 주변이 막히지 않았는지 확인해요.",
    ],
    supplies: ["부드러운 천", "인덕션 전용 세정제"],
    recommended: ["유리 상판용 인덕션 클리너", "제조사가 허용한 상판 스크래퍼"],
    cautions: [
      "청소 전에는 전원을 끄고 잔열 표시가 사라질 때까지 기다리세요.",
      "제품과 조작부에 물을 직접 뿌리지 마세요.",
      "상판과 전기 부품을 임의로 분리하지 마세요.",
      "철수세미와 거친 연마제를 사용하지 마세요.",
    ],
    keywords: ["인덕션", "상판", "잔열", "흡기구"],
  },
  air_purifier: {
    summary: "흡입구의 먼지를 제거하고 세척 가능한 필터와 교체형 필터를 구분해 관리해요.",
    frequency: "필터 알림 또는 오염 발견 시",
    minutes: 15,
    method: "흡입구 청소와 필터 관리",
    installation: "이동형",
    steps: [
      "운전을 정지하고 전원 플러그를 뺀 뒤 제품이 완전히 멈춘 것을 확인해요.",
      "흡입구와 배출구의 먼지를 진공청소기나 부드러운 솔로 제거해요.",
      "공식 설명서에 따라 사용자가 관리할 수 있는 필터만 분리해요.",
      "물세척이 허용된 필터만 세척하고 그늘에서 완전히 말려요.",
      "물세척이 금지된 집진·탈취 필터는 오염 상태와 교체 알림에 따라 교체해요.",
      "필터를 원래 위치에 장착하고 필요한 경우 필터 알림을 초기화해요.",
    ],
    supplies: ["부드러운 천", "부드러운 솔", "진공청소기"],
    recommended: ["표면이 거칠지 않은 극세사 천", "흡입구 먼지 제거용 부드러운 브러시"],
    cautions: [
      "청소 전에는 전원 플러그를 빼세요.",
      "제품에 물을 직접 뿌리지 마세요.",
      "집진·탈취 필터를 임의로 물세척하지 마세요.",
      "센서와 전기 부품을 임의로 분리하지 마세요.",
    ],
    keywords: ["공기청정기", "필터", "흡입구", "탈취필터"],
  },
  vacuum: {
    summary: "먼지통과 브러시의 이물질을 제거하고 모델에 따라 센서와 세척 가능한 필터를 관리해요.",
    frequency: "먼지통이 차거나 흡입력이 떨어질 때",
    minutes: 15,
    method: "먼지통·필터·브러시·센서 관리",
    installation: "무선 스틱형 또는 로봇형",
    steps: [
      "제품 전원을 끄고 충전기에서 분리한 뒤 분리형 배터리는 제품 안내에 따라 분리해요.",
      "먼지통을 비우고 먼지가 날리지 않도록 내부 이물질을 제거해요.",
      "공식 설명서에서 물세척이 허용된 먼지통과 필터만 흐르는 물로 세척해요.",
      "세척한 부품을 통풍이 잘되는 그늘에서 완전히 말린 뒤 장착해요.",
      "브러시에 감긴 머리카락과 실을 제거하고 로봇형은 센서와 바퀴를 부드러운 천으로 닦아요.",
      "청정스테이션의 먼지봉투와 필터는 알림과 공식 교체 안내에 따라 관리해요.",
    ],
    supplies: ["부드러운 천", "부드러운 솔"],
    recommended: ["브러시 이물질 제거용 청소 도구", "표면이 거칠지 않은 극세사 천"],
    cautions: [
      "청소 전에는 전원을 끄고 충전기에서 분리하세요.",
      "제품과 충전기에 물을 직접 뿌리지 마세요.",
      "모터·배터리·센서 부품을 임의로 분리하지 마세요.",
      "세척한 필터가 완전히 마르기 전에 장착하지 마세요.",
    ],
    keywords: ["청소기", "먼지통", "필터", "브러시", "센서"],
  },
  dryer: {
    summary: "보풀 필터를 비우고 센서와 열교환기 주변을 모델 안내에 맞게 관리해요.",
    frequency: "필터 알림 또는 건조 성능이 떨어질 때",
    minutes: 15,
    method: "보풀 필터와 센서 관리",
    installation: "독립형 또는 직렬 설치",
    steps: [
      "작동을 멈추고 전원 플러그를 뺀 뒤 제품이 충분히 식었는지 확인해요.",
      "보풀 필터를 분리해 먼지와 보풀을 제거해요.",
      "물세척이 허용된 필터만 흐르는 물로 씻고 완전히 말린 뒤 다시 장착해요.",
      "드럼 내부와 습도 센서를 부드러운 마른 천으로 닦아요.",
      "열교환기 관리 방식은 모델별 공식 설명서를 확인하고 사용자가 접근 가능한 부분만 관리해요.",
      "필터와 덮개가 정확히 장착됐는지 확인한 뒤 사용해요.",
    ],
    supplies: ["부드러운 천", "부드러운 솔", "진공청소기"],
    recommended: ["보풀 제거용 부드러운 브러시", "표면이 거칠지 않은 극세사 천"],
    cautions: [
      "청소 전에는 전원 플러그를 빼세요.",
      "제품에 물을 직접 뿌리지 마세요.",
      "열교환기 핀과 내부 부품을 임의로 분리하지 마세요.",
      "젖은 필터를 장착하지 마세요.",
    ],
    keywords: ["건조기", "보풀필터", "열교환기", "습도센서"],
  },
};

function parseCsv(text) {
  const matrix = [];
  let row = [];
  let field = "";
  let quoted = false;
  for (let index = 0; index < text.length; index += 1) {
    const character = text[index];
    if (quoted) {
      if (character === '"' && text[index + 1] === '"') {
        field += '"';
        index += 1;
      } else if (character === '"') {
        quoted = false;
      } else {
        field += character;
      }
    } else if (character === '"') {
      quoted = true;
    } else if (character === ",") {
      row.push(field);
      field = "";
    } else if (character === "\n") {
      row.push(field.replace(/\r$/, ""));
      matrix.push(row);
      row = [];
      field = "";
    } else {
      field += character;
    }
  }
  if (field || row.length) {
    row.push(field.replace(/\r$/, ""));
    matrix.push(row);
  }
  const headers = matrix.shift();
  return {
    headers,
    rows: matrix
      .filter((values) => values.some(Boolean))
      .map((values) =>
        Object.fromEntries(headers.map((header, index) => [header, values[index] || ""])),
      ),
  };
}

function csvCell(value) {
  const text = String(value ?? "");
  return /[",\r\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
}

function load(name) {
  return parseCsv(
    fs.readFileSync(path.join(inputDir, name), "utf8").replace(/^\uFEFF/, ""),
  );
}

function save(name, table) {
  const lines = [
    table.headers.join(","),
    ...table.rows.map((row) =>
      table.headers.map((header) => csvCell(row[header])).join(","),
    ),
  ];
  fs.writeFileSync(path.join(inputDir, name), `\uFEFF${lines.join("\r\n")}\r\n`, "utf8");
}

function productId(model) {
  return `samsung-${model.toLowerCase()}`;
}

function seriesName(name) {
  return name.split("(")[0].trim();
}

function featureValues(product) {
  const values = [];
  const pattern = /\d+(?:\.\d+)?(?:\/\d+(?:\.\d+)?)?(?:kg|L|㎡|W|cm|인용|구)/g;
  values.push(...(product.name.match(pattern) || []));
  for (const keyword of [
    "키친핏 Max",
    "키친핏",
    "AI 홈",
    "패밀리허브",
    "맞춤숙성실",
    "플렉스존",
    "후드일체형",
    "트루빌트인",
    "자동 급배수",
    "리모컨 포함",
  ]) {
    if (product.name.includes(keyword)) values.push(keyword);
  }
  return [...new Set(values)].slice(0, 4);
}

function productSpecs(product) {
  const specs = [
    ["출시 연도", `${product.releaseYear}년`],
    ["모델명", product.model],
  ];
  const features = featureValues(product);
  if (features.length) {
    specs.push(["주요 구분", features.join(" / ")]);
  }
  specs.push(["공식 제품명", product.name]);
  return specs;
}

const tableNames = [
  "products.csv",
  "sources.csv",
  "steps.csv",
  "specs.csv",
  "lists.csv",
  "models.csv",
];
const tables = Object.fromEntries(tableNames.map((name) => [name, load(name)]));
const batchIds = new Set(products.map((product) => productId(product.model)));
const batchModels = new Set(products.map((product) => product.model));

for (const name of tableNames.slice(0, 5)) {
  tables[name].rows = tables[name].rows.filter(
    (row) => !batchIds.has(row.productId || row.id),
  );
}
tables["models.csv"].rows = tables["models.csv"].rows.filter(
  (row) => !batchModels.has(row.modelName),
);

for (const product of products) {
  const id = productId(product.model);
  const profile = profiles[product.category];
  const categoryName = categoryNames[product.category];
  const productSource = `${id}-product`;
  const manualSource = `${id}-manual`;
  const features = featureValues(product);
  const sourceTitle = `삼성전자 ${product.name} 공식 제품 페이지`;

  tables["products.csv"].rows.push({
    publish: "true",
    id,
    name: product.name,
    type: "appliance",
    categoryName,
    brand: "삼성전자",
    manufacturer: "삼성전자",
    modelName: product.model,
    seriesName: seriesName(product.name),
    summary: profile.summary,
    frequency: profile.frequency,
    recurrenceDays: "0",
    estimatedMinutes: String(profile.minutes),
    productMethod: profile.method,
    guideStatus: "공식 설명서를 확인했어요.",
    guideBasis: "삼성전자 공식 제품 페이지와 해당 모델의 공식 사용설명서를 확인했어요.",
    guideSourceType: "official",
    matchLevelLabel: "공식 설명서 확인 모델",
    sourceTitle,
    sourceUrl: product.productUrl,
    sourceCheckedAt: product.checkedAt,
    officialManualUrl: product.manualUrl,
    supportUrl: product.supportUrl,
    servicePhone: "1588-3366",
    releaseYear: String(product.releaseYear),
    isDiscontinued: "false",
    imageUrl: product.imageUrl,
    installationType: profile.installation,
    reviewStatus: "verified",
    reviewedBy: "catalog-editor",
    reviewNote: "공식 제품 페이지와 모델별 공식 사용설명서 교차 검수 완료",
  });
  tables["sources.csv"].rows.push(
    {
      productId: id,
      sourceId: productSource,
      title: sourceTitle,
      url: product.productUrl,
      type: "officialProduct",
      publisher: "삼성전자",
      checkedAt: product.checkedAt,
      supports: "제품명|모델명|출시 연식|대표 이미지|주요 구분",
      isOfficial: "true",
      isActive: "true",
    },
    {
      productId: id,
      sourceId: manualSource,
      title: `삼성전자 ${product.model} 공식 사용설명서`,
      url: product.manualUrl,
      type: "officialManual",
      publisher: "삼성전자",
      checkedAt: product.checkedAt,
      supports: "청소 안전사항|관리 대상|관리 순서",
      isOfficial: "true",
      isActive: "true",
    },
  );
  profile.steps.forEach((text, index) => {
    tables["steps.csv"].rows.push({
      productId: id,
      order: String(index + 1),
      text,
      sourceIds: manualSource,
    });
  });
  productSpecs(product).forEach(([label, value], index) => {
    tables["specs.csv"].rows.push({
      productId: id,
      order: String(index + 1),
      label,
      value,
      sourceIds: productSource,
    });
  });
  const groups = [
    ["supply", profile.supplies],
    ["recommendedSupply", profile.recommended],
    ["caution", profile.cautions],
    ["keyword", [...profile.keywords, product.model, seriesName(product.name)]],
    ["modelFeature", features],
  ];
  for (const [kind, values] of groups) {
    values.forEach((value, index) => {
      tables["lists.csv"].rows.push({
        productId: id,
        kind,
        order: String(index + 1),
        value,
      });
    });
  }
  tables["models.csv"].rows.push({
    publish: "true",
    categoryName,
    brand: "삼성전자",
    modelName: product.model,
    displayName: product.name,
    releaseYear: String(product.releaseYear),
    imageUrl: product.imageUrl,
    productUrl: product.productUrl,
    features: features.join("|"),
    sourceCheckedAt: product.checkedAt,
    reviewStatus: "verified",
  });
}

for (const name of tableNames) save(name, tables[name]);
console.log(`Applied ${products.length} verified Samsung products.`);
