# 출시 점검표

## 제품과 데이터

- [ ] 출시 제품 50개의 공식 제품 페이지와 설명서 링크 재확인
- [ ] 관리 단계와 안전 문구의 출처 연결 확인
- [ ] 이미지 사용 정책 확인
- [ ] 단종·링크 만료 재검수 담당자와 주기 지정
- [x] 서버 데이터와 앱 내장 대체 데이터 비교

## Android

- [ ] 정식 앱 이름과 `applicationId` 결정: 표시 이름은 `케어로그`, `applicationId`는 운영 주체 확정 후 최종 결정
- [ ] 최종 아이콘과 스플래시 적용
- [ ] 업로드 키 생성과 오프라인 백업
- [ ] 서명된 AAB 생성
- [ ] Play Console 내부 테스트 배포
- [x] 200% 큰 글자 주요 흐름과 접근성 의미 구조 자동 검증
- [ ] 저사양·작은 화면·TalkBack 실제 기기 검증
- [x] 오프라인과 외부 링크 오류 복구 검증
- [x] 업데이트 후 기존 데이터 유지 검증

## iOS

- [ ] Mac, Xcode와 Apple Developer 계정 준비
- [ ] 카메라·사진 권한 문구 등록
- [ ] iPhone 16 실제 설치와 OCR 검증
- [ ] TestFlight 내부 테스트

## 정책과 운영

- [ ] 운영 주체, 도메인과 문의 이메일 확정
- [ ] Render에 `carelog-api` 배포 (`render.yaml`, `docs/RENDER_DEPLOYMENT_GUIDE.md` 기준)
- [ ] 운영 API URL 확정 및 출시 빌드에 `CATALOG_API_BASE_URL` 주입 (`docs/API_ENVIRONMENT_GUIDE.md` 기준)
- [ ] 개인정보처리방침과 이용약관 법률 검토 (`docs/POLICY_FINALIZATION_CHECKLIST.md` 기준)
- [ ] 제품 정보 책임 범위 최종 검토
- [ ] 광고·제휴 표시 문구 확정
- [ ] 오류 수집과 서버 알림 연결
- [x] DB 안전 백업과 별도 DB 복구 훈련 명령
- [ ] 운영 환경 영속 저장소 연결, 자동 백업 일정과 외부 모니터링 알림 연결
- [ ] 사용자 제보 처리 담당자와 응답 목표 지정

## 배포 판정

- [x] Flutter 정적 분석 통과
- [x] Flutter·서버 전체 테스트 통과
- [ ] 출시 검증 보고서에 FAIL 또는 BLOCKED 없음
- [ ] 주요 사용자 시나리오 실제 기기 통과
