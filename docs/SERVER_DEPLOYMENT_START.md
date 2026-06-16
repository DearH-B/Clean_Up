# 케어로그 서버 구축 시작

- 생성일: 2026-06-16
- 목표: 앱이 사용할 제품 카탈로그, 생활 문제 안내, 사용자 제보 접수 서버를 실제 배포 가능한 구조로 준비한다.

## 1단계에서 완료한 것

- 운영 설정을 `server/app/config.py`로 분리했다.
- 환경 변수 예시 파일 `server/.env.example`을 추가했다.
- `/health` 응답에 실행 환경, 공개 제품 수, 운영 카탈로그 수, 진단 데이터 버전과 관리자 API 활성 여부를 포함했다.
- `CARELOG_ALLOWED_ORIGINS` 기반 CORS 설정을 추가했다.
- 관리자 API로 사용자 제보를 조회할 수 있게 했다.
- 관리자 API로 사용자 제보 상태를 변경할 수 있게 했다.
- Docker 운영 경로에서 카탈로그 DB와 제보 파일을 `/app/runtime`에 저장하도록 맞췄다.
- Docker 이미지에 로컬 제보 파일이 포함되지 않도록 제외했다.

## 현재 서버 역할

- 제품 검색: `GET /v1/products`
- 제품 상세: `GET /v1/products/{productId}`
- 브랜드 목록: `GET /v1/brands`
- 모델 목록: `GET /v1/models`
- 생활 문제 안내: `GET /v1/diagnostics`
- 사용자 제보 접수: `POST /v1/submissions`
- 사용자 제보 상태 확인: `GET /v1/submissions/{trackingToken}`
- 관리자 제품 관리: `/v1/admin/products`
- 관리자 감사 로그: `GET /v1/admin/audit-log`
- 관리자 제보 관리: `/v1/admin/submissions`

## 로컬 실행

```powershell
cd server
$env:CARELOG_ENV = "local"
$env:CATALOG_ADMIN_API_KEY = "local-dev-secret"
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Android 에뮬레이터에서는 앱 서버 주소를 `http://10.0.2.2:8000`으로 사용한다.

## 운영 서버에서 필요한 환경 변수

```text
CARELOG_ENV=production
CARELOG_ALLOWED_ORIGINS=https://admin.example.com
CATALOG_DATABASE_PATH=/app/runtime/catalog_admin.db
SUBMISSIONS_PATH=/app/runtime/submissions.json
CATALOG_ADMIN_API_KEY=<긴 랜덤 비밀키>
```

## 다음 단계

- 앱 빌드에 서버 주소 주입: `docs/API_ENVIRONMENT_GUIDE.md`
- 실제 배포 위치 결정: Render로 진행
- Render 배포 절차: `docs/RENDER_DEPLOYMENT_GUIDE.md`
- 운영 DB 백업 위치 결정
- 외부 모니터링 연결: `/ready`를 1분 또는 5분 주기로 확인
- 관리자 웹 화면 또는 최소 운영 CLI 결정
- 앱의 운영 API URL 확정
- HTTPS 도메인 연결
- 제보 데이터 보관 기간과 삭제 요청 절차 확정

## 아직 출시 차단인 것

- 실제 호스팅 서버 없음
- HTTPS 도메인 없음
- 외부 모니터링 없음
- 운영 관리자 키 미발급
- 제보 처리 담당자와 응답 목표 미확정
- 운영 백업 자동화 미연결
