# Product Catalog API

검수된 제품 정보와 청소 관리법을 Flutter 앱에 제공하는 로컬 API입니다.

## 실행

```powershell
cd server
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- API 문서: `http://127.0.0.1:8000/docs`
- 상태 확인: `http://127.0.0.1:8000/health`
- 제품 검색: `http://127.0.0.1:8000/v1/products?q=DCS-HM4AG-W`
- 브랜드 조회: `http://127.0.0.1:8000/v1/brands?category=TV`
- 모델 조회: `http://127.0.0.1:8000/v1/models?category=TV&brand=삼성전자`

Android 에뮬레이터에서는 PC의 `localhost`가 `10.0.2.2`로 보입니다.

## 데이터 검수 상태

- `draft`: 조사 중이며 앱에 노출하지 않음
- `reviewed`: 기본 검수 완료
- `verified`: 모델명과 주요 출처 확인 완료

현재는 `data/products.json`을 Git으로 검수합니다. 제품 수가 늘면 PostgreSQL과 관리자 화면으로 교체할 수 있도록 API 계층을 분리했습니다.

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
