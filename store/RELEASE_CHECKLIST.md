# Danh sách kiểm tra phát hành (Google Play + App Store)

Đánh dấu `[x]` khi xong. Mục **[CHỦ]** chỉ chủ ứng dụng làm được (tài khoản, thanh toán, khóa bí mật, xác minh danh tính).

## A. Tài khoản & định danh
- [ ] **[CHỦ]** Tài khoản Google Play Console (phí một lần 25 USD) — xác minh danh tính/số điện thoại/địa chỉ.
- [ ] **[CHỦ]** Apple Developer Program (99 USD/năm) — cần máy Mac để build iOS.
- [ ] **[CHỦ]** Quyết định email liên hệ công khai + tên nhà phát triển (sẽ hiện trên trang chính sách và cửa hàng).
- [ ] Đặt biến Repository (Settings → Variables): `CONTACT_EMAIL`, `DEVELOPER_NAME`; bật Pages (Source = GitHub Actions) → ghi lại `SITE_URL`.

## B. Mã nguồn & cấu hình
- [x] Icon mới (`assets/images/app_icon*.png`, mipmap, iOS AppIcon) — sinh bằng `tool/brand/render_brand_test.dart` + `dart run flutter_launcher_icons`.
- [x] Màn hình khởi động: Android (`launch_background`, Android 12 `values-v31`), iOS (`LaunchImage`), trong app (`SplashOverlay`).
- [x] Nhãn ứng dụng: `MindKeeper` (Android label, iOS display name).
- [x] Màn "Quyền riêng tư & điều khoản" trong Hồ sơ.
- [x] Nút "Báo nội dung" (yêu cầu chính sách AI của Play).
- [ ] **[CHỦ]** Cấu hình AI cho bản phát hành: dùng **proxy backend** (`--dart-define=DEEPSEEK_BASE_URL=...` + `DEEPSEEK_PROXY_MODE=true`). **Không** nhúng khóa API vào ứng dụng.
- [ ] Quyết định Firebase: dùng FCM thì thêm `google-services.json` / `GoogleService-Info.plist`; không dùng thì gỡ `firebase_*` khỏi `pubspec.yaml` (đơn giản hóa Data safety).
- [ ] Tăng `version:` trong `pubspec.yaml` (`1.0.0+1` → `1.0.0+2`… mỗi lần tải lên).

## C. Ký bản build
- [ ] **[CHỦ]** Tạo upload keystore (một lần, GIỮ BÍ MẬT, sao lưu ở nơi an toàn):
  `keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
- [ ] Tạo `android/key.properties` (đã nằm trong `.gitignore`):
  ```
  storePassword=...
  keyPassword=...
  keyAlias=upload
  storeFile=C:/đường/dẫn/upload-keystore.jks
  ```
- [ ] `flutter build appbundle --release --dart-define=DEEPSEEK_BASE_URL=<proxy> --dart-define=DEEPSEEK_PROXY_MODE=true`
- [ ] Kiểm tra AAB đã ký khóa upload (không phải debug): `jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab`
- [ ] iOS (trên Mac): `flutter build ipa --release`, ký bằng Distribution certificate + provisioning profile.

## D. Trang cửa hàng
- [x] Nội dung: `store/listing/vi-VN.md`, `en-US.md` (kiểm giới hạn: `bash tool/store/check_listing.sh`).
- [x] Icon 512 / 1024, ảnh bìa 1024×500, ảnh chụp điện thoại/iPhone/iPad, video giới thiệu (`store/`).
- [ ] Sinh cây fastlane: `SITE_URL=<url> bash tool/store/prepare_fastlane.sh`.
- [ ] Tải video lên YouTube (không niêm yết) → dán link vào Play Console (Play không nhận tệp video).

## E. Khai báo bắt buộc
- [ ] Play: Chính sách quyền riêng tư, Quảng cáo=Không, Đối tượng mục tiêu, An toàn dữ liệu, Đánh giá nội dung, Danh mục — xem `store/play/declarations.md`, `store/play/data_safety.md`.
- [ ] Apple: App Privacy, độ tuổi 4+, Encryption (`ITSAppUsesNonExemptEncryption=NO` đã có), Review notes — xem `store/appstore/privacy_labels.md`.

## F. Kiểm thử trước khi gửi
- [x] `flutter analyze` / `flutter test` xanh.
- [x] Maestro GĐ23 trên thiết bị thật (`maestro/gd23/run.sh`).
- [ ] **Thông báo hẹn giờ trên máy OPPO/Realme/Xiaomi**: bật "Tự khởi chạy" + bỏ tối ưu pin rồi kiểm tra thông báo mở rộng + nút "Đã hiểu" + chạm mở đúng mẩu (chưa xác nhận được trên CPH2203 — xem DOCS/IMPLEMENTATION_PROGRESS.md mục GĐ23).
- [ ] Closed testing (Play cá nhân mới): ≥ 12 người thử, ≥ 14 ngày liên tục.

## G. Gửi duyệt
- [ ] Play: Internal → Closed → Production (`fastlane play_internal`, `play_promote`).
- [ ] App Store: TestFlight → `fastlane ios_metadata` → bấm "Submit for Review" (**[CHỦ]** hoặc agent nếu đã được ủy quyền).
