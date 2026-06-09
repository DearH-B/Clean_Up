# iPhone 16 실기기 테스트

Flutter 앱은 iPhone 16에서 직접 테스트할 수 있다. 다만 iOS 앱의 빌드와
서명은 macOS와 Xcode가 필요하므로 현재 Windows PC만으로는 iPhone에 설치할
수 없다.

## 현재 개발 방침

- 당분간 Windows와 Android 에뮬레이터에서 기능을 개발하고 검증한다.
- 변경 사항은 Git과 GitHub에 꾸준히 저장한다.
- 앱의 주요 기능이 안정된 뒤 Mac을 준비해 iOS 프로젝트를 생성한다.
- iPhone 16에서 카메라, 키보드, 화면 배치, 권한과 데이터 저장을 다시 검증한다.

## 준비물

- macOS가 설치된 Mac
- Xcode와 Flutter SDK
- Apple ID
- USB 케이블 또는 같은 네트워크의 무선 디버깅
- 현재 Git 저장소

개인 iPhone에서 개발 테스트만 하는 경우 무료 Apple ID의 Personal Team을
사용할 수 있다. TestFlight 배포와 App Store 출시는 Apple Developer Program
가입이 필요하다.

## 이 프로젝트를 iPhone에서 실행하는 순서

1. GitHub에 현재 변경 사항을 올린다.
2. Mac에서 저장소를 clone한다.
3. 프로젝트 루트에서 iOS 플랫폼을 생성한다.

   ```bash
   flutter create --platforms=ios .
   ```

4. `ios/Runner/Info.plist`에 카메라 사용 설명을 추가한다.

   ```xml
   <key>NSCameraUsageDescription</key>
   <string>제품의 QR 코드와 바코드를 스캔하여 제품 정보를 찾기 위해 카메라를 사용합니다.</string>
   ```

5. `ios/Runner.xcworkspace`를 Xcode로 열고 Runner의 Signing & Capabilities에서
   자신의 Team을 선택한다.
6. iPhone에서 컴퓨터를 신뢰하고 개발자 모드를 활성화한다.
7. Xcode 또는 아래 명령으로 실행한다.

   ```bash
   flutter devices
   flutter run -d <iPhone device id>
   ```

현재 추가된 `mobile_scanner` 코드는 Android와 iOS를 모두 지원한다. 따라서
Mac에서 iOS 플랫폼과 카메라 권한만 구성하면 같은 QR·바코드 등록 흐름을
iPhone에서도 사용할 수 있다.

## Mac을 구했을 때 체크리스트

- [ ] Mac에 Xcode 설치
- [ ] Mac에 Flutter SDK와 Git 설치
- [ ] GitHub에서 프로젝트 clone
- [ ] `flutter doctor`로 개발 환경 확인
- [ ] `flutter create --platforms=ios .` 실행
- [ ] `flutter pub get` 실행
- [ ] `NSCameraUsageDescription` 추가
- [ ] Xcode에서 Apple Account와 Team 설정
- [ ] iPhone 16 연결 및 개발자 모드 활성화
- [ ] `flutter run`으로 실기기 실행
- [ ] QR·바코드 카메라 스캔 확인
- [ ] 제품 검색과 등록 확인
- [ ] 앱 재실행 후 저장 데이터 유지 확인
- [ ] 주요 화면의 글자 잘림과 키보드 입력 확인

## 배포 방식 선택

본인의 iPhone에서 개발 테스트만 하는 동안에는 무료 Apple Account를 사용할 수
있다. 여러 기기에 편하게 배포하거나 TestFlight와 App Store를 이용할 때 Apple
Developer Program 가입을 진행한다.
