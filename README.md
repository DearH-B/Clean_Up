# 케어로그

제품별 청소법, 관리 정보, 소모품과 관리 기록을 정리하는 Flutter 앱입니다.

## 구조

```text
lib/
  data/           앱 내장 카탈로그와 샘플 데이터
  models/         Flutter 도메인 모델
  repositories/   SQLite 로컬 저장소 및 원격 제품 카탈로그 연결
  screens/        홈, 내 제품, 기록, 문제 확인과 설정 화면

server/
  app/            FastAPI 엔드포인트와 카탈로그 서비스
  data/           검수 상태가 포함된 제품 JSON
  tests/          카탈로그 검색 테스트
```

제품 검색은 서버 API를 먼저 사용합니다. 서버가 꺼져 있거나 네트워크 오류가 발생하면 앱 내장 카탈로그로 자동 전환됩니다.
제품 등록의 브랜드·모델 후보도 같은 방식으로 서버를 우선 사용합니다.
제품 라벨은 카메라 OCR로 모델명 후보를 읽을 수 있으며, 한두 글자 오타도 유사
검색합니다.

## 현재 구현 단계

- Phase 8: SQLite 저장, 백업·복원·전체 삭제
- Phase 9: 제품 라벨 OCR과 유사 검색
- Phase 10: 검수형 운영 카탈로그와 감사 로그
- Phase 11: 제품군별 안전한 문제 확인
- Phase 12: 설정, 정책 초안, CI, 서버 Docker와 출시 서명 기반

현재 출시는 실제 기기 검증, 정식 이름·서명키, 법률 검토와 운영 모니터링이 남아
있어 `출시 검증 중` 상태입니다. 최신 판정은
`docs/RELEASE_READINESS_CURRENT.md`에서 확인합니다.

## 백엔드 실행

```powershell
cd server
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API 문서: `http://127.0.0.1:8000/docs`

## Flutter 실행

Android 에뮬레이터:

```powershell
E:\AIP\flutter-sdk\bin\flutter.bat run -d emulator-5554
```

기본 API 주소는 Android 에뮬레이터가 PC를 가리키는 `http://10.0.2.2:8000`입니다.

다른 서버를 사용할 때:

```powershell
E:\AIP\flutter-sdk\bin\flutter.bat run `
  --dart-define=CATALOG_API_BASE_URL=https://api.example.com
```

## 제품 데이터 운영 원칙

- `draft`: 조사 중, 앱 미노출
- `reviewed`: 기본 검수 완료
- `verified`: 모델명과 주요 출처 확인 완료
- 정확한 모델 자료가 없으면 `유사 제품 참고` 또는 `일반 관리법`으로 명확하게 표시
- 출처 URL과 확인일을 함께 저장
- 광고 또는 제휴 상품은 `isSponsored`를 반드시 표시
