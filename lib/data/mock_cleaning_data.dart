import '../models/cleaning_record.dart';
import '../models/cleaning_task.dart';
import '../models/cleaning_zone.dart';

final todayTasks = <CleaningTask>[
  const CleaningTask(
    id: 'task-1',
    title: '싱크대 주변 닦기',
    zoneName: '주방',
    estimatedMinutes: 10,
    isDone: true,
    isRecurring: true,
  ),
  const CleaningTask(
    id: 'task-2',
    title: '거실 바닥 청소기 돌리기',
    zoneName: '거실',
    estimatedMinutes: 15,
    isDone: false,
    isRecurring: true,
  ),
  const CleaningTask(
    id: 'task-3',
    title: '욕실 세면대 정리',
    zoneName: '욕실',
    estimatedMinutes: 8,
    isDone: false,
    isRecurring: true,
  ),
  const CleaningTask(
    id: 'task-4',
    title: '분리수거 모으기',
    zoneName: '현관',
    estimatedMinutes: 5,
    isDone: true,
  ),
];

final cleaningZones = <CleaningZone>[
  const CleaningZone(
    id: 'zone-1',
    name: '주방',
    description: '싱크대, 조리대, 냉장고 앞 공간',
    taskCount: 6,
    completedTaskCount: 4,
  ),
  const CleaningZone(
    id: 'zone-2',
    name: '거실',
    description: '소파, 테이블, 바닥, 창가',
    taskCount: 5,
    completedTaskCount: 2,
  ),
  const CleaningZone(
    id: 'zone-3',
    name: '욕실',
    description: '세면대, 변기, 샤워부스',
    taskCount: 4,
    completedTaskCount: 1,
  ),
  const CleaningZone(
    id: 'zone-4',
    name: '침실',
    description: '침구, 옷장 주변, 협탁',
    taskCount: 3,
    completedTaskCount: 2,
  ),
];

final cleaningRecords = <CleaningRecord>[
  CleaningRecord(
    id: 'record-1',
    title: '주방 데일리 루틴 완료',
    zoneName: '주방',
    completedAt: DateTime(2026, 6, 5, 8, 30),
    minutes: 18,
  ),
  CleaningRecord(
    id: 'record-2',
    title: '현관 정리',
    zoneName: '현관',
    completedAt: DateTime(2026, 6, 4, 21, 10),
    minutes: 7,
  ),
  CleaningRecord(
    id: 'record-3',
    title: '거실 먼지 제거',
    zoneName: '거실',
    completedAt: DateTime(2026, 6, 3, 19, 45),
    minutes: 20,
  ),
];
