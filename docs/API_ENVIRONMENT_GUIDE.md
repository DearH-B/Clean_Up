# API 환경 설정 가이드

- 생성일: 2026-06-16
- 앱 이름: 케어로그
- 목적: 개발, 테스트, 출시 빌드에서 서버 주소를 실수 없이 주입한다.

## 현재 앱 구조

Flutter 앱은 다음 빌드 변수를 사용한다.

```text
CATALOG_API_BASE_URL
```

이 값은 제품 검색, 모델 목록, 생활 문제 안내, 사용자 제보 접수에 공통으로 사용된다.

값을 넣지 않으면 기본값은 Android 에뮬레이터용 로컬 서버다.

```text
http://10.0.2.2:8000
```

## 로컬 개발 서버

PC에서 Docker 서버를 `18080` 포트로 띄운 경우:

```powershell
docker run -d `
  --name carelog-api-dev-test `
  -p 18080:8000 `
  -e CARELOG_ENV=docker-test `
  -e CATALOG_ADMIN_API_KEY=local-dev-secret `
  carelog-api-dev
```

Android 에뮬레이터에서 이 서버를 보려면 앱 빌드 시 다음 주소를 넣는다.

```powershell
E:\AIP\flutter-sdk\bin\flutter.bat run `
  --dart-define=CATALOG_API_BASE_URL=http://10.0.2.2:18080
```

## 일반 로컬 서버

PC에서 Python 서버를 `8000` 포트로 직접 띄운 경우:

```powershell
E:\AIP\flutter-sdk\bin\flutter.bat run `
  --dart-define=CATALOG_API_BASE_URL=http://10.0.2.2:8000
```

현재 앱의 기본값과 같기 때문에 `--dart-define`을 생략해도 된다.

## 출시 빌드

출시 빌드는 반드시 HTTPS 주소를 넣어야 한다.

```powershell
E:\AIP\flutter-sdk\bin\flutter.bat build appbundle --release `
  --dart-define=CATALOG_API_BASE_URL=https://api.example.com
```

출시 빌드에서 `http://10.0.2.2`, `localhost`, `127.0.0.1`을 사용하면 실제 휴대폰에서는 서버에 연결할 수 없다.

Render에 배포했다면 실제 서비스 URL을 사용한다.

```powershell
E:\AIP\flutter-sdk\bin\flutter.bat build appbundle --release `
  --dart-define=CATALOG_API_BASE_URL=https://<render-service-url>
```

## 출시 전 확인

- [ ] 운영 API 도메인이 HTTPS로 열린다.
- [ ] `/health`가 `200 OK`를 반환한다.
- [ ] `/ready`가 `200 OK`를 반환한다.
- [ ] 앱 제품 검색이 운영 서버 결과를 우선 사용한다.
- [ ] 앱 생활 문제 안내가 운영 서버 결과를 우선 사용한다.
- [ ] 앱 제품 정보 요청이 `접수` 상태로 바뀐다.
- [ ] 관리자 API 키 없이 `/v1/admin/submissions`가 거절된다.
- [ ] 관리자 API 키로 접수된 제보를 조회할 수 있다.
- [ ] 출시 빌드 명령에 `CATALOG_API_BASE_URL=https://...`가 들어간다.

## 다음에 결정할 값

- 스테이징 API URL:
- 운영 API URL: https://carelog-api.onrender.com
- 관리자 웹 URL:
- 외부 모니터링 URL:
- 운영 서버 호스팅 서비스:
