# Phase 0: 제품 관리 기준선

## 확정 방향

이 앱은 매일 할 일을 쌓아두는 청소 체크리스트 앱으로 돌아가지 않는다.
사용자가 보유한 제품을 등록하고, 제품을 식별하고, 신뢰할 수 있는 관리 정보를
필요할 때 빠르게 찾는 제품 관리 앱으로 발전시킨다.

## 핵심 사용자 데이터

- `ProductSpace`: 사용자가 제품을 정리하는 공간
- `ZoneItem`: 사용자가 실제로 보유하고 등록한 제품
- `CareRecord`: 제품을 관리한 이력
- `CommunityPost`: 사용자가 공유한 관리 경험

`ZoneItem`은 기존 저장 데이터 호환성을 위해 이름을 당장 유지한다. 이후 단계에서
`UserProduct`로 이름을 바꾸되, 저장 데이터 마이그레이션을 함께 제공한다.

## 카탈로그와 사용자 제품의 경계

- `ProductCatalogEntry`는 공통으로 제공되는 제품 카탈로그 정보다.
- `ZoneItem`은 사용자가 소유한 제품 인스턴스다.
- 카탈로그에서 등록한 제품은 `catalogProductId`로 원본 항목을 참조한다.
- 직접 입력한 제품은 `catalogProductId`가 없을 수 있다.
- 사용자의 관리일, 기록, 공간 배치는 카탈로그 데이터와 분리한다.

## 저장 호환성

기존 사용자 데이터를 잃지 않도록 SharedPreferences 키는 유지한다.

- 공간: `zones_v1`
- 사용자 제품: `zone_items_v1`
- 관리 기록: `cleaning_records_v1`
- 커뮤니티 글: `community_posts_v1`

새 모델은 이전 JSON 필드인 `taskCount`, `completedTaskCount`, `zoneName`도 읽을 수
있다. 새로 저장할 때는 제품 관리 용어의 필드를 사용한다.

## 제거한 이전 구조

- 오늘 할 일과 반복 체크리스트
- 청소 세션 화면과 타이머
- `CleaningTask` 및 전용 저장소
- 체크리스트 전용 타일과 검색 위젯
- `CleaningZone`, `CleaningRecord`, `CleaningDataRepository`

## 다음 단계

Phase 1에서는 `ZoneItem`과 화면 파일의 레거시 이름을 정리하고, 제품 등록 흐름을
`검색 -> 후보 확인 -> 내 제품 등록` 구조로 분리한다.
