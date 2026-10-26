# Hướng dẫn cho AI Agent: đăng MindKeeper lên Google Play & App Store

Tài liệu này là **runbook** để một AI Agent (hoặc người) tự động hóa tối đa việc đăng ứng dụng. Mọi tài sản đã được
sinh sẵn trong `store/`. Agent **không được tự ý**: tạo tài khoản, thanh toán, tạo/đổi khóa ký, đăng bản Production,
hoặc công khai email liên hệ — các bước đó thuộc **[CHỦ]** (xem phần "Điểm dừng bắt buộc").

## 0. Bản đồ tài sản

| Cần cho | Tệp / lệnh | Ghi chú |
|---|---|---|
| Nội dung trang (vi/en) | `store/listing/vi-VN.md`, `en-US.md` | Nguồn duy nhất; kiểm giới hạn `bash tool/store/check_listing.sh` |
| Cây fastlane (chữ + ảnh) | `SITE_URL=<url> bash tool/store/prepare_fastlane.sh` | Sinh `fastlane/metadata`, `fastlane/screenshots` |
| Lane fastlane | `fastlane/Fastfile` (`play_metadata`, `play_internal`, `play_promote`, `ios_metadata`, `ios_testflight`) | Cần biến môi trường (mục 2) |
| Icon Play 512 | `store/play/icon_512.png` | |
| Ảnh bìa Play | `store/play/feature_graphic_1024x500.png` | |
| Ảnh chụp Android | `store/screenshots/android_phone/*.png` (1080×1920) | |
| Ảnh chụp iPhone / iPad | `store/screenshots/ios_6.7/`, `ios_6.5/`, `ios_5.5/`, `ipad_12.9/` | |
| Icon App Store | `store/appstore/icon_1024.png` | không trong suốt |
| Video giới thiệu | `store/video/app_preview_1080x1920.mp4` (Play/YouTube), `app_preview_886x1920.mp4` (App Store) | Dựng lại: `bash tool/brand/make_preview_video.sh` |
| Khai báo Play | `store/play/declarations.md`, `store/play/data_safety.md` | Trả lời từng mục trong console |
| Khai báo Apple | `store/appstore/privacy_labels.md` | |
| Chính sách quyền riêng tư | `site/` → GitHub Pages (`.github/workflows/pages.yml`) | Cần `CONTACT_EMAIL`, `DEVELOPER_NAME` |
| Danh sách đánh dấu | `store/RELEASE_CHECKLIST.md` | Tích `[x]` khi xong |

Dựng lại toàn bộ đồ họa (icon, splash, khung ảnh): xem `store/README.md`.

## 1. Thứ tự thực hiện

1. **Chính sách quyền riêng tư**: đặt Repository variables `CONTACT_EMAIL`, `DEVELOPER_NAME` → bật Pages (Source = GitHub Actions) →
   chạy workflow "Publish site" → lấy `SITE_URL` (`https://<tài-khoản>.github.io/mind_keeper`). Kiểm tra `…/privacy/` trả HTTP 200.
2. `SITE_URL=<url> bash tool/store/prepare_fastlane.sh`.
3. **Build** (mục 3). 
4. **Google Play**: tạo app trong Console → điền khai báo (mục 4) → `fastlane android play_metadata` → `fastlane android play_internal`
   → kiểm thử → `fastlane android play_promote` (sau closed testing nếu tài khoản cá nhân mới).
5. **App Store**: tạo app (Bundle ID `com.mindkeeper.mindKeeper`) → khai báo App Privacy → `fastlane ios ios_metadata` →
   `fastlane ios ios_testflight` (trên Mac) → chọn build → gửi duyệt.
6. Cập nhật `store/RELEASE_CHECKLIST.md` (đánh dấu `[x]`) và ghi kết quả vào `DOCS/IMPLEMENTATION_PROGRESS.md`.

## 2. Biến môi trường / bí mật (KHÔNG commit)

| Biến | Dùng cho | Lấy ở đâu |
|---|---|---|
| `PLAY_JSON_KEY_PATH` | fastlane supply | Play Console → Setup → API access → service account → JSON key (cấp quyền "Release manager") |
| `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_PATH` | fastlane deliver / testflight | App Store Connect → Users and Access → Integrations → API key (.p8) |
| `android/key.properties` + `*.jks` | ký AAB | Chủ tự tạo (checklist mục C) |
| `DEEPSEEK_BASE_URL`, `DEEPSEEK_PROXY_MODE=true` | AI ở bản phát hành | URL proxy backend của chủ; **không** nhúng khóa API |

## 3. Build

```bash
flutter pub get
flutter analyze && flutter test
flutter build appbundle --release \
  --dart-define=DEEPSEEK_BASE_URL=<proxy> --dart-define=DEEPSEEK_PROXY_MODE=true
# Ký kiểm tra
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab | head
```
Nếu thiếu `android/key.properties`, gradle sẽ ký bằng khóa **debug** — AAB đó **không được** tải lên Play.
iOS: `flutter build ipa --release` (chỉ trên macOS).

## 4. Điền khai báo trong Google Play Console (đánh dấu trong giao diện)

Làm lần lượt theo menu **Policy → App content** (tất cả trả lời có sẵn trong `store/play/declarations.md`):
1. Privacy policy → dán `<SITE_URL>/privacy/`.
2. Ads → "No, my app does not contain ads".
3. App access → "All functionality is available without special access".
4. Content rating → làm bảng câu hỏi IARC, danh mục *Reference, News or Educational*, mọi câu "No".
5. Target audience and content → chọn nhóm tuổi 13+ (không chọn dưới 13), "không hấp dẫn trẻ em".
6. Data safety → điền theo `store/play/data_safety.md` (bảng "Loại dữ liệu"; chọn "Data is encrypted in transit").
7. Government/Financial/Health apps → "No / Not applicable".
8. Permissions declarations (nếu console hiện): Exact alarm → lý do "lời nhắc người dùng đặt".
9. Store listing → fastlane đã điền chữ + ảnh; **thêm video**: dán URL YouTube; chọn *Category = Education*; email/website liên hệ.
Console không có API cho Data safety/Content rating → agent dùng trình duyệt (Claude in Chrome / computer-use) hoặc chuyển bước cho chủ.

## 5. Điền khai báo trong App Store Connect
App Privacy (theo `store/appstore/privacy_labels.md`), Age Rating (tất cả "None" → 4+), Pricing = Free,
App Information (Category Education/Productivity, Privacy Policy URL), Review notes (không cần tài khoản; AI cần mạng),
Export compliance (đã khai trong Info.plist). Ảnh + chữ do `fastlane ios ios_metadata` đẩy lên.

## 6. Điểm dừng bắt buộc (agent phải hỏi chủ)
- Trước khi tạo tài khoản, thanh toán, hoặc nhập thông tin định danh/thuế.
- Trước khi tạo hay thay **keystore / khóa API / service account**.
- Trước khi công khai **email/tên** lên trang chính sách và cửa hàng.
- Trước **Production release / Submit for Review** (không thể rút lại ngay).
- Khi cửa hàng từ chối: đọc lý do, sửa theo `store/*`, không "lách" chính sách.

## 7. Tiêu chí xong
- Trang chính sách trả 200; mọi mục trong `store/RELEASE_CHECKLIST.md` thuộc A–E đã `[x]`.
- Play: bản ở Internal/Closed/Production đúng `versionCode`; không còn cảnh báo "App content".
- App Store: build xử lý xong ở TestFlight, trang đủ ảnh, trạng thái "Waiting for Review".
