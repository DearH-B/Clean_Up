# iPhone 16 실기기 테스트

Flutter 앱은 iPhone 16에서 직접 테스트할 수 있다. 다만 iOS 앱의 빌드와
서명은 macOS와 Xcode가 필요하므로 현재 Windows PC만으로는 iPhone에 설치할
수 없다.

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
