import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clean_up/app.dart';
import 'package:clean_up/data/mock_product_data.dart';
import 'package:clean_up/data/mock_zone_items.dart';
import 'package:clean_up/data/product_catalog.dart';
import 'package:clean_up/models/care_record.dart';
import 'package:clean_up/models/community_post.dart';
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

  test('카탈로그 제품 ID와 출처 정보는 저장 후에도 유지된다', () {
    final item = productCatalog.first.toZoneItem(
      id: 'saved-product',
      zoneId: 'zone-1',
    );
    final restored = ZoneItem.fromJson(item.toJson());

    expect(restored.catalogProductId, productCatalog.first.id);
    expect(restored.matchLevelLabel, '모델명 일치');
    expect(restored.sourceTitle, contains('다나와'));
    expect(restored.productSpecs, contains('처리용량: 1kg'));
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

  testWidgets('제품 관리형 앱의 주요 화면을 표시한다', (tester) async {
    seedSampleData(dataRepository);
    await pumpApp(tester, dataRepository);

    expect(find.text('홈'), findsWidgets);
    expect(find.text('내 제품'), findsOneWidget);
    expect(find.text('기록'), findsOneWidget);
    expect(find.text('자랑'), findsOneWidget);
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
    await tester.tap(find.widgetWithText(FilledButton, '완료'));
    await tester.pumpAndSettle();

    final records = await dataRepository.loadCareRecords();
    expect(records!.first.title, '냉장고 관리 완료');
    expect(records.first.spaceName, '주방');
    expect(records.first.spaceId, 'zone-1');
    expect(records.first.productId, 'kitchen-refrigerator');
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
  List<CommunityPost>? _posts;
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
  Future<List<CommunityPost>?> loadCommunityPosts() async => _posts?.toList();

  @override
  Future<void> saveCommunityPosts(List<CommunityPost> posts) async {
    _posts = posts.toList();
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
