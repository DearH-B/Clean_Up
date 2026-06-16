# Phase 12: 출시 준비

## 코드로 완료한 항목

- 설정 탭과 데이터 관리 진입점
- 백업, 복원과 사용자 데이터 전체 삭제
- 개인정보·기기 데이터, 이용, 제품 정보 책임, 광고 표시 안내 초안
- 200% 큰 글자 설정 화면 회귀 테스트
- Android 다크 모드에서도 라이트 시작 화면 사용
- 출시 빌드의 디버그 키 서명 제거
- 출시 키 설정 템플릿
- 디버그 빌드만 로컬 HTTP 허용
- GitHub Actions Flutter·서버 품질 검사
- 서버 Docker 이미지와 상태 확인
- 운영 카탈로그 SQLite 안전 백업 명령

2026-06-14 기준 Docker 이미지를 실제 빌드하고 컨테이너의 `/health` 응답에서 공개
카탈로그 64개 로딩을 확인했다.

## 외부 결정이 필요한 차단 항목

- 정식 앱 이름, 패키지명과 아이콘
- 사업자 또는 운영 주체 정보
- 문의 이메일과 서비스 도메인
- 법률 검토가 끝난 개인정보처리방침과 이용약관
- Android 업로드 키와 Play Console 계정
- 오류 수집·서버 모니터링 서비스
- 실제 Android 기기와 iPhone 검증
- 카메라 OCR 대표 라벨 성공률 검증

## Android 서명 준비

1. 업로드 키를 안전한 위치에 생성한다.
2. `android/key.properties.example`을 참고해 `android/key.properties`를 만든다.
3. 키 파일과 비밀번호를 Git에 올리지 않는다.
4. `flutter build appbundle --release`로 AAB를 생성한다.
5. Play App Signing을 사용하고 업로드 키를 별도 백업한다.

키 설정이 없으면 release 산출물은 서명되지 않는다. 이전처럼 디버그 키로 정식
출시 파일이 만들어지지 않는다.

## 서버 운영

```powershell
cd server
docker build -t product-catalog-api .
docker run --rm -p 8000:8000 `
  -e CATALOG_ADMIN_API_KEY=replace-me `
  -v ${PWD}\runtime:/app/runtime `
  product-catalog-api
```

운영 DB 백업:

```powershell
python manage.py managed-catalog backup ..\backups\catalog_admin.db
```

별도 DB 복구 훈련:

```powershell
python manage.py managed-catalog restore-drill `
  ..\backups\catalog_admin.db `
  ..\recovery-drill\catalog_admin.db
```

이 명령은 원본을 덮어쓰지 않으며 SQLite 무결성, 제품 수와 감사 로그 수가
백업과 일치하는지 확인한다. 복구 목적지는 비어 있어야 한다.

Android 출시 사전 점검:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\release_preflight.ps1
```

정식 패키지명, 앱 이름, `key.properties`와 실제 업로드 키 파일이 준비되지
않았다면 차단 사유를 출력하고 종료 코드 2를 반환한다.
