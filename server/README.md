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

Android 에뮬레이터에서는 PC의 `localhost`가 `10.0.2.2`로 보입니다.

## 데이터 검수 상태

- `draft`: 조사 중이며 앱에 노출하지 않음
- `reviewed`: 기본 검수 완료
- `verified`: 모델명과 주요 출처 확인 완료

현재는 `data/products.json`을 Git으로 검수합니다. 제품 수가 늘면 PostgreSQL과 관리자 화면으로 교체할 수 있도록 API 계층을 분리했습니다.
