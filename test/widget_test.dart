// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clean_up/app.dart';
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
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );

    expect(find.text('오늘'), findsNWidgets(2));
    expect(find.text('구역'), findsOneWidget);
    expect(find.text('기록'), findsOneWidget);
    expect(find.text('청소 요정의 응원'), findsOneWidget);
    expect(find.text('자랑'), findsOneWidget);

    await tester.tap(find.text('구역'));
    await tester.pump();

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
    expect(find.text('제로스크래치 스폰지 수세미'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('청소 순서'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('청소 순서'), findsOneWidget);
    expect(find.text('먼저 확인하세요'), findsOneWidget);
  });

  testWidgets('일반 항목에 나중에 제품 정보를 등록할 수 있다', (tester) async {
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );

    await tester.tap(find.text('구역'));
    await tester.pump();
    await tester.tap(find.text('주방'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('냉장고'));
    await tester.pumpAndSettle();

    expect(find.text('브랜드·모델 등록'), findsOneWidget);

    await tester.tap(find.text('브랜드·모델 등록'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '브랜드 또는 제조사'),
      '삼성전자',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '모델명'),
      'RF85TEST',
    );
    await tester.tap(find.text('제품 정보 저장'));
    await tester.pumpAndSettle();

    expect(find.text('삼성전자'), findsOneWidget);
    expect(find.text('RF85TEST'), findsOneWidget);
    expect(find.text('제품 정보 수정'), findsOneWidget);
  });

  testWidgets('오늘 할 일을 추가하고 완료할 수 있다', (tester) async {
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );

    await tester.tap(find.text('할 일 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '할 일'),
      '분리수거 버리기',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '예상 시간(분)'),
      '7',
    );
    await tester.ensureVisible(find.text('오늘 할 일에 추가'));
    await tester.tap(find.text('오늘 할 일에 추가'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('분리수거 버리기'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('분리수거 버리기'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -180));
    await tester.pump();
    await tester.tap(find.byType(Checkbox).last);
    await tester.pump();
    expect(find.textContaining('벌써 세 개'), findsOneWidget);
  });

  testWidgets('청소 자랑 커뮤니티 탭이 표시된다', (tester) async {
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );

    await tester.tap(find.text('자랑'));
    await tester.pump();

    expect(find.text('청소 자랑'), findsOneWidget);
    expect(find.text('내 청소 자랑하기'), findsOneWidget);
    expect(find.text('반짝주방'), findsOneWidget);
  });

  testWidgets('청소 완료 시 기록 탭에 자동으로 남는다', (tester) async {
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );

    await tester.tap(find.text('구역'));
    await tester.pump();
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

  testWidgets('주기 청소를 다음 일정으로 미룰 수 있다', (tester) async {
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -220));
    await tester.pump();
    final postponeButton = find.byTooltip('미루기').first;
    await tester.tap(postponeButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('내일로 미룸'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('미룬 할 일'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('미룬 할 일'), findsOneWidget);
    expect(find.textContaining('내일로 미룸'), findsOneWidget);
    expect(find.text('되돌리기'), findsOneWidget);
  });

  testWidgets('오늘 할 일을 삭제하고 되돌릴 수 있다', (tester) async {
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -220));
    await tester.pump();
    await tester.tap(find.byTooltip('삭제').first);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('싱크대 주변 닦기'), findsNothing);
    expect(find.textContaining('오늘 할 일에서 지웠어요'), findsOneWidget);

    final undoAction = tester.widget<SnackBarAction>(
      find.byType(SnackBarAction),
    );
    undoAction.onPressed();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('싱크대 주변 닦기'), findsOneWidget);
  });

  testWidgets('추가한 오늘 할 일이 앱을 다시 열어도 유지된다', (tester) async {
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );

    await tester.tap(find.text('할 일 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '할 일'),
      '싱크대 주변 물기 제거',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '예상 시간(분)'),
      '3',
    );
    await tester.ensureVisible(find.text('오늘 할 일에 추가'));
    await tester.tap(find.text('오늘 할 일에 추가'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('싱크대 주변 물기 제거'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('싱크대 주변 물기 제거'), findsOneWidget);
  });

  testWidgets('방1 같은 새 구역을 추가할 수 있다', (tester) async {
    await tester.pumpWidget(
      CleanUpApp(
        taskRepository: taskRepository,
        dataRepository: dataRepository,
      ),
    );

    await tester.tap(find.text('구역'));
    await tester.pump();
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
    await tester.tap(find.text('구역 추가'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('방1'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('방1'), findsOneWidget);
  });
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
