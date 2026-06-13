# 냉장고 3종 출시 검증 보고서

- 대상 릴리스: `production-1.0`
- 생성일: 2026-06-13
- 최종 판정: `blocked`

## 앱 공통 검사

- [BLOCKED] `accessibility_large_text`: 200% 글자 크기와 TalkBack 주요 흐름 미검증 [codex, 2026-06-13]
- [PASS] `android_emulator_flow`: Android 에뮬레이터에서 RM70F63R2A 상세 화면 진입과 관리법 렌더링 확인 [codex, 2026-06-13]
- [PASS] `automated_regression`: Flutter 50개 테스트와 서버 18개 테스트 통과 [codex, 2026-06-13]
- [BLOCKED] `external_link_failure`: 링크 실행 예외 안내와 주소 복사 복구 동작은 구현했으나 실제 실패 주입 검증은 미완료 [codex, 2026-06-13]
- [BLOCKED] `monitoring_and_recovery`: 출시 서버 오류 모니터링, 백업과 복구 훈련 미완료 [owner, 2026-06-13]
- [BLOCKED] `offline_behavior`: 네트워크 차단 상태의 등록·상세·출처 대체 안내 전체 흐름 미검증 (출시 전 실제 기기에서 비행기 모드 테스트 필요) [codex, 2026-06-13]
- [BLOCKED] `physical_android_device`: 실제 Android 기기 설치 및 재실행 검증 기록 없음 [owner, 2026-06-13]
- [BLOCKED] `privacy_terms_disclaimer`: 개인정보 처리방침, 이용약관과 제품 정보 책임 범위 최종본 미등록 [owner, 2026-06-13]
- [BLOCKED] `release_signing`: 출시용 Android 서명키, 패키지명과 스토어 배포 설정 미완료 [owner, 2026-06-13]
- [PASS] `saved_data_migration`: 같은 검수일의 카탈로그 문구 변경도 기존 저장 제품에 반영하는 회귀 테스트 통과 [codex, 2026-06-13]

## RM70F63R2A

판정: `approved`

- [PASS] `catalog_verified`: 카탈로그 검수 상태가 verified입니다.
- [PASS] `official_identity_source`: 공식 제품 페이지로 모델명, 이미지와 출시 연도를 추적합니다.
- [PASS] `official_manual_source`: 공식 설명서 원문과 앱 링크가 일치합니다.
- [PASS] `source_traceability`: 모든 스펙과 관리 단계가 등록된 출처를 참조합니다.
- [PASS] `safety_guidance`: 전원 차단, 직접 물 분사 금지와 임의 분해 금지를 포함합니다.
- [PASS] `model_specific_claims`: 공식 근거 없는 부품번호를 노출하지 않습니다.
- [PASS] `support_information`: 공식 지원 링크와 서비스센터 연락처가 있습니다.
- [PASS] `source_freshness`: 모든 출처가 180일 이내에 확인됐습니다.
- [PASS] `duplicate_copy`: 공식 사용설명서 확인 문구 1회 렌더링, 이전 중복 요약 0회 확인 [codex, 2026-06-13]
- [PASS] `model_ui_render`: 에뮬레이터에서 모델명, 제품 이미지, 공식 자료 배지와 관리법 표시 확인 [codex, 2026-06-13]

## RM70F90M1ZD

판정: `approved`

- [PASS] `catalog_verified`: 카탈로그 검수 상태가 verified입니다.
- [PASS] `official_identity_source`: 공식 제품 페이지로 모델명, 이미지와 출시 연도를 추적합니다.
- [PASS] `official_manual_source`: 공식 설명서 원문과 앱 링크가 일치합니다.
- [PASS] `source_traceability`: 모든 스펙과 관리 단계가 등록된 출처를 참조합니다.
- [PASS] `safety_guidance`: 전원 차단, 직접 물 분사 금지와 임의 분해 금지를 포함합니다.
- [PASS] `model_specific_claims`: 공식 근거 없는 부품번호를 노출하지 않습니다.
- [PASS] `support_information`: 공식 지원 링크와 서비스센터 연락처가 있습니다.
- [PASS] `source_freshness`: 모든 출처가 180일 이내에 확인됐습니다.
- [PASS] `image_origin_review`: 삼성전자 이미지 도메인의 공식 대표 이미지 URL을 사용 [codex, 2026-06-13]
- [PASS] `model_specific_consumables`: RM80에서 RM70F90M1ZD로 변경한 뒤 UV 청정탈취 필터가 0개로 자동 정리됨 [codex, 2026-06-13]
- [PASS] `model_ui_render`: 에뮬레이터에서 RM70F90M1ZD 관리법, 소모품과 제품 정보 탭 렌더링 확인 [codex, 2026-06-13]
- [PASS] `official_support_render`: 제품 정보 탭에서 공식 설명서 링크, 2025년 출시와 서비스센터 1588-3366 표시 확인 [codex, 2026-06-13]

## RM80F91H1W

판정: `approved`

- [PASS] `catalog_verified`: 카탈로그 검수 상태가 verified입니다.
- [PASS] `official_identity_source`: 공식 제품 페이지로 모델명, 이미지와 출시 연도를 추적합니다.
- [PASS] `official_manual_source`: 공식 설명서 원문과 앱 링크가 일치합니다.
- [PASS] `source_traceability`: 모든 스펙과 관리 단계가 등록된 출처를 참조합니다.
- [PASS] `safety_guidance`: 전원 차단, 직접 물 분사 금지와 임의 분해 금지를 포함합니다.
- [PASS] `model_specific_claims`: 공식 근거 없는 부품번호를 노출하지 않습니다.
- [PASS] `support_information`: 공식 지원 링크와 서비스센터 연락처가 있습니다.
- [PASS] `source_freshness`: 모든 출처가 180일 이내에 확인됐습니다.
- [PASS] `model_ui_render`: 에뮬레이터에서 RM80F91H1W 관리법, 소모품과 제품 정보 탭 렌더링 확인 [codex, 2026-06-13]
- [PASS] `official_support_render`: 제품 정보 탭에서 공식 설명서 링크와 서비스센터 1588-3366 표시 확인 [codex, 2026-06-13]
- [PASS] `uv_filter_scope`: UV 청정탈취 필터는 RM80F91H1W에만 노출되고 확인되지 않은 부품번호는 비워 둠 [codex, 2026-06-13]

## 판정 원칙

- `FAIL` 또는 `BLOCKED`가 하나라도 있으면 출시 검증 완료로 표시하지 않는다.
- 자동 검사는 카탈로그를 읽을 때마다 다시 계산한다.
- 수동 검사는 검증일, 검증자와 재현 가능한 증거를 함께 남긴다.
