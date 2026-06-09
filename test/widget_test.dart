import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clean_up/app.dart';
import 'package:clean_up/data/mock_product_data.dart';
import 'package:clean_up/data/mock_zone_items.dart';
import 'package:clean_up/data/product_catalog.dart';
import 'package:clean_up/models/care_record.dart';
import 'package:clean_up/models/community_post.dart';
import 'package:clean_up/models/product_space.dart';
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

  testWidgets('모델 검색으로 카탈로그 제품을 등록할 수 있다', (tester) async {
    seedSampleData(dataRepository);
    await pumpApp(tester, dataRepository);

    await tester.tap(find.text('내 제품'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제품 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제품 등록'));
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
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, '추가'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.widgetWithText(FilledButton, '추가'));
    await tester.pumpAndSettle();

    final products = await dataRepository.loadUserProducts();
    final registered = products!.lastWhere(
      (item) => item.id.startsWith('custom-'),
    );
    expect(registered.catalogProductId, 'eco-up-dcs-hm4ag-w');
    expect(registered.modelName, 'DCS-HM4AG-W');
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
}
