# Share Extension iOS cho Quick capture

> Trạng thái: **code + CI đã viết, CHƯA có kết quả CI macOS, CHƯA chạy trên Mac/iPhone.**
> Máy phát triển là Windows nên không biên dịch được Swift/Xcode ở đây. "CI macOS xanh" (khi có) chỉ chứng minh biên dịch và đóng gói, **không** chứng minh share sheet thật hoạt động.

## 1. Phạm vi
- Có: Share Extension nhận văn bản và URL http(s); App Group; URL scheme `mindkeeper`; cầu nối `ShareBridge.swift` cùng channel `mindkeeper/share`; target Xcode + embed; job CI macOS; docs.
- Không: ảnh/PDF, cloud backup, mã hóa, AI, đổi Android, đổi bundle ID, thêm package.
- Logic thông báo iOS (`UNUserNotificationCenter.delegate` trong `AppDelegate`) giữ nguyên.

## 2. Kiến trúc
```
Safari/Notes/... --share--> ShareExtension (ShareViewController)
   1. đọc NSExtensionItem: attributedContentText, attributedTitle, attachments
      (chỉ UTType.plainText và UTType.url http/https; ưu tiên URL, text chưa chứa URL thì "text\nURL")
   2. ghi {id UUID, text, subject, createdAt} vào UserDefaults(suiteName: group.com.mindkeeper.mindKeeper)
   3. mở app: extensionContext.open(mindkeeper://share?id=<uuid>);
      nếu thất bại → responder chain gọi openURL:options:completionHandler: / openURL: bằng selector
      (không dùng UIApplication.shared)
   4. completeRequest
Runner:
   - SceneDelegate.scene(_:openURLContexts:) và AppDelegate.application(_:open:options:) → ShareBridge.handleIncoming
   - ShareBridge (FlutterPlugin, đăng ký trong didInitializeImplicitFlutterEngine):
       getInitialShared → đọc + xóa payload → {text, subject} hoặc null  (cold start)
       handleIncoming   → nếu Dart đã sẵn sàng: đọc + xóa payload → invoke onShared (warm start)
Dart: không đổi contract; ShareIntake → AppShell → QuickCaptureScreen điền sẵn.
```
Chống trùng / an toàn:
- Payload bị xóa ngay khi đọc → mỗi lần chia sẻ giao đúng một lần; ghi nhớ `lastDeliveredId`.
- Cold start: URL tới trước khi Dart sẵn sàng thì payload để nguyên trong App Group cho `getInitialShared` lấy (không bắn `onShared` vào handler chưa đăng ký).
- URL mở app mà không có payload (hoặc payload quá 1 giờ) → bỏ qua, không lỗi.
- Hủy share: extension không ghi gì nếu người dùng hủy/không có nội dung → không crash.

## 3. File thay đổi
| File | Nội dung |
|---|---|
| `ios/ShareExtension/ShareViewController.swift` | Extension: đọc nội dung, ghi App Group, mở app |
| `ios/ShareExtension/Info.plist` | `com.apple.share-services`, `$(PRODUCT_MODULE_NAME).ShareViewController`, rule: text + web URL tối đa 1 |
| `ios/ShareExtension/ShareExtension.entitlements`, `ios/Runner/Runner.entitlements` | App Group `group.com.mindkeeper.mindKeeper` |
| `ios/Runner/ShareBridge.swift` | Cầu nối Flutter (channel `mindkeeper/share`) |
| `ios/Runner/AppDelegate.swift`, `SceneDelegate.swift` | Đăng ký bridge, nhận URL |
| `ios/Runner/Info.plist` | `CFBundleURLTypes` scheme `mindkeeper` |
| `ios/Runner.xcodeproj/project.pbxproj` | Target `ShareExtension` (bundle `com.mindkeeper.mindKeeper.ShareExtension`, iOS 15.5, `APPLICATION_EXTENSION_API_ONLY=YES`, `SKIP_INSTALL=YES`, `SWIFT_VERSION=5.0`, `TARGETED_DEVICE_FAMILY="1,2"`), phase "Embed Foundation Extensions" đặt trước "Thin Binary", target dependency, `CODE_SIGN_ENTITLEMENTS`. Không có `DEVELOPMENT_TEAM`. |
| `.github/workflows/ci.yml` | Job `ios-build` (macos-latest, 45 phút): `pod install`, `flutter build ios --simulator --debug --no-codesign`, kiểm tra `Runner.app/PlugIns/ShareExtension.appex` + Info.plist + URL scheme |
| `lib/core/services/share_intake.dart` | Chỉ cập nhật comment (iOS không còn bị bỏ qua) |

pbxproj sửa thủ công (script, ID `A1B2C3D4E5F60718293A4B01..15` duy nhất, đã kiểm tra cân bằng ngoặc và mọi ID xuất hiện ≥ 2 lần). Bản sao lưu trước khi sửa nằm ngoài repo.

## 4. Kết quả
| Hạng mục | Kết quả |
|---|---|
| `flutter analyze` | 0 error, 7 warning cũ giữ nguyên (27 issue tổng như trước) |
| `flutter test test/features/quick_capture_test.dart` | 11/11 pass |
| Android CPH2325 (`T4E6S8IFU4AQBM8L`) | Share text+link: cold start (app bị giết) và warm start đều mở "Lưu nhanh" điền sẵn; mã Android không đổi (chỉ chạy lại, không lưu dữ liệu) |
| Plist/entitlements | Hợp lệ (`plistlib` parse OK) |
| **CI macOS (`ios-build`)** | **Chưa chạy.** Chưa push vì CI chỉ chạy trên `master`/PR; xem mục 6 |

## 5. Chưa verify (cần Mac/iPhone thật)
- Biên dịch Swift/Xcode thực tế (pbxproj thủ công chưa từng được Xcode mở).
- `extensionContext.open` / responder-chain fallback có thực sự mở được app từ Share Extension trên iOS thật (đặc biệt iOS 18+ hạn chế `openURL:`). Nếu cả hai bị chặn, app vẫn nhận payload ở lần mở kế tiếp (payload nằm trong App Group tối đa 1 giờ).
- Share text/link cold + warm mở Quick capture đúng một lần; hủy share không crash.
- Ký số với App Group (cần Apple Developer Team + đăng ký App Group và bật capability cho cả 2 App ID `com.mindkeeper.mindKeeper` và `com.mindkeeper.mindKeeper.ShareExtension`).
- Hành vi thông báo iOS (không đổi logic, chỉ đảm bảo vẫn biên dịch).

## 6. Cách test thủ công trên Mac/iPhone
1. `flutter pub get && cd ios && pod install`, mở `ios/Runner.xcworkspace`.
2. Chọn Team cho **cả hai** target (Runner, ShareExtension); bật capability App Group `group.com.mindkeeper.mindKeeper` cho cả hai.
3. Chạy Runner trên iPhone. Mở Safari → Chia sẻ → "MindKeeper": app mở màn "Lưu nhanh" với link điền sẵn (warm).
4. Vuốt tắt app, lặp lại (cold). Kiểm tra chỉ một màn Lưu nhanh, bấm Lưu nhanh rồi chia sẻ lại cùng link → báo trùng.
5. Chia sẻ rồi bấm Hủy → không crash, không mở app.
6. Chạm một thông báo khi app bị tắt → vẫn mở đúng màn.

## 7. Yêu cầu App Group / Team
- Apple Developer Program, App Group `group.com.mindkeeper.mindKeeper`, hai App ID có capability App Groups.
- Repo không chứa Team ID hay secret.
