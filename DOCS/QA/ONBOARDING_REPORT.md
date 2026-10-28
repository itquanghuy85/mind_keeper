# Báo cáo nghiệm thu: Onboarding 60 giây (2026-10-28)

Thiết bị: OPPO **CPH2325** (`T4E6S8IFU4AQBM8L`). Bằng chứng: `DOCS/QA/evidence/v3/` (ảnh trong `screens/`).

## 1. Đã làm
| File | Nội dung |
|------|----------|
| `lib/features/onboarding/onboarding_service.dart` | `shouldShow` (cài mới và chưa onboarding), nhận biết người dùng cũ (DB đã có chủ đề → tự đánh dấu hoàn tất), `seedFor` (mỗi chủ đề 1 entry `DiscoveryCatalog`, lưu bằng `DiscoveryService.saveEntry`, **không gọi AI**, không nhân bản khi gọi lại, tối đa 3), `savePreferences` |
| `lib/features/onboarding/onboarding_screen.dart` | 3 bước: (1) giá trị + "Bắt đầu"; (2) chọn 2–3 chủ đề từ `DiscoveryCatalog.categories` + cấp độ Cơ bản/Nâng cao/Pro/Master; (3) giờ nhắc + công tắc + xin quyền thông báo → "Xong". Có "Bỏ qua" ở mọi bước; chế độ `review` (Xem lại giới thiệu) không tạo lại dữ liệu |
| `lib/features/onboarding/home_gate.dart`, `lib/app.dart` | Cổng trước `AppShell` (route `/`) |
| `lib/features/profile/profile_screen.dart` | Mục "Xem lại giới thiệu" |
| `lib/features/courses/add_course_screen.dart` | Cấp độ mặc định của khóa học mới lấy từ `prefs.defaultCourseLevel` |
| `lib/core/services/preferences_service.dart` | `onboardingCompleted`, `defaultCourseLevel` (thêm ở commit sao lưu) |
| `test/features/onboarding_test.dart`, `test/widget_test.dart` | 9 test mới / cập nhật |
| `maestro/v3/b_onboarding.yaml`, `b2_skip.yaml`, `b3_review.yaml`, `b4_legacy.yaml` | Flow nghiệm thu |

Lưu: `onboarding_completed`, `reminder_hour/minute`, `notifications_enabled` (= bật và đã được cấp quyền), `default_course_level`. Thiếu quyền thông báo: **không chặn**, tắt cờ nhắc, hiện trạng thái rõ ("Quyền thông báo: chưa được cấp…") và snackbar hướng dẫn bật sau.

## 2. Kết quả
- `flutter analyze`: 0 error, 7 warning có sẵn (27 issue tổng, không mới).
- `flutter test`: `onboarding_test` **9/9**, `widget_test` 1/1, `course_ui_test` 8/8, `navigation_entry_test` 3/3.
  - Gồm: cài mới cần onboarding; người dùng cũ không bị chặn và tự đánh dấu; `seedFor` tạo kiến thức + thẻ due ngay, không nhân bản, tối đa 3; luồng widget chọn 2 chủ đề → Xong; thiếu quyền thông báo không chặn; Bỏ qua không tạo dữ liệu.
- Maestro (CPH2325), các flow đều PASS: `b_onboarding` (`maestro_b_onboarding.log`), `b2_skip`, `b3_review`, `b4_legacy` (`maestro_b*.log`).

### Trên máy thật
1. **Cài mới thật** (`adb uninstall` + `install`; quyền thông báo `granted=false` lúc đầu): intro → chọn Khoa học + Lịch sử + Nâng cao → bước 3 bấm "Cho phép thông báo" (hộp thoại hệ thống, Maestro bấm "Cho phép") → "Quyền thông báo: đã cấp." → Xong → vào Trang chủ (`screens/v3_b_1…4_*.png`).
2. **Thời gian** (`b_command_timeline.txt`, `b_timing.txt`): từ lúc màn giới thiệu hiện ra (27,9 s sau khi bấm mở app — khởi động lạnh app lần đầu chậm trên máy này) đến khi vào Trang chủ: **37,7 s** với Maestro (mỗi thao tác chạm ~3–4 s do Maestro; người dùng thật nhanh hơn); tổng từ lúc mở app đến Trang chủ **65,9 s**.
3. **Dữ liệu mẫu**: 2 chủ đề offline (`catalog:disc_space` "Vũ trụ có bao nhiêu hành tinh?" 2 kiến thức/2 thẻ, `catalog:disc_printing` "Một phát minh thay đổi thế giới" 1 kiến thức/1 thẻ) — thẻ due ngay; không có cấu hình AI nên không thể gọi AI. Prefs: `onboarding_completed=true`, `default_course_level=advanced`, `notifications_enabled=true`, nhắc 20:00 (`b_prefs_after.xml`).
4. **Bỏ qua** (`b2_skip`): vào Trang chủ trống, `onboarding_completed=true`, 0 chủ đề.
5. **Xem lại giới thiệu** (`b3_review`): hiển thị lại 3 bước, đổi cấp độ sang Pro (`default_course_level=pro`), số chủ đề trước/sau đều **0** → không seed lại (`b_skip_review_legacy_run.txt`).
6. **Người dùng cũ** (`b4_legacy`): DB có 2 chủ đề nhưng không có cờ onboarding → vào thẳng Trang chủ, không thấy "Bước 1/3", cờ được tự đặt `true`.

## 3. Rủi ro / ghi chú
- Nhánh **từ chối quyền thông báo** được kiểm bằng widget test (`FakeNotificationService.permissionsGranted=false`); trên máy thật quyền được cấp vì không thể `pm revoke` qua adb (ColorOS chặn).
- Chọn 2–3 chủ đề tạo nội dung theo entry đầu tiên chưa lưu của mỗi nhóm (catalog hiện có ít entry/nhóm).
- Cài mới đo trên máy khởi động chậm (~28 s tới màn đầu); phần onboarding tự nó ~38 s với Maestro.
- iOS chưa verify.
