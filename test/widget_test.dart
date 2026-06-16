import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clean_up/app.dart';
import 'package:clean_up/data/mock_product_data.dart';
import 'package:clean_up/data/mock_zone_items.dart';
import 'package:clean_up/data/product_catalog.dart';
import 'package:clean_up/data/product_care_templates.dart';
import 'package:clean_up/data/product_consumable_defaults.dart';
import 'package:clean_up/data/product_diagnostics.dart';
import 'package:clean_up/data/visual_product_candidates.dart';
import 'package:clean_up/models/care_record.dart';
import 'package:clean_up/models/catalog_metadata.dart';
import 'package:clean_up/models/product_space.dart';
import 'package:clean_up/models/product_search_request.dart';
import 'package:clean_up/models/product_submission.dart';
import 'package:clean_up/models/product_consumable.dart';
import 'package:clean_up/models/product_diagnostic.dart';
import 'package:clean_up/models/zone_item.dart';
import 'package:clean_up/repositories/product_catalog_repository.dart';
import 'package:clean_up/repositories/product_data_repository.dart';
import 'package:clean_up/repositories/product_diagnostic_repository.dart';
import 'package:clean_up/repositories/product_submission_repository.dart';
import 'package:clean_up/screens/model_selection_screen.dart';
import 'package:clean_up/screens/product_diagnostic_screen.dart';
import 'package:clean_up/screens/product_registration_screen.dart';
import 'package:clean_up/screens/data_management_screen.dart';
import 'package:clean_up/screens/settings_screen.dart';
import 'package:clean_up/screens/zone_item_detail_screen.dart';
import 'package:clean_up/theme/app_theme.dart';
import 'package:clean_up/utils/product_label_parser.dart';
import 'package:clean_up/widgets/zone_item_tile.dart';

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

  test('제품 모델명 오타 한두 글자도 유사 검색한다', () {
    expect(
      searchProductCatalog('DCS-HM4AG-X').first.modelName,
      'DCS-HM4AG-W',
    );
  });

  test('제품 라벨 OCR 문장에서 모델명 후보를 우선 추출한다', () {
    final candidates = extractProductLabelCandidates(
      'SAMSUNG\nMODEL CODE: RF85C90F1AP\n220V 60Hz',
    );

    expect(candidates.first.value, 'RF85C90F1AP');
    expect(candidates.map((item) => item.value), isNot(contains('220V')));
    expect(candidates.map((item) => item.value), isNot(contains('60HZ')));
  });

  test('모델명 표기가 다음 줄에 있어도 후보로 추출한다', () {
    final candidates = extractProductLabelCandidates(
      '모델명\nDCS-HM4AG-W\n정격전압 220V',
    );

    expect(candidates.first.value, 'DCS-HM4AG-W');
  });

  test('제품 문제 확인은 위험 증상을 사용 중단으로 우선 분류한다', () {
    final refrigerator = diagnosticsForProduct('냉장고');
    final leak =
        refrigerator.firstWhere((item) => item.id == 'refrigerator-water');

    expect(leak.outcome, DiagnosticOutcome.stopUsing);
    expect(leak.requiresStop, isTrue);
    expect(leak.safeAction, contains('사용을 중단'));
  });

  test('세면대 문제는 물때와 머리카락 막힘의 서로 다른 해결책을 제공한다', () {
    final diagnostics = diagnosticsForProduct('세면대');
    final scale = diagnostics.firstWhere(
      (item) => item.id == 'washbasin-scale',
    );
    final clog = diagnostics.firstWhere(
      (item) => item.id == 'washbasin-hair-clog',
    );

    expect(scale.steps.join(' '), contains('물때'));
    expect(scale.tools, contains('극세사 천'));
    expect(scale.recommendedProducts, isNotEmpty);
    expect(clog.steps.join(' '), contains('머리카락'));
    expect(clog.tools, contains('플라스틱 배수구 클리너'));
    expect(clog.caution, contains('섞지 마세요'));
  });

  test('생활 문제 데이터는 JSON 응답을 앱 모델로 변환한다', () {
    final source = diagnosticsForProduct('세면대').first;
    final restored = ProductDiagnostic.fromJson(source.toJson());

    expect(restored.id, source.id);
    expect(restored.outcome, source.outcome);
    expect(restored.reviewStatus, source.reviewStatus);
    expect(
        restored.recommendedProducts.length, source.recommendedProducts.length);
  });

  test('공식 진단 출처는 JSON 변환 후에도 유지된다', () {
    final diagnostic = ProductDiagnostic.fromJson({
      'id': 'verified-guide',
      'symptom': '공식 자료 확인',
      'question': '설명서를 확인했나요?',
      'safeAction': '공식 안내를 따라주세요.',
      'outcome': 'checkManual',
      'reviewStatus': 'verified',
      'basisType': 'manufacturerGuide',
      'sourceTitle': '공식 사용설명서',
      'reviewedAt': '2026-06-15',
      'applicableMaterials': ['해당 제품군'],
      'sources': [
        {
          'id': 'official-manual',
          'title': '제조사 공식 사용설명서',
          'url': 'https://example.com/manual',
          'publisher': '제조사',
          'type': 'officialManual',
          'checkedAt': '2026-06-15',
          'isOfficial': true,
          'supports': ['안전 주의사항'],
        },
      ],
    });
    final restored = ProductDiagnostic.fromJson(diagnostic.toJson());

    expect(restored.reviewStatus, DiagnosticReviewStatus.verified);
    expect(restored.sources, hasLength(1));
    expect(restored.sources.single.isOfficial, isTrue);
    expect(restored.sources.single.type, 'officialManual');
  });

  test('생활 문제 서버에 연결할 수 없으면 내장 안내를 사용한다', () async {
    const repository = RemoteFirstProductDiagnosticRepository(
      baseUrl: 'http://127.0.0.1:1',
    );

    final results = await repository.diagnosticsFor('냉장고');

    expect(results, hasLength(greaterThanOrEqualTo(3)));
    expect(results.any((item) => item.id == 'refrigerator-water'), isTrue);
  });

  test('생활 문제 서버 응답이 있으면 내장 안내보다 우선 사용한다', () async {
    final repository = RemoteFirstProductDiagnosticRepository(
      loader: (uri) async {
        expect(uri.queryParameters['productType'], '냉장고');
        return {
          'items': [
            {
              'id': 'server-refrigerator-guide',
              'symptom': '서버에서 갱신한 증상',
              'question': '서버 안내를 확인했나요?',
              'safeAction': '서버의 검수된 안내를 따라주세요.',
              'outcome': 'checkManual',
              'warningSigns': <String>[],
              'steps': ['공식 설명서를 확인해요.'],
              'tools': <String>[],
              'recommendedProducts': <Object>[],
              'reviewStatus': 'reviewed',
              'basisType': 'generalSafety',
              'sourceTitle': '테스트 검수 자료',
              'reviewedAt': '2026-06-15',
              'applicableMaterials': ['제품 설명서 확인'],
            },
          ],
          'total': 1,
          'productType': '냉장고',
          'version': 'test',
        };
      },
    );

    final results = await repository.diagnosticsFor('냉장고');

    expect(results, hasLength(1));
    expect(results.single.id, 'server-refrigerator-guide');
    expect(results.single.reviewStatus, DiagnosticReviewStatus.reviewed);
  });

  test('등록 가능한 모든 표준 제품 종류에 생활 문제 해결 정보가 연결된다', () {
    const productTypes = [
      '냉장고',
      '음식물처리기',
      '전자레인지',
      '식기세척기',
      '정수기',
      '싱크대',
      'TV',
      '소파',
      '테이블',
      '가습기',
      '공기청정기',
      '에어컨',
      '침대',
      '러그',
      '세면대',
      '변기',
      '샤워부스',
      '욕조',
      '환풍기',
      '욕실장',
      '매트리스',
      '옷장',
      '화장대',
      '세탁기',
      '건조기',
      '세탁조',
      '빨래건조대',
      '책상',
      '의자',
      '모니터',
      '컴퓨터',
      '책장',
      '신발장',
      '현관문',
      '중문',
      '현관 매트',
      '창문',
      '방충망',
      '실외기',
      '수납장',
      '김치냉장고',
      '인덕션',
      '가스레인지',
      '오븐',
      '커피머신',
      '전기밥솥',
      '믹서기',
      '토스터',
      '제습기',
      '선풍기',
      '로봇청소기',
      '청소기',
      '스피커',
      '프로젝터',
      '게임기',
      '공유기',
      '프린터',
      '안마의자',
      '전기장판',
      '협탁',
      '식탁',
      '서랍장',
      '커튼',
      '블라인드',
      '거울',
    ];

    for (final productType in productTypes) {
      final diagnostics = diagnosticsForProduct(productType);
      expect(
        diagnostics,
        hasLength(greaterThanOrEqualTo(3)),
        reason: '$productType 문제 정보가 부족해요.',
      );
      expect(
        diagnostics.any((item) => item.id.startsWith('generic-')),
        isFalse,
        reason: '$productType이 범용 문제 정보로 연결됐어요.',
      );
      expect(
        diagnostics.any(
          (item) =>
              item.steps.isNotEmpty &&
              item.tools.isNotEmpty &&
              item.recommendedProducts.isNotEmpty,
        ),
        isTrue,
        reason: '$productType에 대처 순서·도구·제품 추천이 모두 있는 문제가 없어요.',
      );
      for (final diagnostic in diagnostics) {
        expect(diagnostic.sourceTitle, isNotEmpty);
        expect(diagnostic.reviewedAt, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
        expect(diagnostic.applicableMaterials, isNotEmpty);
      }
    }
  });

  testWidgets('세면대 문제 결과에 대처 순서와 도구 및 제품 추천을 표시한다', (tester) async {
    const item = ZoneItem(
      id: 'sink-1',
      zoneId: 'bathroom',
      name: '세면대',
      type: ZoneItemType.fixture,
      summary: '욕실 세면대',
      frequency: '필요할 때',
      supplies: [],
      cautions: [],
      steps: [],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const ProductDiagnosticScreen(item: item),
      ),
    );

    await tester.tap(find.text('하얀 물때·비누때가 보여요'));
    await tester.pump();
    await tester.tap(find.text('네'));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('대처 순서'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('대처 순서'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('제품 추천'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('필요한 도구'), findsOneWidget);
    expect(find.text('제품 추천'), findsOneWidget);
    expect(find.textContaining('홈스타'), findsOneWidget);
    expect(find.text('판매처 검색'), findsWidgets);
    expect(find.text('광고 아님'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('안전 편집 초안'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('일반 안전 원칙 · 2026-06-15 검토'), findsOneWidget);
  });

  testWidgets('서버 안내가 늦게 도착해도 사용자의 진단 선택을 유지한다', (tester) async {
    const item = ZoneItem(
      id: 'sink-delayed',
      zoneId: 'bathroom',
      name: '세면대',
      type: ZoneItemType.fixture,
      summary: '욕실 세면대',
      frequency: '필요할 때',
      supplies: [],
      cautions: [],
      steps: [],
    );
    final repository = DeferredProductDiagnosticRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ProductDiagnosticScreen(
          item: item,
          diagnosticRepository: repository,
        ),
      ),
    );

    await tester.tap(find.text('하얀 물때·비누때가 보여요'));
    await tester.pump();
    expect(
      find.text('표면이 일반 도기이고 금속 수전의 도금이 벗겨지거나 갈라진 곳은 없나요?'),
      findsOneWidget,
    );

    repository.complete(diagnosticsForProduct('세면대'));
    await tester.pump();

    expect(
      find.text('표면이 일반 도기이고 금속 수전의 도금이 벗겨지거나 갈라진 곳은 없나요?'),
      findsOneWidget,
    );
    expect(find.text('현재 상태를 확인하세요'), findsOneWidget);
  });

  testWidgets('공식 확인 진단은 연결된 제조사 출처를 표시한다', (tester) async {
    const item = ZoneItem(
      id: 'verified-refrigerator',
      zoneId: 'kitchen',
      name: '냉장고',
      type: ZoneItemType.appliance,
      summary: '냉장고',
      frequency: '필요할 때',
      supplies: [],
      cautions: [],
      steps: [],
    );
    final diagnostic = ProductDiagnostic.fromJson({
      'id': 'verified-refrigerator-guide',
      'symptom': '문이 잘 닫히지 않아요',
      'question': '패킹을 확인했나요?',
      'safeAction': '공식 설명서의 패킹 관리 방법을 확인하세요.',
      'outcome': 'selfCare',
      'reviewStatus': 'verified',
      'basisType': 'manufacturerGuide',
      'sourceTitle': '삼성전자 공식 사용설명서',
      'reviewedAt': '2026-06-15',
      'applicableMaterials': ['RF9000F 계열'],
      'sources': [
        {
          'id': 'samsung-manual',
          'title': '삼성전자 RF9000F 계열 공식 사용설명서',
          'url': 'https://example.com/samsung-manual',
          'publisher': '삼성전자',
          'type': 'officialManual',
          'checkedAt': '2026-06-15',
          'isOfficial': true,
          'supports': ['문과 패킹 관리'],
        },
      ],
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ProductDiagnosticScreen(
          item: item,
          diagnosticRepository: StaticProductDiagnosticRepository(
            [diagnostic],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('문이 잘 닫히지 않아요'));
    await tester.pump();
    await tester.tap(find.text('네'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('공식 근거 1건'),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('공식 자료 확인'), findsOneWidget);
    expect(find.text('공식 근거 1건'), findsOneWidget);
    expect(find.text('삼성전자 RF9000F 계열 공식 사용설명서'), findsOneWidget);
  });

  testWidgets('제품 목록은 미정 일정을 숨기고 문제 해결 바로가기를 제공한다', (tester) async {
    var problemSolverOpened = false;
    const item = ZoneItem(
      id: 'sink-tile',
      zoneId: 'bathroom',
      name: '세면대',
      type: ZoneItemType.fixture,
      summary: '욕실 세면대',
      frequency: '필요할 때',
      supplies: [],
      cautions: [],
      steps: [],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: ZoneItemTile(
            item: item,
            onTap: () {},
            onSolveProblem: () => problemSolverOpened = true,
          ),
        ),
      ),
    );

    expect(find.text('다음 미정'), findsNothing);
    expect(find.byIcon(Icons.wash_outlined), findsOneWidget);
    await tester.tap(find.byTooltip('문제 해결'));
    expect(problemSolverOpened, isTrue);
  });

  testWidgets('공식 링크 실행 예외가 나면 주소 복구 안내를 표시한다', (tester) async {
    final item = searchProductCatalog('M875GBB231').single.toZoneItem(
          id: 'lg-refrigerator',
          zoneId: 'kitchen',
        );
    final diagnostic = diagnosticsForProduct(item.name).first;

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDiagnosticScreen(
          item: item,
          linkLauncher: (_) async => throw Exception('link unavailable'),
        ),
      ),
    );

    await tester.tap(find.text(diagnostic.symptom));
    await tester.pump();
    await tester.tap(find.text('아니요 / 모르겠어요'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('공식 설명서 확인'),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('공식 설명서 확인'));
    await tester.pump();

    expect(
      find.text('연결할 수 없어요. 주소나 전화번호를 복사해 다시 확인할 수 있어요.'),
      findsOneWidget,
    );
    expect(find.text('복사'), findsOneWidget);
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

  test('삼성 세탁기 3개 모델은 공식 설명서가 연결된 검수 카탈로그다', () {
    const models = ['WF25CB8895BW', 'WF25DG8650BW', 'WF25DG8250BW'];

    for (final modelName in models) {
      final product = findCatalogEntry(
        categoryName: '세탁기',
        brand: '삼성전자',
        modelName: modelName,
      );

      expect(product, isNotNull, reason: modelName);
      expect(product!.reviewStatus, 'verified');
      expect(product.matchLevelLabel, '공식 설명서 확인 모델');
      expect(product.officialManualUrl, contains('downloadcenter.samsung.com'));
      expect(product.imageUrl, contains('images.samsung.com'));
      expect(product.releaseYear, isNotNull);
      expect(product.steps.join(' '), contains('배수필터'));
      expect(product.steps.join(' '), contains('무세제통세척'));
    }
  });

  test('신규 삼성 가전 15개 모델은 공식 자료와 제품군별 관리법이 연결된다', () {
    const groups = {
      '에어컨': (
        ['AF60F17D11WRT', 'AF70F19D11BRT', 'AF90H19D35WRT'],
        ['필터', '실외기'],
      ),
      '공기청정기': (
        ['AP90H10198UDD', 'AP90H03163UGD', 'AP70F06103RVD'],
        ['필터', '흡입구'],
      ),
      '식기세척기': (
        ['DW80F71Y1UEWS', 'DW90F79F1USWS', 'DW80F73Y1UEWS'],
        ['필터', '분사 노즐'],
      ),
      '건조기': (
        ['DV21DG8200BV', 'DV80H20DDW', 'DV90F22CDS'],
        ['보풀 필터', '열교환기'],
      ),
      '청소기': (
        ['VS28D950ACB', 'VS90F40CNK', 'VS90F40CSK'],
        ['먼지통', '브러시'],
      ),
    };

    for (final MapEntry(key: categoryName, value: group) in groups.entries) {
      final (models, careTerms) = group;
      for (final modelName in models) {
        final product = findCatalogEntry(
          categoryName: categoryName,
          brand: '삼성전자',
          modelName: modelName,
        );

        expect(product, isNotNull, reason: '$categoryName $modelName');
        expect(product!.reviewStatus, 'verified');
        expect(product.matchLevelLabel, '공식 설명서 확인 모델');
        expect(
            product.officialManualUrl, contains('downloadcenter.samsung.com'));
        expect(product.imageUrl, contains('images.samsung.com'));
        expect(product.releaseYear, isNotNull);
        expect(product.sources, hasLength(2));
        expect(product.steps.length, greaterThanOrEqualTo(5));
        for (final term in careTerms) {
          expect(product.steps.join(' '), contains(term), reason: modelName);
        }
      }
    }
  });

  test('삼성 확장 배치 29개 모델은 공식 자료와 제품군별 관리법이 연결된다', () {
    const groups = {
      '냉장고': (
        ['RM70F64Q1XJ', 'RM90F91D1W', 'RM90H64P2W', 'RR40C7895AP'],
        ['선반', '도어 패킹'],
      ),
      '김치냉장고': (
        [
          'RK70F49D1A',
          'RK80F42C2A',
          'RK80F58B1A',
          'RQ33DB74E1AP',
          'RQ34C7915AP',
          'RP20C3111EG',
        ],
        ['김치통', '저장실'],
      ),
      '세탁기': (
        [
          'WA30DG2120EE',
          'WA80F19SKB',
          'WD90H25AHS',
          'WD99F25AHR',
          'WF90F25ADT',
        ],
        ['세제함', '통세척'],
      ),
      '에어컨': (
        [
          'AF60F19D12WRT',
          'AF70F17D24WRT',
          'AF80F18D25WRT',
          'AF90H25D36WRT',
          'AR60F11D11WT',
        ],
        ['필터', '실외기'],
      ),
      '식기세척기': (
        ['DW99F79E1B00S', 'DW99F79E1UHCS'],
        ['필터', '분사 노즐'],
      ),
      '인덕션': (
        ['CC80H63G1HS', 'CC99H84JAD', 'NZ62DG300CFW'],
        ['잔열', '상판'],
      ),
      '청소기': (
        ['VR90F01SAG', 'VS15A680AEW', 'VS90F40CSG'],
        ['먼지통', '센서'],
      ),
      '건조기': (
        ['DV90F22CDT'],
        ['보풀 필터', '열교환기'],
      ),
    };

    for (final MapEntry(key: categoryName, value: group) in groups.entries) {
      final (models, careTerms) = group;
      for (final modelName in models) {
        final product = findCatalogEntry(
          categoryName: categoryName,
          brand: '삼성전자',
          modelName: modelName,
        );

        expect(product, isNotNull, reason: '$categoryName $modelName');
        expect(product!.reviewStatus, 'verified');
        expect(product.matchLevelLabel, '공식 설명서 확인 모델');
        expect(
            product.officialManualUrl, contains('downloadcenter.samsung.com'));
        expect(product.imageUrl, contains('images.samsung.com'));
        expect(product.releaseYear, isNotNull);
        expect(product.sources, hasLength(2));
        expect(product.steps.length, greaterThanOrEqualTo(5));
        for (final term in careTerms) {
          expect(product.steps.join(' '), contains(term), reason: modelName);
        }
      }
    }
  });

  test('첫 출시 기준인 공식 확인 정확 모델 50개를 확보했다', () {
    final verifiedModels = productCatalog
        .where(
          (product) =>
              product.reviewStatus == 'verified' &&
              product.modelName.trim().isNotEmpty,
        )
        .toList();

    expect(verifiedModels.length, greaterThanOrEqualTo(50));
    expect(
      verifiedModels.map((product) => product.modelName).toSet().length,
      verifiedModels.length,
    );
    expect(
      verifiedModels.every(
        (product) =>
            product.sources.any(
              (source) => source.type == ProductSourceType.officialManual,
            ) &&
            product.sources.any(
              (source) => source.type == ProductSourceType.officialProduct,
            ),
      ),
      isTrue,
    );
  });

  test('LG 정확 모델 5종은 공식 설명서까지 연결된다', () {
    const verifiedModels = {
      'M875GBB231',
      'RG19GN',
      'AS355NSNA',
      'FX25EFE',
      'DUE4BGL1E',
    };

    for (final model in verifiedModels) {
      final item = searchProductCatalog(model).first;
      expect(item.brand, 'LG전자');
      expect(item.modelName, model);
      expect(item.reviewStatus, 'verified');
      expect(item.matchLevelLabel, '공식 설명서 확인 모델');
      expect(item.officialManualUrl, contains('gscs-manual.lge.com'));
      expect(item.imageUrl, isNotEmpty);
    }

    final pending = searchProductCatalog('FQ18GV6EE1').first;
    expect(pending.reviewStatus, 'reviewed');
    expect(pending.matchLevelLabel, '정확 모델·일반 관리법');
    expect(pending.officialManualUrl, isNull);
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

  test('정확 모델을 바꾸면 이전 모델 전용 소모품이 남지 않는다', () {
    final hybrid = findCatalogEntry(
      categoryName: '냉장고',
      brand: '삼성전자',
      modelName: 'RM80F91H1W',
    )!;
    final largeCapacity = findCatalogEntry(
      categoryName: '냉장고',
      brand: '삼성전자',
      modelName: 'RM70F90M1ZD',
    )!;
    final hybridItem = hybrid.toZoneItem(id: 'fridge', zoneId: 'kitchen');

    final changed = largeCapacity.mergeInto(hybridItem);

    expect(changed.modelName, 'RM70F90M1ZD');
    expect(changed.consumables, isEmpty);
  });

  test('카탈로그 소모품을 정리해도 사용자가 추가한 소모품은 유지한다', () {
    final hybrid = findCatalogEntry(
      categoryName: '냉장고',
      brand: '삼성전자',
      modelName: 'RM80F91H1W',
    )!;
    final largeCapacity = findCatalogEntry(
      categoryName: '냉장고',
      brand: '삼성전자',
      modelName: 'RM70F90M1ZD',
    )!;
    final hybridItem =
        hybrid.toZoneItem(id: 'fridge', zoneId: 'kitchen').copyWith(
      consumables: [
        ...hybrid.consumableDetails,
        const ProductConsumable(
          id: 'user-cleaner',
          name: '사용자 등록 세정제',
          type: ConsumableType.cleaner,
          replacementDays: 90,
          compatibilityLabel: '사용자 등록',
        ),
      ],
    );

    final changed = largeCapacity.mergeInto(hybridItem);

    expect(changed.consumables.map((item) => item.id), ['user-cleaner']);
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
      for (final model in models.where(
        (item) => const {
          'RM70F63R2A',
          'RM80F91H1W',
          'RM70F90M1ZD',
        }.contains(item.modelName),
      )) {
        expect(model.releaseYear, 2025);
        expect(model.imageUrl, isNotEmpty);
        expect(model.features, isNotEmpty);
      }
    } finally {
      await server.close(force: true);
    }
  });

  test('서버에 연결할 수 없어도 검색과 등록 후보는 내장 카탈로그를 사용한다', () async {
    final unavailable = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = unavailable.port;
    await unavailable.close(force: true);
    final repository = RemoteFirstProductCatalogRepository(
      baseUrl: 'http://127.0.0.1:$port',
    );

    final searchResults = await repository.search('M875GBB231');
    final brands = await repository.brandsFor('냉장고');
    final models = await repository.modelsFor(
      category: '냉장고',
      brand: 'LG전자',
      query: 'M875',
    );

    expect(searchResults.map((item) => item.modelName), contains('M875GBB231'));
    expect(brands, contains('LG전자'));
    expect(models.map((item) => item.modelName), contains('M875GBB231'));
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

  test('최근 본 제품은 최신 순서로 다섯 개까지 저장한다', () async {
    SharedPreferences.setMockInitialValues({});
    const repository = ProductDataRepository();

    for (var index = 0; index < 7; index++) {
      await repository.markProductViewed('product-$index');
    }
    await repository.markProductViewed('product-4');

    expect(
      await repository.loadRecentProductIds(),
      ['product-4', 'product-6', 'product-5', 'product-3', 'product-2'],
    );
  });

  test('백업 JSON으로 제품과 기록을 복원한다', () async {
    SharedPreferences.setMockInitialValues({});
    const repository = ProductDataRepository();
    await repository.saveSpaces(productSpaces);
    await repository.saveUserProducts(mockZoneItems.take(2).toList());
    await repository.saveCareRecords([
      CareRecord(
        id: 'backup-record',
        title: '냉장고 관리 완료',
        spaceName: '주방',
        completedAt: DateTime(2026, 6, 14),
        minutes: 0,
        productId: 'kitchen-refrigerator',
        productName: '냉장고',
        spaceId: 'zone-1',
      ),
    ]);
    await repository.markProductViewed('kitchen-refrigerator');

    final backup = await repository.exportBackupJson();
    await repository.saveSpaces(const []);
    await repository.saveUserProducts(const []);
    await repository.saveCareRecords(const []);

    final summary = await repository.restoreBackupJson(backup);

    expect(summary.spaceCount, productSpaces.length);
    expect(summary.productCount, 2);
    expect(summary.recordCount, 1);
    expect((await repository.loadUserProducts())!.length, 2);
    expect((await repository.loadCareRecords())!.single.id, 'backup-record');
    expect(
      await repository.loadRecentProductIds(),
      ['kitchen-refrigerator'],
    );
  });

  test('잘못된 백업은 기존 데이터를 변경하지 않는다', () async {
    SharedPreferences.setMockInitialValues({});
    const repository = ProductDataRepository();
    await repository.saveSpaces(productSpaces);

    await expectLater(
      repository.restoreBackupJson('{"schemaVersion":99}'),
      throwsFormatException,
    );

    expect((await repository.loadSpaces())!.length, productSpaces.length);
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

  testWidgets('초기 홈의 CARE INDEX는 제품이 없어도 넘치지 않는다', (tester) async {
    await tester.pumpWidget(
      CleanUpApp(
        dataRepository: dataRepository,
        catalogRepository: const LocalProductCatalogRepository(),
        submissionRepository: const MemoryProductSubmissionRepository(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('제품을 등록해볼까요?'), findsOneWidget);
    expect(find.text('제품 추가'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    expect(find.text('문제·소모품'), findsOneWidget);
    expect(find.text('기록'), findsOneWidget);
    expect(find.byTooltip('제품 정보와 공식 자료'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '관리 기록'));
    await tester.pumpAndSettle();

    final records = await dataRepository.loadCareRecords();
    expect(records!.first.title, '냉장고 관리 완료');
    expect(records.first.spaceName, '주방');
    expect(records.first.spaceId, 'zone-1');
    expect(records.first.productId, 'kitchen-refrigerator');
    expect(records.first.minutes, 0);

    await tester.tap(find.text('실행 취소'));
    await tester.pumpAndSettle();
    final undoneRecords = await dataRepository.loadCareRecords();
    expect(
      undoneRecords!.any((record) => record.id == records.first.id),
      isFalse,
    );
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

    await tester.enterText(find.byType(TextField).first, 'RM70F63R2A');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '이 모델 선택').first);
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

  testWidgets('제품 상세에서 제품을 삭제해도 이전 관리 기록은 유지된다', (tester) async {
    seedSampleData(dataRepository);
    final originalRecords = await dataRepository.loadCareRecords();
    await pumpApp(tester, dataRepository);

    await tester.tap(find.text('내 제품'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('냉장고'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('제품 관리'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제품 삭제'));
    await tester.pumpAndSettle();

    expect(find.text('제품을 삭제할까요?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '삭제'));
    await tester.pumpAndSettle();

    final products = await dataRepository.loadUserProducts();
    expect(products!.any((item) => item.name == '냉장고'), isFalse);
    final remainingRecords = await dataRepository.loadCareRecords();
    expect(
      remainingRecords!.map((record) => record.id),
      originalRecords!.map((record) => record.id),
    );
  });

  testWidgets('등록한 제품을 다른 공간으로 이동할 수 있다', (tester) async {
    seedSampleData(dataRepository);
    await pumpApp(tester, dataRepository);

    await tester.tap(find.text('내 제품'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('냉장고'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('제품 관리'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('공간 이동'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('거실').last);
    await tester.pumpAndSettle();

    final products = await dataRepository.loadUserProducts();
    final refrigerator =
        products!.firstWhere((item) => item.id == 'kitchen-refrigerator');
    expect(refrigerator.zoneId, 'zone-2');
    expect(find.text('거실 공간으로 이동했어요.'), findsOneWidget);
  });

  testWidgets('홈에서 모델명으로 등록 제품을 검색할 수 있다', (tester) async {
    seedSampleData(dataRepository);
    await pumpApp(tester, dataRepository);

    final searchField = find.widgetWithText(TextField, '내 제품 검색');
    await tester.enterText(searchField, '에코업');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.textContaining('검색 결과'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('검색 결과'), findsOneWidget);
    expect(find.text('에코업 음식물처리기'), findsOneWidget);
  });

  testWidgets('다른 탭에서 본 제품이 홈의 최근 본 제품에 표시된다', (tester) async {
    seedSampleData(dataRepository);
    await pumpApp(tester, dataRepository);

    await tester.tap(find.text('내 제품'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('냉장고'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('최근 본 제품'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('최근 본 제품'), findsOneWidget);
    expect(find.text('냉장고'), findsOneWidget);
  });

  testWidgets('기록이 없으면 검색과 필터를 숨긴다', (tester) async {
    await dataRepository.saveSpaces(productSpaces);
    await dataRepository.saveUserProducts(mockZoneItems);
    await dataRepository.saveCareRecords(const []);
    await pumpApp(tester, dataRepository);

    await tester.tap(find.text('기록'));
    await tester.pumpAndSettle();

    expect(find.text('아직 관리 기록이 없어요'), findsWidgets);
    expect(find.widgetWithText(TextField, '기록 검색'), findsNothing);
    expect(find.text('모든 제품'), findsNothing);
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
    await tester.tap(find.widgetWithText(Tab, '문제·소모품'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('정수 필터'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('정수 필터'), findsOneWidget);
    final replaceButton = find.text('교체했어요').first;
    await tester.ensureVisible(replaceButton);
    await tester.pumpAndSettle();
    await tester.tap(replaceButton);
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
    await tester.tap(find.text('등록하기'));
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

  testWidgets('모델명을 몰라도 제품 종류만으로 등록할 수 있다', (tester) async {
    seedSampleData(dataRepository);
    await pumpApp(tester, dataRepository);

    await tester.tap(find.text('내 제품'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제품 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('전체 제품 종류에서 찾기'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '종류 검색'),
      '식기세척기',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, '식기세척기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('등록하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('나중에 보기'));
    await tester.pumpAndSettle();

    final products = await dataRepository.loadUserProducts();
    final registered = products!.last;
    expect(registered.name, '식기세척기');
    expect(registered.nickname, isNull);
    expect(registered.catalogProductId, isNull);
    expect(registered.frequency, contains('필터'));
    expect(registered.steps.join(' '), contains('배수구'));
    expect(registered.steps.join(' '), contains('분사 날개'));
    expect(registered.supplies, contains('제품 허용 세척제'));
  });

  testWidgets('추천 제품은 모델명이나 사진 없이 바로 등록할 수 있다', (tester) async {
    ProductRegistrationResult? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result =
                    await Navigator.of(context).push<ProductRegistrationResult>(
                  MaterialPageRoute(
                    builder: (_) => ProductRegistrationScreen(
                      space: productSpaces.first,
                      spaces: productSpaces,
                      existingProducts: const [],
                      dataRepository: dataRepository,
                      catalogRepository: const LocalProductCatalogRepository(),
                    ),
                  ),
                );
              },
              child: const Text('제품 추가'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('제품 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('냉장고'));
    await tester.pumpAndSettle();

    expect(find.text('등록하기'), findsOneWidget);
    expect(find.text('정확한 모델 추가 (선택)'), findsOneWidget);
    await tester.tap(find.text('등록하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('나중에 보기'));
    await tester.pumpAndSettle();

    expect(result?.product?.name, '냉장고');
    expect(result?.product?.modelName, isNull);
    expect(result?.product?.modelImageUrl, isNull);
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

    expect(find.text('거실 추천 종류'), findsOneWidget);
    expect(find.text('TV'), findsOneWidget);
    expect(find.text('소파'), findsOneWidget);
    expect(find.text('가습기'), findsOneWidget);
    expect(find.text('침대'), findsOneWidget);
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
    await tester.tap(find.text('정확한 모델 추가 (선택)'));
    await tester.pumpAndSettle();

    expect(find.text('내 제품 찾기'), findsOneWidget);
    await tester.tap(find.text('외형으로 찾기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('4도어 냉장고'), findsOneWidget);
    await tester.tap(find.text('비슷해요').first);
    await tester.pumpAndSettle();

    expect(find.text('유사 제품'), findsOneWidget);
    await tester.tap(find.text('등록하기'));
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

  testWidgets('외형 후보가 없는 음식물처리기는 모델 선택만 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const ModelSelectionScreen(
          categoryName: '음식물처리기',
          brand: '에코업',
          catalogRepository: LocalProductCatalogRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('외형으로 찾기'), findsNothing);
    expect(find.text('정확한 모델'), findsNothing);
    expect(find.text('DCS-HM4AG-W'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('모델명 직접 입력'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('모델명 직접 입력'), findsOneWidget);
  });

  testWidgets('외형 후보가 있는 냉장고는 두 가지 찾기 방식을 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const ModelSelectionScreen(
          categoryName: '냉장고',
          brand: '삼성전자',
          catalogRepository: LocalProductCatalogRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('정확한 모델'), findsOneWidget);
    expect(find.text('외형으로 찾기'), findsOneWidget);
    await tester.tap(find.text('외형으로 찾기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('4도어 냉장고'), findsOneWidget);
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
    final productFinderButton = find.text('정확한 모델 추가 (선택)');
    await tester.ensureVisible(productFinderButton);
    await tester.pumpAndSettle();
    await tester.tap(productFinderButton);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'RM70F63R2A');
    await tester.pumpAndSettle();
    expect(find.text('RM70F63R2A'), findsWidgets);
    expect(find.text('공식 관리법 준비됨'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, '이 모델 선택').first);
    await tester.pumpAndSettle();

    expect(find.text('선택한 모델: RM70F63R2A'), findsOneWidget);
    await tester.tap(find.text('등록하기'));
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

    final productFinderButton = find.text('정확한 모델 추가 (선택)');
    await tester.ensureVisible(productFinderButton);
    await tester.pumpAndSettle();
    await tester.tap(productFinderButton);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'RM70F63R2A');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '이 모델 선택').first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final selectedButton = find.widgetWithText(OutlinedButton, 'RM70F63R2A');
    await tester.ensureVisible(selectedButton);
    await tester.pumpAndSettle();
    await tester.tap(selectedButton);
    await tester.pumpAndSettle();
    expect(find.text('내 제품 찾기'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(OutlinedButton, 'RM70F63R2A'), findsOneWidget);
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
    final requestButton = find.text('제품 정보 추가 요청');
    await tester.ensureVisible(requestButton);
    await tester.pumpAndSettle();
    await tester.tap(requestButton);
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
      find.text('제품 정보 요청 내역'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('제품 정보 요청 내역'));
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
    await tester.tap(find.text('전체 제품 종류에서 찾기'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '종류 검색'),
      '식기세척기',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, '식기세척기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('등록하기'));
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

  testWidgets('설정에서 정책과 데이터 관리 경로를 제공한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: SettingsScreen(
          dataRepository: dataRepository,
          onDataChanged: () {},
        ),
      ),
    );

    expect(find.text('백업·복원·전체 삭제'), findsOneWidget);
    expect(find.text('개인정보 및 기기 데이터'), findsOneWidget);
    expect(find.text('제품 정보 책임 범위'), findsOneWidget);
  });

  testWidgets('설정에서 앱 기능 문제를 화면 문맥과 함께 저장한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: SettingsScreen(
          dataRepository: dataRepository,
          onDataChanged: () {},
        ),
      ),
    );

    await tester.tap(find.text('앱 기능 문제 신고'));
    await tester.pumpAndSettle();
    expect(find.text('설정 · 도움말과 피드백'), findsOneWidget);
    expect(
        find.text('무엇을 누른 뒤 문제가 생겼는지, 기대한 결과와 실제 결과를 적어주세요'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('submission-details')),
      '저장 버튼을 눌렀지만 제품 메모가 반영되지 않았어요.',
    );
    await tester.tap(find.text('요청 내역에 저장'));
    await tester.pumpAndSettle();

    final submissions = await dataRepository.loadProductSubmissions();
    expect(submissions, hasLength(1));
    expect(submissions!.single.type, ProductSubmissionType.appIssue);
    expect(
      submissions.single.screenContext,
      '설정 · 도움말과 피드백',
    );
  });

  testWidgets('설정 화면은 큰 글자에서도 렌더링된다', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(2),
          ),
          child: SettingsScreen(
            dataRepository: dataRepository,
            onDataChanged: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('설정'), findsOneWidget);
  });

  testWidgets('주요 사용자 흐름은 200% 큰 글자에서도 레이아웃 오류가 없다', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> pumpLargeText(Widget child) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(2),
            ),
            child: child,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await pumpLargeText(
      ProductRegistrationScreen(
        space: productSpaces.first,
        spaces: productSpaces,
        existingProducts: const [],
        dataRepository: dataRepository,
        catalogRepository: const LocalProductCatalogRepository(),
      ),
    );
    expect(find.text('제품 등록'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await pumpLargeText(
      ZoneItemDetailScreen(
        item: mockZoneItems.first,
        spaceId: productSpaces.first.id,
        spaceName: productSpaces.first.name,
        spaces: productSpaces,
        dataRepository: dataRepository,
        catalogRepository: const LocalProductCatalogRepository(),
      ),
    );
    expect(find.text(mockZoneItems.first.displayName), findsWidgets);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await pumpLargeText(ProductDiagnosticScreen(item: mockZoneItems.first));
    expect(find.text('문제 확인'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await pumpLargeText(
      DataManagementScreen(dataRepository: dataRepository),
    );
    expect(find.text('데이터 백업'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('핵심 탐색과 위험 결과는 접근성 의미 정보로 노출된다', (tester) async {
    final semantics = tester.ensureSemantics();
    seedSampleData(dataRepository);
    await tester.pumpWidget(
      CleanUpApp(
        dataRepository: dataRepository,
        catalogRepository: const LocalProductCatalogRepository(),
        submissionRepository: const MemoryProductSubmissionRepository(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    for (final label in ['홈', '내 제품', '기록', '설정']) {
      final node = tester.getSemantics(find.text(label).last);
      expect(node.label, contains(label));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ProductDiagnosticScreen(item: mockZoneItems.first),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('누수 흔적이 있어요'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('네'));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(
        RegExp('사용을 멈추고 전문가에게 문의하세요'),
      ),
      findsWidgets,
    );
    semantics.dispose();
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

  @override
  Future<void> clearAllUserData() async {
    _spaces = [];
    _products = [];
    _records = [];
    _searchRequests = [];
    _submissions = [];
    _recentSearches = [];
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

class DeferredProductDiagnosticRepository
    implements ProductDiagnosticRepository {
  final Completer<List<ProductDiagnostic>> _completer = Completer();

  @override
  Future<List<ProductDiagnostic>> diagnosticsFor(String productName) {
    return _completer.future;
  }

  void complete(List<ProductDiagnostic> diagnostics) {
    _completer.complete(diagnostics);
  }
}

class StaticProductDiagnosticRepository implements ProductDiagnosticRepository {
  const StaticProductDiagnosticRepository(this.diagnostics);

  final List<ProductDiagnostic> diagnostics;

  @override
  Future<List<ProductDiagnostic>> diagnosticsFor(String productName) async {
    return diagnostics;
  }
}
