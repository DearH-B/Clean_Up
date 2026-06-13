# 제품 대량 등록 사용법

## 목적

제품을 추가할 때 Flutter와 서버 코드를 직접 수정하지 않는다. `catalog_input`의 표만
채우고 변환 명령을 실행하면 앱 내장 카탈로그와 서버 카탈로그가 함께 생성된다.

## 입력 파일

`catalog_input` 폴더의 CSV 파일은 Excel에서 바로 열고 편집할 수 있다.

- `products.csv`: 제품 기본 정보와 검수 상태
- `sources.csv`: 공식 제품 페이지, 설명서, 영상 등 출처
- `steps.csv`: 사용자 관리 순서
- `specs.csv`: 용량, 크기, 출시 연도 등 확인된 스펙
- `lists.csv`: 준비물, 주의사항, 키워드와 모델 특징
- `consumables.csv`: 필터와 교체 소모품
- `recommendations.csv`: 특정 관리용품 추천
- `models.csv`: 이미지와 출시 연도로 고르는 모델 후보

각 표는 `productId`로 연결한다. 목록이 여러 개인 항목은 행을 추가한다. `supports`,
`sourceIds`, `features`처럼 한 셀 안에 여러 값을 넣을 때는 `|`로 구분한다.

## 등록 순서

1. 예시 행을 복제하고 제품 정보를 입력한다.
2. 조사 중에는 `publish=false`로 둔다.
3. 공식 자료와 관리법 검수가 끝나면 `publish=true`로 바꾼다.
4. 검증만 먼저 실행한다.

```powershell
cd server
python manage.py import-catalog ..\catalog_input --check
```

5. 오류가 없으면 앱·서버 생성 파일을 갱신한다.

```powershell
python manage.py import-catalog ..\catalog_input
```

6. Flutter 테스트와 서버 테스트를 실행한다.

## 생성되는 파일

- `server/data/imported_products.json`
- `server/data/imported_models.json`
- `lib/data/generated_product_catalog.dart`

세 파일은 직접 수정하지 않는다. 원본 표를 수정한 뒤 변환 명령을 다시 실행한다.
기존 내장 제품과 같은 제품 ID 또는 모델 식별값을 표에 등록하면 생성 데이터가
우선 적용된다. 따라서 기존 제품도 중복 노출 없이 차례로 표 기반 데이터로 옮길 수 있다.

## Excel 통합 문서 사용

같은 이름의 시트 8개를 가진 `.xlsx` 파일도 입력할 수 있다. 첫 행의 열 이름은 CSV와
같아야 한다.

```powershell
python manage.py import-catalog .\product_catalog.xlsx
```

## 오류를 막는 규칙

- 제품 ID는 중복될 수 없다.
- 공개 제품에는 출처와 관리 단계가 최소 1개씩 필요하다.
- 단계와 스펙의 `sourceIds`는 `sources` 표에 실제로 등록돼야 한다.
- 숫자와 참/거짓 값의 형식이 올바르지 않으면 생성하지 않는다.
- 생성 후 서버의 Pydantic 제품 스키마를 통과해야 한다.
