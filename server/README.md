# Product Catalog API

검수된 제품 정보와 청소 관리법을 Flutter 앱에 제공하는 로컬 API입니다.

## 실행

```powershell
cd server
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- API 문서: `http://127.0.0.1:8000/docs`
- 상태 확인: `http://127.0.0.1:8000/health`
- 준비 상태: `http://127.0.0.1:8000/ready`
- 제품 검색: `http://127.0.0.1:8000/v1/products?q=DCS-HM4AG-W`
- 브랜드 조회: `http://127.0.0.1:8000/v1/brands?category=TV`
- 모델 조회: `http://127.0.0.1:8000/v1/models?category=TV&brand=삼성전자`

Android 에뮬레이터에서는 PC의 `localhost`가 `10.0.2.2`로 보입니다.

## 환경 변수

운영 서버에서는 `server/.env.example`을 기준으로 값을 지정합니다.

- `CARELOG_ENV`: `local`, `staging`, `production` 같은 실행 환경 이름
- `CARELOG_ALLOWED_ORIGINS`: 웹 관리자 화면을 붙일 때 허용할 Origin 목록, 쉼표로 구분
- `CATALOG_DATABASE_PATH`: 운영 카탈로그 SQLite 경로
- `SUBMISSIONS_PATH`: 사용자 제보 JSON 저장 경로
- `CATALOG_ADMIN_API_KEY`: 관리자 API 보호 키

앱만 서버 API를 호출하는 현재 구조에서는 CORS가 필수는 아니지만, 추후 웹 관리자
화면을 만들 경우 `CARELOG_ALLOWED_ORIGINS`에 해당 도메인을 등록합니다.

## 데이터 검수 상태

- `draft`: 조사 중이며 앱에 노출하지 않음
- `reviewed`: 기본 검수 완료
- `verified`: 모델명과 주요 출처 확인 완료

기본 카탈로그는 `data/products.json`으로 관리하고, 운영 중 추가되는 제품은
`data/catalog_admin.db`의 검수 워크플로로 관리합니다. 앱에는 `reviewed`와
`verified` 제품만 노출됩니다.

- `data/products.json`: 관리법까지 검수 완료된 제품
- `data/models.json`: 제품 등록 단계에서 보여줄 브랜드별 모델 후보

모델 후보와 관리법 데이터는 분리합니다. 모델을 찾았더라도 관리법 근거가 충분하지 않으면 앱은 해당 제품군의 일반 관리법을 표시합니다.

## 출처와 검수 규칙

- 공개 제품은 하나 이상의 `sources`와 `reviewHistory`가 필요합니다.
- 숫자가 포함된 스펙은 `specSourceIds`로 근거 출처를 연결합니다.
- 관리 단계의 근거는 `stepSourceIds`로 연결합니다.
- 존재하지 않는 출처 ID를 참조하면 서버가 시작되지 않습니다.
- 마지막 검수 이력의 상태는 제품의 `reviewStatus`와 같아야 합니다.
# 운영 도구

카탈로그 품질 보고서:

```powershell
python manage.py catalog
```

실제 출시 준비 상태 검사:

```powershell
python manage.py release --allow-blocked
python manage.py release --product samsung-rm70f63r2a
python manage.py release --allow-blocked `
  --output ..\docs\RELEASE_READINESS_REFRIGERATORS.md
```

- 필수 자동 검사와 수동 증거를 함께 판정합니다.
- `FAIL` 또는 `BLOCKED`가 있으면 기본 종료 코드는 `2`입니다.
- 진행 중 보고서를 만들 때만 `--allow-blocked`를 사용합니다.
- 수동 증거는 `data/release_readiness.json`에 검증일, 검증자와 재현 가능한
  근거를 기록합니다.

접수된 사용자 제보:

```powershell
python manage.py submissions list
python manage.py submissions list --status received
```

제보 처리 상태 변경:

```powershell
python manage.py submissions update <tracking_token> investigating `
  --operator "reviewer@example.com" `
  --note "공식 설명서 대조 중"
```

관리자 인증이 준비되기 전에는 상태 변경 API를 외부에 공개하지 않는다.

## 운영 카탈로그

관리 API는 `CATALOG_ADMIN_API_KEY` 환경 변수가 없으면 비활성화됩니다.

```powershell
$env:CATALOG_ADMIN_API_KEY = "change-this-secret"
python -m uvicorn app.main:app --reload --port 8000
```

모든 관리 요청에는 `X-Admin-Key` 헤더가 필요합니다.

- `GET /v1/admin/products`: 상태별 제품 조회
- `PUT /v1/admin/products/{id}`: 초안 등록·수정
- `POST /v1/admin/products/{id}/transition`: 검수 상태 변경
- `DELETE /v1/admin/products/{id}`: 초안 삭제
- `GET /v1/admin/audit-log`: 변경 이력 조회
- `GET /v1/admin/submissions`: 사용자 제보 조회
- `POST /v1/admin/submissions/{trackingToken}/status`: 사용자 제보 상태 변경

제보 상태 변경 예시:

```powershell
$headers = @{ "X-Admin-Key" = $env:CATALOG_ADMIN_API_KEY }
$body = @{
  status = "investigating"
  operator = "reviewer@example.com"
  note = "공식 자료 확인 중"
} | ConvertTo-Json
Invoke-RestMethod `
  -Method Post `
  -Headers $headers `
  -ContentType "application/json" `
  -Body $body `
  http://127.0.0.1:8000/v1/admin/submissions/<trackingToken>/status
```

CLI에서도 같은 저장소를 관리할 수 있습니다.

```powershell
python manage.py managed-catalog import product.json `
  --operator "author@example.com" --note "공식 설명서 기반 초안"
python manage.py managed-catalog transition product-id reviewed `
  --operator "reviewer@example.com" --note "출처와 관리 단계 검수"
python manage.py managed-catalog transition product-id verified `
  --operator "verifier@example.com" --note "출시 승인"
python manage.py managed-catalog list --status verified
python manage.py managed-catalog audit --product product-id
python manage.py managed-catalog backup ..\backups\catalog_admin.db
python manage.py managed-catalog restore-drill `
  ..\backups\catalog_admin.db `
  ..\recovery-drill\catalog_admin.db
```

`/health`는 프로세스와 공개 카탈로그 로딩 상태를, `/ready`는 운영 SQLite
무결성과 제품·감사 로그 접근 가능 여부까지 확인한다. 배포 환경의 외부
모니터링은 `/ready`를 주기적으로 호출하도록 설정한다.

공개된 제품을 수정하려면 먼저 `draft`로 되돌려야 하며, 수정 후 다시 검수와
검증을 거쳐야 합니다.
