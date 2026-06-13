import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clean_up/app.dart';
import 'package:clean_up/data/mock_product_data.dart';
import 'package:clean_up/data/mock_zone_items.dart';
import 'package:clean_up/data/product_catalog.dart';
import 'package:clean_up/data/product_care_templates.dart';
import 'package:clean_up/data/product_consumable_defaults.dart';
import 'package:clean_up/data/visual_product_candidates.dart';
import 'package:clean_up/models/care_record.dart';
import 'package:clean_up/models/catalog_metadata.dart';
import 'package:clean_up/models/product_space.dart';
import 'package:clean_up/models/product_search_request.dart';
import 'package:clean_up/models/product_submission.dart';
import 'package:clean_up/models/product_consumable.dart';
import 'package:clean_up/models/zone_item.dart';
import 'package:clean_up/repositories/product_catalog_repository.dart';
import 'package:clean_up/repositories/product_data_repository.dart';
import 'package:clean_up/repositories/product_submission_repository.dart';

void main() {
  late MemoryProductDataRepository dataRepository;

  setUp(() {
    dataRepository = MemoryProductDataRepository();
  });

  test('제품 카탈로그는 모델명과 별칭으로 검색할 수 있다', () {
    expect(
      searchProductCatalog('DCS-HM4AG-W').single.modelName,
      'DCS-HM4AG-W',
    );
    expect(
      searchProductCatalog('dcs hm4ag w').first.modelName,
      'DCS-HM4AG-W',
    );
    expect(searchProductCatalog('음처기').single.brand, '에코업');
  });

  test('핵심 5개 시리즈는 앱 내장 카탈로그에서 검색할 수 있다', () {
    const ids = {
      'samsung-bespoke-ai-refrigerator-4door',
      'lg-dios-objet-refrigerator-top-bottom',
      'samsung-bespoke-ai-washer',
      'lg-tromm-objet-drum-washer',
      'samsung-bespoke-ai-windfree-classic',
    };

    expect(
      productCatalog.where((item) => ids.contains(item.id)).length,
      ids.length,
    );
    expect(
      searchProductCatalog('트롬 오브제컬렉션').first.seriesName,
      '트롬 오브제컬렉션 드럼세탁기',
    );
    expect(
      searchProductCatalog('무풍클래식').first.matchLevelLabel,
      '시리즈 기준',
    );
  });

  test('시리즈 정보는 등록 후 저장과 복원에서도 유지된다', () {
    final catalog =
        findCatalogEntryById('samsung-bespoke-ai-refrigerator-4door')!;
    final saved = catalog.toZoneItem(id: 'series-product', zoneId: 'kitchen');
    final restored = ZoneItem.fromJson(saved.toJson());

    expect(restored.seriesName, 'Bespoke AI 4도어');
    expect(restored.modelName, isEmpty);
    expect(restored.hasProductInfo, isTrue);
  });

  test('공식 확인 모델 메타데이터는 저장과 복원에서도 유지된다', () {
    final item = searchProductCatalog('Bespoke AI 4도어')
        .first
        .toZoneItem(id: 'exact-product', zoneId: 'kitchen')
        .copyWith(
          modelName: 'RM70F63R2A',
          modelDisplayName: 'Bespoke AI 냉장고 4도어 키친핏 Max 640L',
          modelReleaseYear: 2025,
          modelImageUrl: 'https://example.com/refrigerator.png',
          officialProductUrl: 'https://example.com/product',
          modelFeatures: const ['키친핏 Max', '640L'],
          matchLevelLabel: '공식 확인 모델',
        );

    final restored = ZoneItem.fromJson(item.toJson());

    expect(restored.modelName, 'RM70F63R2A');
    expect(restored.modelReleaseYear, 2025);
    expect(restored.modelImageUrl, contains('refrigerator.png'));
    expect(restored.officialProductUrl, contains('/product'));
    expect(restored.modelFeatures, ['키친핏 Max', '640L']);
    expect(restored.matchLevelLabel, '공식 확인 모델');
  });

  test('삼성 냉장고 3개 모델은 공식 설명서가 연결된 검수 카탈로그다', () {
    const models = ['RM70F63R2A', 'RM80F91H1W', 'RM70F90M1ZD'];

    for (final modelName in models) {
      final product = findCatalogEntry(
        categoryName: '냉장고',
        brand: '삼성전자',
        modelName: modelName,
      );

      expect(product, isNotNull, reason: modelName);
      expect(product!.reviewStatus, 'verified');
      expect(product.matchLevelLabel, '공식 설명서 확인 모델');
      expect(product.summary, isNot(contains('사용설명서')));
      expect(
        '정확한 모델과 공식 사용설명서를 확인했어요.'.allMatches(product.guideStatus).length,
        1,
      );
      expect(product.officialManualUrl, contains('DA68-04836T-01'));
      expect(
        product.sources.any(
          (source) => source.type == ProductSourceType.officialManual,
        ),
        isTrue,
      );
      expect(product.steps, hasLength(5));
      expect(product.cautions, contains('청소 전에는 전원 플러그를 빼세요.'));
    }
  });

  test('RM80F91H1W만 확인된 UV 청정탈취 필터를 제공한다', () {
    final hybrid = findCatalogEntry(
      categoryName: '냉장고',
      brand: '삼성전자',
      modelName: 'RM80F91H1W',
    )!;
    final kitchenFit = findCatalogEntry(
      categoryName: '냉장고',
      brand: '삼성전자',
      modelName: 'RM70F63R2A',
    )!;

    expect(hybrid.consumableDetails, hasLength(1));
    expect(hybrid.consumableDetails.single.name, 'UV 청정탈취 필터');
    expect(hybrid.consumableDetails.single.replacementDays, 3650);
    expect(kitchenFit.consumableDetails, isEmpty);
  });

  test('이전 버전의 정확한 모델은 로드할 때 공식 메타데이터로 보강된다', () async {
    final legacyItem = searchProductCatalog('Bespoke AI 4도어')
        .first
        .toZoneItem(id: 'legacy-exact-product', zoneId: 'kitchen')
        .copyWith(modelName: 'RM70F63R2A');
    SharedPreferences.setMockInitialValues({
      'zone_items_v1': jsonEncode([legacyItem.toJson()]),
    });

    final products = await const ProductDataRepository().loadUserProducts();
    final upgraded = products!.single;

    expect(upgraded.modelDisplayName, contains('키친핏 Max'));
    expect(upgraded.modelReleaseYear, 2025);
    expect(upgraded.modelImageUrl, isNotEmpty);
    expect(upgraded.officialProductUrl, contains('samsung.com'));
    expect(upgraded.officialManualUrl, contains('DA68-04836T-01'));
    expect(upgraded.catalogProductId, 'samsung-rm70f63r2a');
    expect(upgraded.matchLevelLabel, '공식 설명서 확인 모델');
  });

  test('대표 브랜드 목록에는 브랜드 미상이 표시되지 않는다', () {
    expect(catalogBrandOptionsFor('냉장고'), isNot(contains('브랜드 미상')));
    expect(
      catalogBrandOptionsFor('공기청정기'),
      isNot(contains('브랜드 미상')),
    );
  });

  test('TV는 로컬 대체 목록에서도 삼성전자 모델을 찾을 수 있다', () async {
    const repository = LocalProductCatalogRepository();

    expect(await repository.brandsFor('TV'), contains('삼성전자'));
    final models = await repository.modelsFor(
      category: 'TV',
      brand: '삼성전자',
    );
    expect(
      models.map((item) => item.modelName),
      contains('KQ65QNF90AFXKR'),
    );
  });

  test('서버 모델 목록이 비어 있으면 앱 내장 후보를 사용한다', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"items":[],"total":0}');
      await request.response.close();
    });
    final repository = RemoteFirstProductCatalogRepository(
      baseUrl: 'http://${server.address.host}:${server.port}',
    );

    try {
      final models = await repository.modelsFor(
        category: '냉장고',
        brand: '삼성전자',
      );

      expect(
        models.map((item) => item.modelName),
        containsAll(['RM70F63R2A', 'RM80F91H1W', 'RM70F90M1ZD']),
      );
      for (final model in models) {
        expect(model.releaseYear, 2025);
        expect(model.imageUrl, isNotEmpty);
        expect(model.features, isNotEmpty);
      }
    } finally {
      await server.close(force: true);
    }
  });

  test('카탈로그 제품 ID와 출처 정보는 저장 후에도 유지된다', () {
    final item = productCatalog.first.toZoneItem(
      id: 'saved-product',
      zoneId: 'zone-1',
    );
    final restored = ZoneItem.fromJson(item.toJson());

    expect(restored.catalogProductId, productCatalog.first.id);
    expect(restored.matchLevelLabel, '모델명 일치');
    expect(restored.sourceTitle, contains('다나와'));
    expect(restored.productSources, hasLength(2));
    expect(restored.productSources.last.isOfficial, isTrue);
    expect(restored.productSpecs, contains('처리용량: 1kg'));
  });

  test('공개 카탈로그는 출처와 검수 이력 규칙을 충족한다', () {
    for (final product in productCatalog) {
      expect(
        product.validateForPublication(),
        isEmpty,
        reason: product.id,
      );
    }
  });

  test('오래되거나 비활성인 출처는 재검수 대상으로 판단한다', () {
    final currentProduct = productCatalog.first;

    expect(currentProduct.needsSourceReview(DateTime(2026, 6, 9)), isFalse);
    expect(
      currentProduct.needsSourceReview(
        DateTime(2027, 1, 1),
        maxAgeDays: 180,
      ),
      isTrue,
    );
  });

  test('냉장고와 식기세척기는 서로 다른 관리법을 사용한다', () {
    final refrigerator = findProductCareTemplate('냉장고')!;
    final dishwasher = findProductCareTemplate('식기세척기')!;

    expect(refrigerator.focusAreas, contains('문 고무패킹'));
    expect(refrigerator.steps.join(' '), contains('선반'));
    expect(refrigerator.steps.join(' '), isNot(contains('분사 날개')));

    expect(dishwasher.focusAreas, contains('배수구 주변'));
    expect(dishwasher.steps.join(' '), contains('필터'));
    expect(dishwasher.steps.join(' '), contains('분사 날개'));
    expect(dishwasher.cautions.join(' '), contains('일반 주방세제'));
  });

  test('냉장고 외형 후보는 문 구조와 출시 시기를 제공한다', () {
    final candidates = visualCandidatesFor(
      categoryName: '냉장고',
      brand: '삼성전자',
    );

    expect(candidates, hasLength(4));
    expect(candidates.first.formFactor, contains('4도어'));
    expect(candidates.first.releasePeriod, isNotEmpty);
    expect(candidates.first.features, contains('위쪽 냉장실'));
  });

  test('사용자 제품의 별칭과 구매 정보는 저장 후에도 유지된다', () {
    final purchaseDate = DateTime(2025, 3, 2);
    final installedDate = DateTime(2025, 3, 5);
    final item = productCatalog.first
        .toZoneItem(id: 'my-product', zoneId: 'zone-1')
        .copyWith(
          nickname: '싱크대 처리기',
          purchaseDate: purchaseDate,
          installedDate: installedDate,
          note: '필터는 싱크대 아래 보관',
        );

    final restored = ZoneItem.fromJson(item.toJson());

    expect(restored.displayName, '싱크대 처리기');
    expect(restored.purchaseDate, purchaseDate);
    expect(restored.installedDate, installedDate);
    expect(restored.note, '필터는 싱크대 아래 보관');
  });

  test('스캔한 제품 코드는 저장 후에도 유지된다', () {
    final item = productCatalog.first
        .toZoneItem(id: 'scanned-product', zoneId: 'zone-1')
        .copyWith(
          scannedCode: '8801234567890',
          scannedCodeFormat: 'ean13',
          scannedSourceUrl: 'https://example.com/products/8801234567890',
        );

    final restored = ZoneItem.fromJson(item.toJson());

    expect(restored.scannedCode, '8801234567890');
    expect(restored.scannedCodeFormat, 'ean13');
    expect(
      restored.scannedSourceUrl,
      'https://example.com/products/8801234567890',
    );
  });

  test('이전 공간과 관리 기록 JSON을 새 모델로 읽을 수 있다', () async {
    SharedPreferences.setMockInitialValues({
      'zones_v1': jsonEncode([
        {
          'id': 'legacy-space',
          'name': '주방',
          'description': '이전 버전 공간',
          'taskCount': 3,
          'completedTaskCount': 2,
        },
      ]),
      'cleaning_records_v1': jsonEncode([
        {
          'id': 'legacy-record',
          'title': '냉장고 청소 완료',
          'zoneName': '주방',
          'completedAt': '2026-06-01T10:00:00.000',
          'minutes': 10,
        },
      ]),
    });
    const repository = ProductDataRepository();

    final spaces = await repository.loadSpaces();
    final records = await repository.loadCareRecords();

    expect(spaces!.single.productCount, 3);
    expect(spaces.single.identifiedProductCount, 2);
    expect(records!.single.spaceName, '주방');
    expect(records.single.productId, isNull);
    expect(records.single.spaceId, isNull);
    expect(records.single.type, CareRecordType.cleaning);
  });

  test('확장 관리 기록은 유형과 상세 내용을 저장 후 복원한다', () {
    final record = CareRecord(
      id: 'record-phase-4',
      title: '식기세척기 필터 교체',
      spaceName: '주방',
      completedAt: DateTime(2026, 6, 11, 9, 20),
      minutes: 10,
      type: CareRecordType.filterReplacement,
      productId: 'kitchen-dishwasher',
      productName: '식기세척기',
      spaceId: 'zone-1',
      guideTitle: '필터 관리',
      usedSupplies: const ['교체 필터', '마른 천'],
      result: '냄새가 줄어듦',
      note: '다음에는 배수구도 함께 확인',
      nextCheckAt: DateTime(2026, 9, 11),
    );

    final restored = CareRecord.fromJson(record.toJson());

    expect(restored.type, CareRecordType.filterReplacement);
    expect(restored.usedSupplies, ['교체 필터', '마른 천']);
    expect(restored.result, '냄새가 줄어듦');
    expect(restored.note, '다음에는 배수구도 함께 확인');
    expect(restored.nextCheckAt, DateTime(2026, 9, 11));
  });

  test('제품군 기본 소모품은 호환 수준과 교체 주기를 제공한다', () {
    final refrigerator = defaultConsumablesFor('냉장고');
    final airPurifier = defaultConsumablesFor('공기청정기');

    expect(refrigerator, hasLength(2));
    expect(refrigerator.first.compatibilityLabel, contains('모델'));
    expect(refrigerator.first.replacementDays, 180);
    expect(airPurifier.single.name, contains('필터'));
    expect(airPurifier.single.partNumber, isNull);
  });

  test('소모품 교체 기록은 제품의 마지막 청소 기록으로 계산하지 않는다', () {
    final records = [
      CareRecord(
        id: 'replacement',
        title: '냉장고 정수 필터 교체',
        spaceName: '주방',
        completedAt: DateTime(2026, 6, 11),
        minutes: 0,
        type: CareRecordType.filterReplacement,
        productId: 'fridge',
        consumableId: 'water-filter',
      ),
      CareRecord(
        id: 'cleaning',
        title: '냉장고 청소',
        spaceName: '주방',
        completedAt: DateTime(2026, 6, 1),
        minutes: 0,
        type: CareRecordType.cleaning,
        productId: 'fridge',
      ),
    ];

    expect(
      latestScheduledCareRecord(records, 'fridge')!.id,
      'cleaning',
    );
  });

  test('소모품 교체일과 다음 교체일은 저장 후 유지된다', () {
    final replacedAt = DateTime(2026, 6, 11);
    final consumable = const ProductConsumable(
      id: 'filter',
      name: '집진 필터',
      type: ConsumableType.filter,
      replacementDays: 180,
      compatibilityLabel: '모델별 확인 필요',
    ).markReplaced(replacedAt);

    final restored = ProductConsumable.fromJson(consumable.toJson());

    expect(restored.lastReplacedAt, replacedAt);
    expect(
        restored.nextReplacementAt, replacedAt.add(const Duration(days: 180)));
  });

  test('제품 정보 제보는 전송 상태와 추적 토큰을 저장한다', () {
    final now = DateTime(2026, 6, 11, 10, 30);
    final submission = ProductSubmission(
      id: 'submission-1',
      trackingToken: 'tracking-token',
      type: ProductSubmissionType.incorrectGuide,
      title: '관리법 확인 요청',
      details: '설명서와 순서가 달라요.',
      productId: 'product-1',
      createdAt: now,
      updatedAt: now,
      status: ProductSubmissionStatus.investigating,
      statusMessage: '공식 설명서를 확인하고 있어요.',
    );

    final restored = ProductSubmission.fromJson(
      jsonDecode(jsonEncode(submission.toJson())) as Map<String, Object?>,
    );

    expect(restored.trackingToken, 'tracking-token');
    expect(restored.status, ProductSubmissionStatus.investigating);
    expect(restored.productId, 'product-1');
  });

  test('손상된 로컬 제품 데이터는 직전 백업으로 복구한다', () async {
    SharedPreferences.setMockInitialValues({
      'zone_items_v1': '{broken-json',
      'zone_items_v1_backup': jsonEncode([mockZoneItems.first.toJson()]),
    });
    const repository = ProductDataRepository();

    final recovered = await repository.loadUserProducts();
    final preferences = await SharedPreferences.getInstance();

    expect(recovered, hasLength(1));
    expect(recovered!.single.id, mockZoneItems.first.id);
    expect(preferences.getString('zone_items_v1'), isNot('{broken-json'));
  });

  test('기존 정확 모델은 사용자 정보를 유지하며 카탈로그 ID를 연결한다', () async {
    final legacyProduct = productCatalog.first
        .toZoneItem(id: 'legacy-product', zoneId: 'zone-1')
        .toJson()
      ..remove('catalogProductId')
      ..['sourceTitle'] = '이전 버전에서 저장한 출처';
    SharedPreferences.setMockInitialValues({
      'zone_items_v1': jsonEncode([legacyProduct]),
    });
    const repository = ProductDataRepository();

    final products = await repository.loadUserProducts();

    expect(products!.single.catalogProductId, 'eco-up-dcs-hm4ag-w');
    expect(products.single.sourceTitle, contains('에코업'));
  });

  test('연결된 제품은 더 최신인 검수 카탈로그로 자동 갱신된다', () async {
    final savedProduct = productCatalog.first
        .toZoneItem(id: 'saved-eco-up', zoneId: 'zone-1')
        .toJson()
      ..['nickname'] = '우리집 음처기'
      ..['sourceCheckedAt'] = DateTime(2026, 6, 8).toIso8601String()
      ..['frequency'] = '주 1회'
      ..['recurrenceDays'] = 7
      ..['estimatedMinutes'] = 12
      ..['nextDueAt'] = DateTime(2026, 6, 20).toIso8601String();
    SharedPreferences.setMockInitialValues({
      'zone_items_v1': jsonEncode([savedProduct]),
    });
    const repository = ProductDataRepository();

    final products = await repository.loadUserProducts();
    final updated = products!.single;

    expect(updated.nickname, '우리집 음처기');
    expect(updated.sourceCheckedAt, DateTime(2026, 6, 12));
    expect(updated.frequency, contains('공식 관리 주기 미확인'));
    expect(updated.recurrenceDays, 0);
    expect(updated.estimatedMinutes, 0);
    expect(updated.nextDueAt, isNull);
    expect(updated.recommendedProducts, isEmpty);
  });

  test('같은 검수일이어도 변경된 카탈로그 관리 문구는 자동 갱신된다', () async {
    final catalogProduct = findCatalogEntry(
      categoryName: '냉장고',
      brand: '삼성전자',
      modelName: 'RM70F63R2A',
    )!;
    final savedProduct = catalogProduct
        .toZoneItem(id: 'saved-refrigerator', zoneId: 'kitchen')
        .toJson()
      ..['summary'] = '삼성전자 공식 RF9000F 2025 사용설명서에 따라 문과 내부 부속품을 관리해요.';
    SharedPreferences.setMockInitialValues({
      'zone_items_v1': jsonEncode([savedProduct]),
    });

    final products = await const ProductDataRepository().loadUserProducts();
    final updated = products!.single;

    expect(updated.summary, catalogProduct.summary);
    expect(updated.summary, isNot(contains('사용설명서에 따라')));
    expect(updated.guideStatus, catalogProduct.guideStatus);
  });

  test('이전 범용 식기세척기 관리법은 제품군 관리법으로 자동 갱신된다', () async {
    const legacyDishwasher = ZoneItem(
      id: 'legacy-dishwasher',
      zoneId: 'zone-1',
      name: '식기세척기',
      nickname: '우리집 식기세척기',
      type: ZoneItemType.appliance,
      summary: '식기세척기 제품의 재질과 사용설명서를 확인한 뒤 관리하세요.',
      frequency: '필요할 때',
      supplies: ['부드러운 천', '중성세제'],
      cautions: ['가전은 전원을 분리하세요.'],
      steps: [
        '식기세척기 주변의 물건과 먼지를 먼저 정리해요.',
        '제품 재질에 맞는 도구로 오염을 닦아요.',
        '깨끗한 천으로 세제와 물기를 제거해요.',
        '충분히 건조한 뒤 원래 위치에 정리해요.',
      ],
    );
    SharedPreferences.setMockInitialValues({
      'zone_items_v1': jsonEncode([legacyDishwasher.toJson()]),
    });
    const repository = ProductDataRepository();

    final products = await repository.loadUserProducts();

    expect(products!.single.nickname, '우리집 식기세척기');
    expect(products.single.frequency, contains('필터'));
    expect(products.single.steps.join(' '), contains('분사 날개'));
    expect(products.single.steps.join(' '), contains('배수구'));
  });

  testWidgets('제품 관리형 앱의 주요 화면을 표시한다', (tester) async {
    seedSampleData(dataRepository);
    await pumpApp(tester, dataRepository);

    expect(find.text('홈'), findsWidgets);
    expect(find.text('내 제품'), findsOneWidget);
    expect(find.text('기록'), findsOneWidget);
    expect(find.text('자랑'), findsNothing);
    expect(find.text('CARE INDEX'), findsOneWidget);
    expect(find.text('등록 제품'), findsOneWidget);
  });

  testWidgets('공간에서 등록 제품과 제품 추가 기능을 볼 수 있다', (tester) async {
    seedSampleData(dataRepository);
    await pumpApp(tester, dataRepository);

    await tester.tap(find.text('내 제품'));
    await tester.pumpAndSettle();

    expect(find.text('주방'), findsOneWidget);
    expect(find.text('거실'), findsOneWidget);

    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();

    expect(find.text('에코업 음식물처리기'), findsOneWidget);
    expect(find.text('냉장고'), findsOneWidget);
    expect(find.text('제품 추가'), findsOneWidget);
  });

  testWidgets('관리 완료 기록에는 제품명이 아닌 실제 공간이 저장된다', (tester) async {
    seedSampleData(dataRepository);
    await pumpApp(tester, dataRepository);

    await tester.tap(find.text('내 제품'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('냉장고'));
    await tester.pumpAndSettle();

    expect(find.text('관리법'), findsOneWidget);
    expect(find.text('문제 해결'), findsOneWidget);
    expect(find.text('소모품'), findsOneWidget);
    expect(find.text('제품 정보'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '오늘 청소'));
    await tester.pumpAndSettle();

    final records = await dataRepository.loadCareRecords();
    expect(records!.first.title, '냉장고 관리 완료');
    expect(records.first.spaceName, '주방');
    expect(records.first.spaceId, 'zone-1');
    expect(records.first.productId, 'kitchen-refrigerator');
  });

  testWidgets('제품 상세에서 유형과 메모가 있는 관리 기록을 추가할 수 있다', (tester) async {
    seedSampleData(dataRepository);
    await pumpApp(tester, dataRepository);

    await tester.tap(find.text('내 제품'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('냉장고'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, '기록'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '기록 추가'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('상세 내용 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('필터 교체'));
    await tester.pumpAndSettle();
    final noteField = find.byKey(const ValueKey('care-record-note'));
    await tester.ensureVisible(noteField);
    await tester.enterText(noteField, '다음에는 안쪽 먼지도 확인');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final saveButton = find.widgetWithText(FilledButton, '기록 저장');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    final records = await dataRepository.loadCareRecords();
    final saved = records!.first;
    expect(saved.type, CareRecordType.filterReplacement);
    expect(saved.productId, 'kitchen-refrigerator');
    expect(saved.usedSupplies, isEmpty);
    expect(saved.result, isNull);
    expect(saved.note, '다음에는 안쪽 먼지도 확인');
  });

  testWidgets('이미 등록한 제품에서도 내 제품 찾기로 정확한 모델을 추가할 수 있다', (tester) async {
    final seriesProduct =
        findCatalogEntryById('samsung-bespoke-ai-refrigerator-4door')!
            .toZoneItem(id: 'series-refrigerator', zoneId: 'zone-1');
    await dataRepository.saveSpaces(productSpaces);
    await dataRepository.saveUserProducts([seriesProduct]);
    await pumpApp(tester, dataRepository);

    await tester.tap(find.text('내 제품'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삼성 Bespoke AI 냉장고 4도어'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('제품 정보 수정'));
    await tester.pumpAndSettle();

    final finderButton = find.widgetWithText(FilledButton, '내 제품 찾기');
    await tester.ensureVisible(finderButton);
    await tester.tap(finderButton);
    await tester.pumpAndSettle();

    final targetModelCard = find
        .ancestor(
          of: find.text('RM70F63R2A').first,
          matching: find.byType(Card),
        )
        .first;
    await tester.tap(
      find.descendant(
        of: targetModelCard,
        matching: find.text('정확해요'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('정확한 모델 바꾸기'), findsOneWidget);
    final saveButton = find.widgetWithText(FilledButton, '제품 정보 저장');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    final products = await dataRepository.loadUserProducts();
    final refrigerator =
        products!.firstWhere((item) => item.id == 'series-refrigerator');
    expect(refrigerator.manufacturer, '삼성전자');
    expect(refrigerator.modelName, 'RM70F63R2A');
    expect(refrigerator.modelDisplayName, contains('키친핏 Max'));
    expect(refrigerator.modelReleaseYear, 2025);
    expect(refrigerator.modelImageUrl, isNotEmpty);
    expect(refrigerator.officialProductUrl, contains('samsung.com'));
    expect(refrigerator.modelFeatures, contains('640L'));
    expect(refrigerator.officialManualUrl, contains('DA68-04836T-01'));
    expect(refrigerator.catalogProductId, 'samsung-rm70f63r2a');
    expect(refrigerator.matchLevelLabel, '공식 설명서 확인 모델');
    expect(refrigerator.visualCandidateId, isNull);
  });

  testWidgets('소모품 교체는 별도 교체 기록과 다음 교체일을 저장한다', (tester) async {
    seedSampleData(dataRepository);
    await pumpApp(tester, dataRepository);

    await tester.tap(find.text('내 제품'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('냉장고'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, '소모품'));
    await tester.pumpAndSettle();

    expect(find.text('정수 필터'), findsOneWidget);
    await tester.tap(find.text('교체했어요').first);
    await tester.pumpAndSettle();

    final products = await dataRepository.loadUserProducts();
    final refrigerator = products!.firstWhere(
      (item) => item.id == 'kitchen-refrigerator',
    );
    final filter = refrigerator.consumables.firstWhere(
      (item) => item.id == 'refrigerator-water-filter',
    );
    expect(filter.lastReplacedAt, isNotNull);
    expect(filter.nextReplacementAt, isNotNull);

    final records = await dataRepository.loadCareRecords();
    expect(records!.first.type, CareRecordType.filterReplacement);
    expect(records.first.consumableId, 'refrigerator-water-filter');
  });

  testWidgets('전체 기록에서 유형으로 필터하고 기록을 삭제할 수 있다', (tester) async {
    seedSampleData(dataRepository);
    await dataRepository.saveCareRecords([
      CareRecord(
        id: 'filter-record',
        title: '냉장고 필터 교체',
        spaceName: '주방',
        completedAt: DateTime(2026, 6, 11),
        minutes: 10,
        type: CareRecordType.filterReplacement,
        productId: 'kitchen-refrigerator',
        productName: '냉장고',
        spaceId: 'zone-1',
      ),
      ...careRecords,
    ]);
    await pumpApp(tester, dataRepository);

    await tester.tap(find.text('기록'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '모든 유형'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('필터 교체').last);
    await tester.pumpAndSettle();

    expect(find.text('냉장고 필터 교체'), findsOneWidget);
    expect(find.text('음식물처리기 관리 완료'), findsNothing);

    await tester.tap(find.byTooltip('기록 메뉴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '삭제'));
    await tester.pumpAndSettle();

    final records = await dataRepository.loadCareRecords();
    expect(
        records,
        isNot(contains(predicate<CareRecord>(
          (record) => record.id == 'filter-record',
        ))));
  });

  testWidgets('모델 검색으로 카탈로그 제품을 등록할 수 있다', (tester) async {
    seedSampleData(dataRepository);
    await pumpApp(tester, dataRepository);

    await tester.tap(find.text('내 제품'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제품 추가'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, '제품 검색'),
      'DCS-HM4AG-W',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(ListTile, '에코업 음식물처리기').last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '이 정보로 계속'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '등록 내용 확인'));
    await tester.pumpAndSettle();

    expect(find.text('비슷한 제품이 이미 있어요'), findsOneWidget);
    await tester.tap(find.text('별도 제품으로 등록'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('나중에 보기'));
    await tester.pumpAndSettle();

    final products = await dataRepository.loadUserProducts();
    final registered = products!.lastWhere(
      (item) => item.id.startsWith('product-'),
    );
    expect(registered.catalogProductId, 'eco-up-dcs-hm4ag-w');
    expect(registered.modelName, 'DCS-HM4AG-W');
    expect(registered.nextDueAt, isNull);
  });

  testWidgets('모델명을 몰라도 제품 종류와 별칭으로 등록할 수 있다', (tester) async {
    seedSampleData(dataRepository);
    await pumpApp(tester, dataRepository);

    await tester.tap(find.text('내 제품'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제품 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('모델명을 몰라요'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '제품 종류'),
      '식기세척기',
    );
    await tester.tap(find.widgetWithText(FilledButton, '이 정보로 계속'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '별칭 (선택)'),
      '주방 식기세척기',
    );
    await tester.tap(find.widgetWithText(FilledButton, '등록 내용 확인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('나중에 보기'));
    await tester.pumpAndSettle();

    final products = await dataRepository.loadUserProducts();
    final registered = products!.last;
    expect(registered.name, '식기세척기');
    expect(registered.nickname, '주방 식기세척기');
    expect(registered.catalogProductId, isNull);
    expect(registered.frequency, contains('필터'));
    expect(registered.steps.join(' '), contains('배수구'));
    expect(registered.steps.join(' '), contains('분사 날개'));
    expect(registered.supplies, contains('제품 허용 세척제'));
  });

  testWidgets('제품 등록 추천은 선택한 구역에 맞게 표시된다', (tester) async {
    seedSampleData(dataRepository);
    await pumpApp(tester, dataRepository);

    await tester.tap(find.text('내 제품'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('거실'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제품 추가'));
    await tester.pumpAndSettle();

    expect(find.text('거실에서 자주 등록하는 제품'), findsOneWidget);
    expect(find.text('TV'), findsOneWidget);
    expect(find.text('소파'), findsOneWidget);
    expect(find.text('냉장고'), findsNothing);
    expect(find.text('음식물처리기'), findsNothing);
  });

  testWidgets('냉장고는 브랜드 선택 후 외형으로 비슷한 제품을 등록할 수 있다', (tester) async {
    await dataRepository.saveSpaces(productSpaces);
    await dataRepository.saveUserProducts([]);
    await pumpApp(tester, dataRepository);

    await tester.tap(find.text('내 제품'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제품 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('냉장고'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삼성전자'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('내 제품 찾기'));
    await tester.pumpAndSettle();

    expect(find.text('내 제품 찾기'), findsOneWidget);
    await tester.tap(find.text('외형으로 찾기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('4도어 냉장고'), findsOneWidget);
    await tester.tap(find.text('비슷해요').first);
    await tester.pumpAndSettle();

    expect(find.text('유사 제품'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '이 정보로 계속'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '등록 내용 확인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('나중에 보기'));
    await tester.pumpAndSettle();

    final products = await dataRepository.loadUserProducts();
    final product = products!.single;
    expect(product.manufacturer, '삼성전자');
    expect(product.modelName, isNull);
    expect(product.productMethod, contains('4도어'));
    expect(product.releasePeriod, contains('2018년 이후'));
    expect(product.matchLevelLabel, '외형 기반 유사 제품');
  });

  testWidgets('모델명은 별도 선택 화면에서 고를 수 있다', (tester) async {
    await dataRepository.saveSpaces(productSpaces);
    await dataRepository.saveUserProducts([]);
    await pumpApp(tester, dataRepository);

    await tester.tap(find.text('내 제품'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제품 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('냉장고'));
    await tester.pumpAndSettle();

    expect(find.text('브랜드 미상'), findsNothing);
    await tester.tap(find.text('삼성전자'));
    await tester.pumpAndSettle();
    final productFinderButton = find.widgetWithText(FilledButton, '내 제품 찾기');
    await tester.ensureVisible(productFinderButton);
    await tester.pumpAndSettle();
    await tester.tap(productFinderButton);
    await tester.pumpAndSettle();

    expect(find.text('RM70F63R2A'), findsWidgets);
    final targetModelCard = find
        .ancestor(
          of: find.text('RM70F63R2A').first,
          matching: find.byType(Card),
        )
        .first;
    await tester.tap(
      find.descendant(
        of: targetModelCard,
        matching: find.text('정확해요'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('선택한 모델: RM70F63R2A'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '이 정보로 계속'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '등록 내용 확인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('나중에 보기'));
    await tester.pumpAndSettle();

    final products = await dataRepository.loadUserProducts();
    expect(products!.single.manufacturer, '삼성전자');
    expect(products.single.modelName, 'RM70F63R2A');
    expect(products.single.visualCandidateId, isNull);
  });

  testWidgets('내 제품 찾기 화면을 반복해서 열고 닫아도 오류가 발생하지 않는다', (tester) async {
    await dataRepository.saveSpaces(productSpaces);
    await dataRepository.saveUserProducts([]);
    await pumpApp(tester, dataRepository);

    await tester.tap(find.text('내 제품'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제품 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('냉장고'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삼성전자'));
    await tester.pumpAndSettle();

    final productFinderButton = find.widgetWithText(FilledButton, '내 제품 찾기');
    await tester.ensureVisible(productFinderButton);
    await tester.pumpAndSettle();
    await tester.tap(productFinderButton);
    await tester.pumpAndSettle();
    final targetModelCard = find
        .ancestor(
          of: find.text('RM70F63R2A').first,
          matching: find.byType(Card),
        )
        .first;
    await tester.tap(
      find.descendant(
        of: targetModelCard,
        matching: find.text('정확해요'),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final selectedButton = find.widgetWithText(FilledButton, 'RM70F63R2A');
    await tester.ensureVisible(selectedButton);
    await tester.pumpAndSettle();
    await tester.tap(selectedButton);
    await tester.pumpAndSettle();
    expect(find.text('내 제품 찾기'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(FilledButton, 'RM70F63R2A'), findsOneWidget);
  });

  testWidgets('검색 실패 시 제품 정보 요청을 저장할 수 있다', (tester) async {
    seedSampleData(dataRepository);
    await pumpApp(tester, dataRepository);

    await tester.tap(find.text('내 제품'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제품 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '제품 검색'),
      '없는모델-1234',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('제품 정보 추가 요청'));
    await tester.pumpAndSettle();

    final requests = await dataRepository.loadProductSearchRequests();
    expect(requests!.single.query, '없는모델-1234');
    final submissions = await dataRepository.loadProductSubmissions();
    expect(submissions!.single.type, ProductSubmissionType.missingProduct);
    expect(submissions.single.status, ProductSubmissionStatus.pendingUpload);
  });

  testWidgets('제품 정보 요청은 서버 접수 상태로 동기화된다', (tester) async {
    final now = DateTime(2026, 6, 11);
    await dataRepository.saveProductSubmissions([
      ProductSubmission(
        id: 'submission-sync',
        type: ProductSubmissionType.missingProduct,
        title: '새 제품 정보 요청',
        details: '모델명을 찾을 수 없어요.',
        createdAt: now,
        updatedAt: now,
        status: ProductSubmissionStatus.pendingUpload,
      ),
    ]);
    const submissionRepository = MemoryProductSubmissionRepository();
    await pumpApp(
      tester,
      dataRepository,
      submissionRepository: submissionRepository,
    );

    await tester.scrollUntilVisible(
      find.text('요청 내역'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('요청 내역'));
    await tester.pumpAndSettle();

    expect(find.text('제품 정보 요청'), findsOneWidget);
    expect(find.text('접수'), findsOneWidget);
    final saved = await dataRepository.loadProductSubmissions();
    expect(saved!.single.trackingToken, 'tracking-submission-sync');
    expect(saved.single.status, ProductSubmissionStatus.received);
  });

  testWidgets('이전 단계로 돌아가도 제품 입력값이 유지된다', (tester) async {
    seedSampleData(dataRepository);
    await pumpApp(tester, dataRepository);

    await tester.tap(find.text('내 제품'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제품 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('모델명을 몰라요'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '제품 종류'),
      '식기세척기',
    );
    await tester.tap(find.widgetWithText(FilledButton, '이 정보로 계속'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('이전'));
    await tester.pumpAndSettle();

    expect(find.text('식기세척기'), findsOneWidget);
  });

  testWidgets('초기 상태에서는 공간 설정부터 안내한다', (tester) async {
    await pumpApp(tester, dataRepository);

    await tester.tap(find.text('내 제품'));
    await tester.pumpAndSettle();

    expect(find.text('제품을 담을 공간을 먼저 만들까요?'), findsOneWidget);
    expect(find.text('선택한 공간 만들기'), findsOneWidget);
  });
}

Future<void> pumpApp(
  WidgetTester tester,
  ProductDataRepository dataRepository, {
  ProductSubmissionRepository submissionRepository =
      const MemoryProductSubmissionRepository(),
}) async {
  await tester.pumpWidget(
    CleanUpApp(
      dataRepository: dataRepository,
      catalogRepository: const LocalProductCatalogRepository(),
      submissionRepository: submissionRepository,
    ),
  );
  await tester.pumpAndSettle();
}

void seedSampleData(MemoryProductDataRepository dataRepository) {
  dataRepository.saveSpaces(productSpaces);
  dataRepository.saveUserProducts(mockZoneItems);
  dataRepository.saveCareRecords(careRecords);
}

class MemoryProductDataRepository extends ProductDataRepository {
  List<ProductSpace>? _spaces;
  List<ZoneItem>? _products;
  List<CareRecord>? _records;
  List<ProductSearchRequest>? _searchRequests;
  List<ProductSubmission>? _submissions;
  List<String> _recentSearches = [];

  @override
  Future<List<ProductSpace>?> loadSpaces() async => _spaces?.toList();

  @override
  Future<void> saveSpaces(List<ProductSpace> spaces) async {
    _spaces = spaces.toList();
  }

  @override
  Future<List<ZoneItem>?> loadUserProducts() async => _products?.toList();

  @override
  Future<void> saveUserProducts(List<ZoneItem> products) async {
    _products = products.toList();
  }

  @override
  Future<List<CareRecord>?> loadCareRecords() async => _records?.toList();

  @override
  Future<void> saveCareRecords(List<CareRecord> records) async {
    _records = records.toList();
  }

  @override
  Future<List<ProductSearchRequest>?> loadProductSearchRequests() async {
    return _searchRequests?.toList();
  }

  @override
  Future<void> saveProductSearchRequests(
    List<ProductSearchRequest> requests,
  ) async {
    _searchRequests = requests.toList();
  }

  @override
  Future<List<ProductSubmission>?> loadProductSubmissions() async {
    return _submissions?.toList();
  }

  @override
  Future<void> saveProductSubmissions(
    List<ProductSubmission> submissions,
  ) async {
    _submissions = submissions.toList();
  }

  @override
  Future<List<String>> loadRecentProductSearches() async {
    return _recentSearches.toList();
  }

  @override
  Future<void> saveRecentProductSearches(List<String> searches) async {
    _recentSearches = searches.toList();
  }
}

class MemoryProductSubmissionRepository implements ProductSubmissionRepository {
  const MemoryProductSubmissionRepository();

  @override
  Future<ProductSubmission> submit(ProductSubmission submission) async {
    return submission.copyWith(
      trackingToken: 'tracking-${submission.id}',
      updatedAt: DateTime(2026, 6, 11, 12),
      status: ProductSubmissionStatus.received,
      statusMessage: '운영팀 접수 대기열에 등록됐어요.',
    );
  }

  @override
  Future<ProductSubmission> refresh(ProductSubmission submission) async {
    return submission;
  }
}
