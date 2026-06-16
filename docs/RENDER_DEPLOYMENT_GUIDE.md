# Render 배포 가이드

- 생성일: 2026-06-16
- 대상 서비스: `carelog-api`
- 설정 파일: `render.yaml`

## 준비된 것

- Render Blueprint 파일을 저장소 루트에 추가했다.
- 서버 Dockerfile은 Render의 `PORT` 환경 변수를 사용하도록 변경했다.
- 런타임 데이터는 `/app/runtime`에 저장한다.
- 카탈로그 운영 DB와 사용자 제보 파일은 Render Persistent Disk에 저장한다.
- 관리자 API 키는 `render.yaml`에 직접 쓰지 않고 Render가 생성한다.

## Render에서 해야 할 일

1. Render 계정에 로그인한다.
2. GitHub 저장소를 Render에 연결한다.
3. New > Blueprint를 선택한다.
4. 이 저장소의 `render.yaml`을 선택한다.
5. `carelog-api` 서비스가 생성되는지 확인한다.
6. 첫 배포가 끝나면 서비스 URL을 확인한다.
7. 다음 주소들이 200으로 응답하는지 확인한다.

```text
https://<render-service-url>/health
https://<render-service-url>/ready
https://<render-service-url>/v1/products?q=DCS-HM4AG-W
```

## 앱 빌드에 넣을 값

Render 배포 후 앱 출시 빌드는 다음처럼 만든다.

```powershell
E:\AIP\flutter-sdk\bin\flutter.bat build appbundle --release `
  --dart-define=CATALOG_API_BASE_URL=https://<render-service-url>
```

## 운영 확인 항목

- [ ] `/health`가 정상이다.
- [ ] `/ready`가 정상이다.
- [ ] 제품 검색 API가 정상이다.
- [ ] 사용자 제보 접수가 정상이다.
- [ ] 관리자 API 키 없이 관리자 API가 거절된다.
- [ ] Render Dashboard에서 `CATALOG_ADMIN_API_KEY` 값을 안전하게 보관했다.
- [ ] Render Disk가 `/app/runtime`에 붙어 있다.
- [ ] 배포 후 재시작해도 제보 데이터가 유지된다.

## 비용 메모

이 설정은 Persistent Disk를 사용한다. 제보와 운영 카탈로그 DB를 유지하려면 무료 인스턴스만으로는 부족할 수 있으므로, Render Dashboard에서 실제 월 비용을 배포 전에 확인해야 한다.

## 참고한 Render 공식 문서

- Blueprint 파일은 기본적으로 저장소 루트의 `render.yaml`을 사용한다.
- Docker 서비스는 `runtime: docker`를 사용한다.
- 모노레포 구조는 `dockerfilePath`와 `dockerContext`로 Dockerfile과 빌드 컨텍스트를 지정할 수 있다.
- 비밀 환경 변수는 파일에 하드코딩하지 않고 `generateValue: true` 또는 `sync: false`를 사용한다.
- Web service의 상태 확인 경로는 `healthCheckPath`로 지정한다.
