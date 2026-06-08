import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clean_up/app.dart';
import 'package:clean_up/data/mock_cleaning_data.dart';
import 'package:clean_up/data/mock_zone_items.dart';
import 'package:clean_up/data/product_catalog.dart';
import 'package:clean_up/models/cleaning_record.dart';
import 'package:clean_up/models/cleaning_task.dart';
import 'package:clean_up/models/cleaning_zone.dart';
import 'package:clean_up/models/community_post.dart';
import 'package:clean_up/models/zone_item.dart';
import 'package:clean_up/repositories/cleaning_data_repository.dart';
import 'package:clean_up/repositories/cleaning_task_repository.dart';

void main() {
  late MemoryCleaningTaskRepository taskRepository;
  late MemoryCleaningDataRepository dataRepository;

  setUp(() {
    taskRepository = MemoryCleaningTaskRepository();
    dataRepository = MemoryCleaningDataRepository();
  });

  test('제품 카탈로그는 모델명과 별칭으로 검색할 수 있다', () {
    expect(
      searchProductCatalog('DCS-HM4AG-W').single.modelName,
      'DCS-HM4AG-W',
    );
    expect(searchProductCatalog('음처기').single.brand, '에코업');
  });

  test('제품 출처 정보는 JSON 저장 후에도 유지된다', () {
    final item = productCatalog.first.toZoneItem(
      id: 'saved-product',
      zoneId: 'zone-1',
    );
    final restored = ZoneItem.fromJson(item.toJson());

    expect(restored.matchLevelLabel, '모델명 일치');
    expect(restored.sourceTitle, contains('다나와'));
    expect(restored.productSpecs, contains('처리용량: 1kg'));
  });

  testWidgets('제품 관리형 홈 화면이 표시된다', (tester) async {
    seedSampleData(taskRepository, dataRepository);
    await pumpApp(tester, taskRepository, dataRepository);

    expect(find.text('홈'), findsWidgets);
    expect(find.text('내 제품'), findsOneWidget);
    expect(find.text('기록'), findsOneWidget);
    expect(find.text('자랑'), findsOneWidget);
    expect(find.text('제품 관리 도우미'), findsOneWidget);
    expect(find.text('등록 제품'), findsOneWidget);
    expect(find.text('추천용품'), findsOneWidget);
  });

  testWidgets('홈에서 제품 상세 관리법을 열 수 있다', (tester) async {
    seedSampleData(taskRepository, dataRepository);
    await pumpApp(tester, taskRepository, dataRepository);

    await tester.scrollUntilVisible(
      find.text('에코업 음식물처리기'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('에코업 음식물처리기'));
    await tester.pumpAndSettle();

    expect(find.text('DCS-HM4AG-W'), findsOneWidget);
    expect(find.text('제품 정보 수정'), findsOneWidget);
    expect(find.textContaining('공식'), findsWidgets);
  });

  testWidgets('내 제품 탭에서 공간별 제품을 볼 수 있다', (tester) async {
    seedSampleData(taskRepository, dataRepository);
    await pumpApp(tester, taskRepository, dataRepository);

    await tester.tap(find.text('내 제품'));
    await tester.pumpAndSettle();

    expect(find.text('내 제품'), findsWidgets);
    expect(find.text('주방'), findsOneWidget);
    expect(find.text('거실'), findsOneWidget);

    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();

    expect(find.text('에코업 음식물처리기'), findsOneWidget);
    expect(find.text('냉장고'), findsOneWidget);
    expect(find.text('항목 추가'), findsOneWidget);
  });

  testWidgets('모델명을 검색해 출처가 있는 제품을 등록할 수 있다', (tester) async {
    seedSampleData(taskRepository, dataRepository);
    await pumpApp(tester, taskRepository, dataRepository);

    await tester.tap(find.text('내 제품'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('항목 추가'));
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

    final items = await dataRepository.loadZoneItems();
    final registered = items!.lastWhere(
      (item) => item.id.startsWith('custom-'),
    );
    expect(registered.modelName, 'DCS-HM4AG-W');
    expect(registered.matchLevelLabel, '모델명 일치');
    expect(registered.sourceUrl, isNotEmpty);
    expect(registered.productSpecs, contains('소음: 약 40dB'));
  });

  testWidgets('처음 사용하는 상태에서는 제품 추가 안내가 나온다', (tester) async {
    await pumpApp(tester, taskRepository, dataRepository);

    await tester.scrollUntilVisible(
      find.text('아직 등록된 제품이 없어요'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('아직 등록된 제품이 없어요'), findsOneWidget);
    expect(find.text('내 제품 추가'), findsOneWidget);

    await tester.tap(find.text('내 제품'));
    await tester.pumpAndSettle();

    expect(find.text('제품을 담을 공간을 먼저 만들까요?'), findsOneWidget);
    expect(find.text('선택한 공간 만들기'), findsOneWidget);
  });

  testWidgets('방1 같은 새 공간을 추가할 수 있다', (tester) async {
    await pumpApp(tester, taskRepository, dataRepository);

    await tester.tap(find.text('내 제품'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('공간 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '공간 이름'),
      '방1',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '공간 설명'),
      '책상, 의자, 수납장',
    );
    await tester.tap(find.widgetWithText(FilledButton, '공간 추가').last);
    await tester.pumpAndSettle();

    final zones = await dataRepository.loadZones();
    expect(zones?.map((zone) => zone.name), contains('방1'));
  });
}

Future<void> pumpApp(
  WidgetTester tester,
  CleaningTaskRepository taskRepository,
  CleaningDataRepository dataRepository,
) async {
  await tester.pumpWidget(
    CleanUpApp(
      taskRepository: taskRepository,
      dataRepository: dataRepository,
    ),
  );
  await tester.pumpAndSettle();
}

void seedSampleData(
  MemoryCleaningTaskRepository taskRepository,
  MemoryCleaningDataRepository dataRepository,
) {
  taskRepository.saveTodayTasks(todayTasks);
  dataRepository.saveZones(cleaningZones);
  dataRepository.saveZoneItems(mockZoneItems);
  dataRepository.saveRecords(cleaningRecords);
}

class MemoryCleaningDataRepository extends CleaningDataRepository {
  List<CleaningZone>? _zones;
  List<ZoneItem>? _items;
  List<CleaningRecord>? _records;
  List<CommunityPost>? _posts;

  @override
  Future<List<CleaningZone>?> loadZones() async {
    return _zones?.toList();
  }

  @override
  Future<void> saveZones(List<CleaningZone> zones) async {
    _zones = zones.toList();
  }

  @override
  Future<List<ZoneItem>?> loadZoneItems() async {
    return _items?.toList();
  }

  @override
  Future<void> saveZoneItems(List<ZoneItem> items) async {
    _items = items.toList();
  }

  @override
  Future<List<CleaningRecord>?> loadRecords() async {
    return _records?.toList();
  }

  @override
  Future<void> saveRecords(List<CleaningRecord> records) async {
    _records = records.toList();
  }

  @override
  Future<List<CommunityPost>?> loadCommunityPosts() async {
    return _posts?.toList();
  }

  @override
  Future<void> saveCommunityPosts(List<CommunityPost> posts) async {
    _posts = posts.toList();
  }
}

class MemoryCleaningTaskRepository implements CleaningTaskRepository {
  List<CleaningTask>? _tasks;

  @override
  Future<List<CleaningTask>?> loadTodayTasks() async {
    return _tasks?.toList();
  }

  @override
  Future<void> saveTodayTasks(List<CleaningTask> tasks) async {
    _tasks = tasks.toList();
  }
}
