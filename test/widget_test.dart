// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clean_up/app.dart';
import 'package:clean_up/data/mock_cleaning_data.dart';
import 'package:clean_up/data/mock_zone_items.dart';
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

  testWidgets('메인 화면에 청소 탭이 표시된다', (WidgetTester tester) async {
    seedSampleData(taskRepository, dataRepository);
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('지금 청소'), findsNWidgets(2));
    expect(find.text('구역'), findsOneWidget);
    expect(find.text('기록'), findsOneWidget);
    expect(find.text('청소 요정의 추천'), findsOneWidget);
    expect(find.text('자랑'), findsOneWidget);

    await tester.tap(find.text('구역'));
    await tester.pumpAndSettle();

    expect(find.text('주방'), findsOneWidget);
    expect(find.text('거실'), findsOneWidget);

    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();

    expect(find.text('에코업 음식물처리기'), findsOneWidget);
    expect(find.text('항목 추가'), findsOneWidget);

    await tester.tap(find.text('에코업 음식물처리기'));
    await tester.pumpAndSettle();

    expect(find.text('DCS-HM4AG-W'), findsOneWidget);
    expect(find.text('제품 정보 수정'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('공식 세척 영상 보기'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('공식 세척 영상 보기'), findsOneWidget);
    expect(find.text('이 청소법의 참고 기준'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('청소용품 추천'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('청소용품 추천'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('추천 제품'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('추천 제품'), findsOneWidget);
    expect(find.text('베이직 제로 스크래치 스펀지 수세미'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('청소 순서'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('청소 순서'), findsOneWidget);
    expect(find.text('먼저 확인하세요'), findsOneWidget);
  });

  testWidgets('일반 항목에 나중에 제품 정보를 등록할 수 있다', (tester) async {
    seedSampleData(taskRepository, dataRepository);
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('구역'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('냉장고'));
    await tester.pumpAndSettle();

    expect(find.text('브랜드·모델 등록'), findsOneWidget);

    await tester.tap(find.text('브랜드·모델 등록'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('목록에 없어요'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '브랜드 직접 입력'),
      '삼성전자',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '모델명 직접 입력 또는 선택'),
      'RF85TEST',
    );
    await tester.scrollUntilVisible(
      find.text('제품 정보 저장'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('제품 정보 저장'));
    await tester.pumpAndSettle();

    expect(find.text('삼성전자'), findsOneWidget);
    expect(find.text('RF85TEST'), findsOneWidget);
    expect(find.text('제품 정보 수정'), findsOneWidget);
  });

  testWidgets('브랜드와 모델명을 선택지로 등록할 수 있다', (tester) async {
    seedSampleData(taskRepository, dataRepository);
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('구역'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('냉장고'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('브랜드·모델 등록'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('LG전자'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('M874GBB031'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('RF85C90F1AP'), findsNothing);
    await tester.tap(find.text('M874GBB031'));
    await tester.scrollUntilVisible(
      find.text('제품 정보 저장'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('제품 정보 저장'));
    await tester.pumpAndSettle();

    expect(find.text('LG전자'), findsOneWidget);
    expect(find.text('M874GBB031'), findsOneWidget);
  });

  testWidgets('제품 등록 모드에서 항목 프리셋을 눌러도 제품 등록이 유지된다', (tester) async {
    seedSampleData(taskRepository, dataRepository);
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('구역'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('항목 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제품 등록'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, '냉장고'));
    await tester.pumpAndSettle();

    expect(find.text('브랜드'), findsOneWidget);
    expect(find.text('브랜드를 고르면 아래 모델 후보가 바뀌어요.'), findsOneWidget);
    expect(find.widgetWithText(TextField, '모델명 직접 입력 또는 선택'), findsOneWidget);
  });

  testWidgets('구역을 고르고 등록된 청소를 완료할 수 있다', (tester) async {
    seedSampleData(taskRepository, dataRepository);
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('지금 몇 분 정도 괜찮으세요?'), findsNothing);
    expect(find.text('아무 곳이나'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('청소할 구역을 골라주세요'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('청소할 구역을 골라주세요'), findsOneWidget);
    expect(find.text('싱크대 주변 닦기'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, '주방'));
    await tester.pumpAndSettle();

    expect(find.text('주방 청소 목록'), findsOneWidget);
    expect(find.text('에코업 음식물처리기 청소'), findsOneWidget);
    expect(find.text('냉장고 청소'), findsOneWidget);

    final foodWasteCard = find.ancestor(
      of: find.text('에코업 음식물처리기 청소'),
      matching: find.byType(Card),
    );
    final foodWasteCheckbox = find.descendant(
      of: foodWasteCard,
      matching: find.byType(Checkbox),
    );
    await tester.ensureVisible(foodWasteCheckbox);
    await tester.pumpAndSettle();
    await tester.tap(foodWasteCheckbox);
    await tester.pumpAndSettle();
    expect(find.textContaining('첫 번째 반짝임 완료'), findsOneWidget);
  });

  testWidgets('탭을 이동해도 지금 청소의 체크 상태가 유지된다', (tester) async {
    seedSampleData(taskRepository, dataRepository);
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, '주방'));
    await tester.pumpAndSettle();
    final sinkCard = find.ancestor(
      of: find.text('싱크대 청소'),
      matching: find.byType(Card),
    );
    final sinkCheckbox = find.descendant(
      of: sinkCard,
      matching: find.byType(Checkbox),
    );
    await tester.ensureVisible(sinkCheckbox);
    await tester.tap(sinkCheckbox);
    await tester.pumpAndSettle();

    expect(tester.widget<Checkbox>(sinkCheckbox).value, isTrue);

    await tester.tap(find.text('구역'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('싱크대'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('청소 순서'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('청소 순서'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('지금 청소'));
    await tester.pumpAndSettle();

    final restoredSinkCard = find.ancestor(
      of: find.text('싱크대 청소'),
      matching: find.byType(Card),
    );
    final restoredSinkCheckbox = find.descendant(
      of: restoredSinkCard,
      matching: find.byType(Checkbox),
    );
    expect(tester.widget<Checkbox>(restoredSinkCheckbox).value, isTrue);
  });

  testWidgets('청소 자랑 커뮤니티 탭이 표시된다', (tester) async {
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('자랑'));
    await tester.pump();

    expect(find.text('청소 자랑'), findsOneWidget);
    expect(find.text('내 청소 자랑하기'), findsOneWidget);
    expect(find.text('아직 올라온 자랑이 없어요'), findsOneWidget);
  });

  testWidgets('청소 완료 시 기록 탭에 자동으로 남는다', (tester) async {
    seedSampleData(taskRepository, dataRepository);
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('구역'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('에코업 음식물처리기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('기록'));
    await tester.pumpAndSettle();

    expect(find.text('에코업 음식물처리기 청소 완료'), findsOneWidget);
  });

  testWidgets('커뮤니티에 내 청소 자랑을 올릴 수 있다', (tester) async {
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('자랑'));
    await tester.pump();
    await tester.tap(find.text('내 청소 자랑하기'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '자랑 내용'),
      '싱크대 주변을 반짝하게 닦았어요!',
    );
    await tester.tap(find.text('올리기'));
    await tester.pumpAndSettle();

    expect(find.text('싱크대 주변을 반짝하게 닦았어요!'), findsOneWidget);
  });

  testWidgets('초기 세팅에서 선택한 구역을 바로 만들 수 있다', (tester) async {
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('구역'));
    await tester.pumpAndSettle();

    expect(find.text('먼저 집 구조를 골라볼까요?'), findsOneWidget);
    await tester.tap(find.text('선택한 구역 만들기'));
    await tester.pumpAndSettle();

    expect(find.text('주방'), findsOneWidget);
    expect(find.text('거실'), findsOneWidget);
    expect(find.text('욕실'), findsOneWidget);
  });

  testWidgets('첫 화면에는 밀린 청소가 쌓여 보이지 않는다', (tester) async {
    seedSampleData(taskRepository, dataRepository);
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('청소할 구역을 골라주세요'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('청소할 구역을 골라주세요'), findsOneWidget);
    expect(find.text('싱크대 주변 닦기'), findsNothing);
    expect(find.text('거실 바닥 청소기 돌리기'), findsNothing);
  });

  testWidgets('주방을 선택하면 주방에 등록한 항목이 나열된다', (tester) async {
    seedSampleData(taskRepository, dataRepository);
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, '주방'));
    await tester.pumpAndSettle();

    expect(find.text('에코업 음식물처리기 청소'), findsOneWidget);
    expect(find.text('냉장고 청소'), findsOneWidget);
    expect(find.text('전자레인지 청소'), findsOneWidget);
    expect(find.text('싱크대 청소'), findsOneWidget);
    expect(find.text('소파 청소'), findsNothing);
  });

  testWidgets('직접 추가한 청소가 앱을 다시 열어도 추천 후보로 유지된다', (tester) async {
    seedSampleData(taskRepository, dataRepository);
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, '주방'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('하고 싶은 청소 직접 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '할 일'),
      '싱크대 주변 물기 제거',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '예상 시간(분)'),
      '3',
    );
    await tester.ensureVisible(find.text('이번 청소에 추가'));
    await tester.tap(find.text('이번 청소에 추가'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, '주방'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('싱크대 주변 물기 제거'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('싱크대 주변 물기 제거'), findsOneWidget);
  });

  testWidgets('구역을 선택하면 청소 이유가 표시된다', (tester) async {
    seedSampleData(taskRepository, dataRepository);
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('오늘 체력은 어때요?'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, '욕실'));
    await tester.pumpAndSettle();

    expect(find.text('욕실 청소 목록'), findsOneWidget);
    expect(find.text('세면대 청소'), findsOneWidget);
    expect(find.textContaining('참고했어요'), findsWidgets);
  });

  testWidgets('청소 순서를 보고 뿌듯하게 완료할 수 있다', (tester) async {
    seedSampleData(taskRepository, dataRepository);
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, '주방'));
    await tester.pumpAndSettle();
    final foodWasteCard = find.ancestor(
      of: find.text('에코업 음식물처리기 청소'),
      matching: find.byType(Card),
    );
    final startButton = find.descendant(
      of: foodWasteCard,
      matching: find.widgetWithText(FilledButton, '시작'),
    );
    await tester.ensureVisible(startButton);
    await tester.pumpAndSettle();
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    expect(find.text('청소 시작'), findsOneWidget);
    expect(find.text('타이머 시작'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('이 순서로 해봐요'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('이 순서로 해봐요'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('청소 완료'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('청소 완료'));
    await tester.pumpAndSettle();

    expect(find.text('한 곳을 반짝이게 만들었어요!'), findsOneWidget);
    expect(find.text('뿌듯하게 마치기'), findsOneWidget);
    await tester.tap(find.text('뿌듯하게 마치기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('첫 번째 반짝임 완료'), findsOneWidget);
    final records = await dataRepository.loadRecords();
    expect(records?.first.title, contains('완료'));
  });

  testWidgets('최근 청소한 항목도 구역 목록에서 직접 선택할 수 있다', (tester) async {
    final now = DateTime.now();
    final sink = mockZoneItems.firstWhere(
      (item) => item.id == 'kitchen-sink',
    );
    await dataRepository.saveZones(cleaningZones);
    await dataRepository.saveZoneItems([
      ...mockZoneItems.where((item) => item.id != sink.id),
      sink.copyWith(
        lastCleanedAt: now,
        nextDueAt: now.add(const Duration(days: 1)),
      ),
    ]);
    await taskRepository.saveTodayTasks([
      const CleaningTask(
        id: 'scheduled-zone-item-kitchen-sink',
        title: '싱크대 정기 청소',
        zoneName: '주방',
        estimatedMinutes: 8,
        isDone: false,
        isRecurring: true,
      ),
    ]);

    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '주방'));
    await tester.pumpAndSettle();

    expect(find.text('싱크대 청소'), findsOneWidget);
    expect(find.textContaining('마지막 청소 후 0일'), findsNothing);
    expect(find.textContaining('최근에 청소했어요'), findsOneWidget);
  });

  testWidgets('방1 같은 새 구역을 추가할 수 있다', (tester) async {
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('구역'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('구역 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '구역 이름'),
      '방1',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '구역 설명'),
      '책상, 침대, 옷장',
    );
    await tester.tap(find.widgetWithText(FilledButton, '구역 추가').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('방1'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('방1'), findsOneWidget);
  });

  testWidgets('구역을 삭제할 수 있다', (tester) async {
    seedSampleData(taskRepository, dataRepository);
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('구역'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('구역 삭제'));
    await tester.pumpAndSettle();

    expect(find.text('주방 삭제'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '삭제'));
    await tester.pumpAndSettle();

    expect(find.text('주방'), findsNothing);
    expect(find.textContaining('구역을 삭제했어요'), findsOneWidget);
  });
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
