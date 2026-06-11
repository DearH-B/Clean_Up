import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clean_up/app.dart';
import 'package:clean_up/data/mock_product_data.dart';
import 'package:clean_up/data/mock_zone_items.dart';
import 'package:clean_up/data/product_catalog.dart';
import 'package:clean_up/data/product_care_templates.dart';
import 'package:clean_up/data/visual_product_candidates.dart';
import 'package:clean_up/models/care_record.dart';
import 'package:clean_up/models/product_space.dart';
import 'package:clean_up/models/product_search_request.dart';
import 'package:clean_up/models/zone_item.dart';
import 'package:clean_up/repositories/product_catalog_repository.dart';
import 'package:clean_up/repositories/product_data_repository.dart';

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
    expect(products.single.sourceTitle, '이전 버전에서 저장한 출처');
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
    expect(find.text('제품 관리 도우미'), findsOneWidget);
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

    await tester.tap(find.widgetWithText(FilledButton, '완료'));
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

    await tester.tap(find.text('필터 교체'));
    await tester.pumpAndSettle();
    final suppliesField =
        find.byKey(const ValueKey('care-record-supplies'));
    await tester.ensureVisible(suppliesField);
    await tester.enterText(suppliesField, '교체 필터, 마른 천');
    final resultField = find.byKey(const ValueKey('care-record-result'));
    await tester.ensureVisible(resultField);
    await tester.enterText(resultField, '필터 상태 정상');
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
    expect(saved.usedSupplies, ['교체 필터', '마른 천']);
    expect(saved.result, '필터 상태 정상');
    expect(saved.note, '다음에는 안쪽 먼지도 확인');
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
    await tester.tap(find.text('이미지와 연식으로 제품 찾기'));
    await tester.pumpAndSettle();

    expect(find.text('외형으로 제품 찾기'), findsOneWidget);
    expect(find.textContaining('4도어 냉장고'), findsOneWidget);
    await tester.tap(find.text('이 제품과 비슷해요').first);
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
    final modelButton = find.widgetWithText(OutlinedButton, '모델 선택');
    await tester.ensureVisible(modelButton);
    await tester.pumpAndSettle();
    await tester.tap(modelButton);
    await tester.pumpAndSettle();

    expect(find.text('RF85C90F1AP'), findsOneWidget);
    await tester.tap(find.text('RF85C90F1AP'));
    await tester.pumpAndSettle();

    expect(find.text('선택한 모델: RF85C90F1AP'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '이 정보로 계속'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '등록 내용 확인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('나중에 보기'));
    await tester.pumpAndSettle();

    final products = await dataRepository.loadUserProducts();
    expect(products!.single.manufacturer, '삼성전자');
    expect(products.single.modelName, 'RF85C90F1AP');
    expect(products.single.visualCandidateId, isNull);
  });

  testWidgets('모델 선택 화면을 반복해서 열고 닫아도 오류가 발생하지 않는다', (tester) async {
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

    final modelButton = find.widgetWithText(OutlinedButton, '모델 선택');
    await tester.ensureVisible(modelButton);
    await tester.pumpAndSettle();
    await tester.tap(modelButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('RF85C90F1AP'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final selectedButton = find.widgetWithText(OutlinedButton, 'RF85C90F1AP');
    await tester.ensureVisible(selectedButton);
    await tester.pumpAndSettle();
    await tester.tap(selectedButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('모델명을 모르겠어요'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(OutlinedButton, '모델 선택'), findsOneWidget);
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
  ProductDataRepository dataRepository,
) async {
  await tester.pumpWidget(
    CleanUpApp(
      dataRepository: dataRepository,
      catalogRepository: const LocalProductCatalogRepository(),
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
  Future<List<String>> loadRecentProductSearches() async {
    return _recentSearches.toList();
  }

  @override
  Future<void> saveRecentProductSearches(List<String> searches) async {
    _recentSearches = searches.toList();
  }
}
