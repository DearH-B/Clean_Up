# Phase 6: 사용자 제보와 운영자 검수

상태: 핵심 완료

## 완료된 기능

### 앱

- 검색되지 않는 제품을 제품 정보 요청으로 저장
- 제품 상세에서 다음 유형의 오류 제보 작성
  - 제품 정보가 다름
  - 링크가 열리지 않음
  - 관리법이 맞지 않음
  - 위험한 안내가 있음
  - 새로운 공식 자료 제공
- 개인정보를 적지 않도록 안내
- 서버 연결 전에도 기기에 안전하게 보관
- 서버 전송 실패 시 `전송 확인 필요`로 표시
- 요청 내역에서 재전송 및 접수 상태 새로고침
- 접수, 조사 중, 정보 확인, 반영 완료, 반영 불가 상태 지원

### 서버

- `POST /v1/submissions`: 제보 접수
- `GET /v1/submissions/{tracking_token}`: 상태 조회
- 클라이언트 요청 ID 기준 중복 접수 방지
- 추측하기 어려운 추적 토큰 발급
- 카탈로그 데이터와 분리된 `data/submissions.json` 저장
- 임시 파일 작성 후 교체하는 방식으로 저장 중단 위험 축소
- 상태 변경 시 운영자, 시각, 메모 감사 이력 보관

### 운영 도구

제보 목록:

```powershell
cd server
python manage.py submissions list
python manage.py submissions list --status received
```

제보 상태 변경:

```powershell
python manage.py submissions update <tracking_token> investigating `
  --operator "reviewer@example.com" `
  --note "공식 설명서 대조 중"
```

카탈로그 품질 보고서:

```powershell
python manage.py catalog
```

## 안전 기준

- 사용자 제보는 자동으로 공개 카탈로그가 되지 않는다.
- 관리자 인증이 없는 상태에서 상태 변경 API를 외부에 공개하지 않는다.
- 현재 상태 변경은 서버 파일에 접근할 수 있는 운영자 CLI에서만 가능하다.
- 공식 자료가 확인되기 전에는 `verified` 상태로 올리지 않는다.
- 라벨 사진과 개인정보는 아직 서버로 전송하지 않는다.

## 남은 운영 환경 작업

- 실제 서버 주소와 HTTPS
- 서버 영구 디스크 또는 데이터베이스
- 운영자 계정과 권한
- 사진 저장용 객체 스토리지
- 사용자 계정 도입 후 본인 요청만 조회하는 권한 정책
- 요청 처리 알림

위 항목은 로컬 코드만으로 안전하게 확정할 수 없다. 배포 환경과 계정 정책이 정해진
뒤 Phase 7, 8에서 진행한다.
