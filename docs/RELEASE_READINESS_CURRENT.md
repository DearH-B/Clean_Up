# 제품 출시 검증 보고서

- 대상 릴리스: `production-1.0`
- 생성일: 2026-06-15
- 최종 판정: `blocked`

## 앱 공통 검사

- [PASS] `accessibility_large_text`: 200% 글자 크기에서 설정, 제품 등록, 제품 상세, 문제 확인과 데이터 관리 화면 회귀 테스트 통과. 하단 탐색과 위험 결과의 접근성 의미 및 탭 동작 자동 검증 완료 [codex, 2026-06-15]
- [PASS] `android_emulator_flow`: Android 에뮬레이터에서 제품 등록 OCR 진입, 설정·정책, 식기세척기 누수 문제 확인과 안전 결과 렌더링 확인 [codex, 2026-06-14]
- [PASS] `automated_regression`: Flutter 73개 테스트와 서버 28개 테스트, 정적 분석 및 디버그 APK 빌드 통과 [codex, 2026-06-15]
- [PASS] `external_link_failure`: 공식 설명서 링크 실행 예외를 자동 주입해 앱이 중단되지 않고 주소 복사 복구 안내를 표시하는 회귀 테스트 통과 [codex, 2026-06-15]
- [BLOCKED] `monitoring_and_recovery`: Python 3.13 Docker 이미지와 /health 확인, SQLite 안전 백업 및 별도 DB 복원 무결성·제품 수·감사 로그 비교 자동화 완료 (실제 호스팅 환경의 외부 가용성 모니터링과 알림 채널 연결 필요) [owner, 2026-06-15]
- [PASS] `offline_behavior`: Android 에뮬레이터 비행기 모드에서 홈 로컬 데이터, 주방 제품 목록, LG 냉장고 M875GBB231 검색·등록과 공식 관리법 상세 표시까지 확인 [codex, 2026-06-15]
- [BLOCKED] `physical_android_device`: 실제 Android 기기 설치 및 재실행 검증 기록 없음 [owner, 2026-06-13]
- [BLOCKED] `privacy_terms_disclaimer`: 앱 내 개인정보·기기 데이터, 이용, 제품 정보 책임, 광고 표시 초안 구현 (운영 주체와 문의 채널 확정 후 법률 검토 필요) [owner, 2026-06-14]
- [BLOCKED] `release_signing`: 디버그 키 출시 서명을 제거하고 key.properties 템플릿 구현 (정식 패키지명 결정, 업로드 키 생성과 Play Console 설정 필요) [owner, 2026-06-14]
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

## WF25CB8895BW

판정: `approved`

- [PASS] `catalog_verified`: 카탈로그 검수 상태가 verified입니다.
- [PASS] `official_identity_source`: 공식 제품 페이지로 모델명, 이미지와 출시 연도를 추적합니다.
- [PASS] `official_manual_source`: 공식 설명서 원문과 앱 링크가 일치합니다.
- [PASS] `source_traceability`: 모든 스펙과 관리 단계가 등록된 출처를 참조합니다.
- [PASS] `safety_guidance`: 전원 차단, 직접 물 분사 금지와 임의 분해 금지를 포함합니다.
- [PASS] `model_specific_claims`: 공식 근거 없는 부품번호를 노출하지 않습니다.
- [PASS] `support_information`: 공식 지원 링크와 서비스센터 연락처가 있습니다.
- [PASS] `source_freshness`: 모든 출처가 180일 이내에 확인됐습니다.
- [PASS] `model_ui_render`: Android 에뮬레이터에서 모델명, 공식 이미지, 출시 연도, 공식 자료 배지, 설명서 링크와 제품 사양 렌더링 확인 [codex, 2026-06-13]

## WF25DG8250BW

판정: `approved`

- [PASS] `catalog_verified`: 카탈로그 검수 상태가 verified입니다.
- [PASS] `official_identity_source`: 공식 제품 페이지로 모델명, 이미지와 출시 연도를 추적합니다.
- [PASS] `official_manual_source`: 공식 설명서 원문과 앱 링크가 일치합니다.
- [PASS] `source_traceability`: 모든 스펙과 관리 단계가 등록된 출처를 참조합니다.
- [PASS] `safety_guidance`: 전원 차단, 직접 물 분사 금지와 임의 분해 금지를 포함합니다.
- [PASS] `model_specific_claims`: 공식 근거 없는 부품번호를 노출하지 않습니다.
- [PASS] `support_information`: 공식 지원 링크와 서비스센터 연락처가 있습니다.
- [PASS] `source_freshness`: 모든 출처가 180일 이내에 확인됐습니다.
- [PASS] `model_ui_render`: Android 에뮬레이터에서 WF25DG8250BW 검색, 공식 설명서 확인 모델, 검수 상태, 주요 사양과 출시 연도 렌더링 확인 [codex, 2026-06-15]

## WF25DG8650BW

판정: `approved`

- [PASS] `catalog_verified`: 카탈로그 검수 상태가 verified입니다.
- [PASS] `official_identity_source`: 공식 제품 페이지로 모델명, 이미지와 출시 연도를 추적합니다.
- [PASS] `official_manual_source`: 공식 설명서 원문과 앱 링크가 일치합니다.
- [PASS] `source_traceability`: 모든 스펙과 관리 단계가 등록된 출처를 참조합니다.
- [PASS] `safety_guidance`: 전원 차단, 직접 물 분사 금지와 임의 분해 금지를 포함합니다.
- [PASS] `model_specific_claims`: 공식 근거 없는 부품번호를 노출하지 않습니다.
- [PASS] `support_information`: 공식 지원 링크와 서비스센터 연락처가 있습니다.
- [PASS] `source_freshness`: 모든 출처가 180일 이내에 확인됐습니다.
- [PASS] `model_ui_render`: Android 에뮬레이터에서 WF25DG8650BW 검색, 공식 설명서 확인 모델과 검수 상태, 제품 이미지, 사양 및 모델별 관리 순서 렌더링 확인 [codex, 2026-06-15]

## 판정 원칙

- `FAIL` 또는 `BLOCKED`가 하나라도 있으면 출시 검증 완료로 표시하지 않는다.
- 자동 검사는 카탈로그를 읽을 때마다 다시 계산한다.
- 수동 검사는 검증일, 검증자와 재현 가능한 증거를 함께 남긴다.
