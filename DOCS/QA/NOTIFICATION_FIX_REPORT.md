# Báo cáo sửa lỗi thông báo kiến thức & lịch thông báo

Ngày nghiệm thu: 2026-10-28. Thiết bị: OPPO **CPH2325** (`T4E6S8IFU4AQBM8L`, Android 13, ColorOS). Bằng chứng nằm ở `DOCS/QA/evidence/`.

## 1. File đã sửa
| File | Thay đổi |
|------|----------|
| `lib/core/services/notification_service.dart` | Thêm `_withBigText()`; thông báo nhắc kiến thức (`scheduleKnowledgeReminder`), nội dung mới (`scheduleContentNotification`, `lesson:`/`quick:`) và thẻ ôn (`scheduleCardDueAt`) dùng `BigTextStyleInformation(body, contentTitle: title)`. |
| `lib/core/services/notification_router.dart` | Bỏ `payload.id!`: payload thiếu `id` rơi về phiên ôn tập thay vì crash. |
| `lib/features/profile/notification_settings_screen.dart` | Nút debug "Kiểm thử thông báo": `skipDuplicateCheck: true` (lần bấm thứ hai bị `ValidationException` do kiến thức trùng, không có catch → không lập lịch, không có snackbar). |
| `ios/Runner/AppDelegate.swift` | `UNUserNotificationCenter.current().delegate = self` để flutter_local_notifications nhận chạm thông báo. **Chưa verify iOS.** |
| `maestro/notif/*.yaml` | Flow nghiệm thu mới (10 tạo bài học mẫu, 20/21 cold start course/lesson, 30 lên lịch thông báo thẻ). |

`dart format` đã chạy trên 3 file Dart (formatter đổi thêm một số dòng không thuộc thay đổi logic).

## 2. Đã kiểm tra, không cần sửa
- `ReviewController.rate()` hủy lịch cũ + lập lại theo `dueAt` mới; lỗi thông báo trong try/catch, không mất dữ liệu ôn tập.
- Cold/warm start: `_launchPayload` phát lại khi `setOnNotificationOpened` đăng ký → `AppBootstrap.pendingNotificationPayload` → `AppShell._handlePendingPayload`.
- `KnowledgeReminderScheduler.sync()`: title = tên bài, body = snippet (≤160 ký tự), payload `lesson:<id>`.

## 3. Router: payload → màn hình
| Payload | Màn hình |
|---------|----------|
| `card:<id>` | `ReviewScreen(targetCardId)` |
| `lesson:<id>` | `LessonReaderScreen` |
| `course:<id>` | `CourseReaderScreen` |
| `quick:<id>`, `article`, `quick_info` | `KnowledgeDetailScreen` |
| `review`, `review_due`, thiếu id, không rõ | `ReviewScreen` (phiên chung) |

## 4. Kết quả kiểm tra

### flutter analyze (toàn dự án)
0 error, 7 warning, 27 issue tổng. Cả 7 warning đều có sẵn, không thuộc file đã sửa: `firebase_messaging_service.dart` (unused import `notification_router.dart`, unused field `_available`) và `test/features/layout_overflow_test.dart` (5 unused import/element). Phần còn lại là info (`avoid_print` trong `tool/`, doc comment…).

### flutter test (từng file, timeout 180 giây; log: `evidence/flutter_test_per_file.txt`)
- 34 file: **31 file pass = 223 test passed**.
- `test/features/learned_library_enrolled_test.dart`: lần đầu 1 pass / 1 fail, chạy lại riêng **2/2 pass** → flaky, +2 → tổng **225 passed**.
- `test/features/layout_overflow_test.dart`: **0 pass / 3 fail** (`pumpAndSettle timed out` ở `TodayScreen`). **Có sẵn**: chạy lại khi cất 4 file thay đổi của phiên này (HEAD) cho kết quả y hệt (+0 -3). Không do thay đổi thông báo. (Mục "Cập nhật phiên sửa lỗi" cũ trong IMPLEMENTATION_PROGRESS ghi file này đã sửa; hiện không còn đúng.)
- `test/features/study_plan_screen_test.dart`: chạy riêng, **timeout 180 giây (rc=124), 0 test hoàn tất** → xác nhận treo có sẵn (đã ghi nhận từ trước ở GĐ23).
- Skipped: 0.

### Maestro trên CPH2325
| Flow | Kết quả | Log / ảnh |
|------|---------|-----------|
| `maestro/cph2239/01_smoke.yaml` (qua `run.sh`) | PASS exit=0 | `evidence/maestro_cph2239_smoke.log` |
| `maestro/gd23/02_add_course.yaml` (mock AI) | PASS | `evidence/maestro_gd23_02_add_course.log`, `evidence/maestro_screens/gd23_02_*.png` |
| `maestro/notif/10_create_sample_lesson.yaml` (mock AI) | PASS | `evidence/maestro_10_create_lesson.log`, `maestro_screens/notif_10_lesson_created.png` |
| `maestro/notif/20_course_cold_start.yaml` | PASS | `evidence/maestro_20_course_cold.log`, `maestro_screens/notif_20_course_cold_opened.png` |
| `maestro/notif/21_lesson_cold_start.yaml` | PASS | `evidence/maestro_21_lesson_cold.log`, `maestro_screens/notif_21_lesson_cold_opened.png` |
| `maestro/notif/30_schedule_card_notification.yaml` | PASS | `evidence/maestro_30_schedule_card.log` |

Dữ liệu mẫu tạo bằng `tool/mock_ai_server.js` (không gọi AI thật, không dùng key); APK nghiệm thu build với `--dart-define=DEEPSEEK_BASE_URL=http://127.0.0.1:8765/v1 --dart-define=DEEPSEEK_PROXY_MODE=true`.

### Thông báo thật trên máy (quyền thông báo do người dùng cấp)
| Loại | Hiển thị | Chạm warm start | Chạm cold start |
|------|----------|-----------------|-----------------|
| Thẻ ôn `card:` (`scheduleCardDueAt`) | `evidence/card_notif_collapsed.png`; `notif_dumpsys_card.txt`: `BigTextStyle`, bigText đủ | `evidence/card_warm_opened.png` | `evidence/card_cold_opened.png` (am kill, chạm thông báo thật) |
| Nhắc kiến thức `lesson:` (id 700000/700001, kênh `mind_keeper_review`) | `evidence/lesson_notif_collapsed.png`, `lesson_notif_expanded.png`; `notif_dumpsys_after_lesson.txt`: `BigTextStyle`, bigText | `evidence/lesson_warm_opened.png` (LessonReaderScreen) | `evidence/lesson_cold_opened.png` (am kill, chạm thông báo thật) |
| Khóa học `course:` (kênh `mind_keeper_course`) | `evidence/course_notif_collapsed.png` / `course_notif_expanded.png`: title, body, bigText, footer "Mẩu 1/4 · Chưa kiểm chứng", nút "Đã hiểu"/"Đọc đầy đủ"; `notif_dumpsys_after_course.txt` | `evidence/course_warm_opened.png` (CourseReaderScreen, Mẩu 1/4) | Qua `am start -a SELECT_NOTIFICATION --es payload course:<id>` + flow 20 (cùng đường đi plugin; **không** phải chạm thật vì thông báo khóa học thứ hai không nổ trong cửa sổ chờ) |

Giới hạn trung thực:
- Hầu hết nội dung mẫu ngắn nên thu gọn/mở rộng nhìn giống nhau; bằng chứng BigText chủ yếu là `dumpsys notification` (`android.template=BigTextStyle`, `android.bigText`). Thông báo khóa học tự hiện ở dạng mở rộng (thấy bigText + nút).
- "Gửi ngay" (`showNow`) không dùng BigText (chỉ dùng cho nút debug), chủ ý không đổi.
- Cold start course dùng intent mô phỏng như đã nêu trên.

### Dọn dẹp sau nghiệm thu
- DB trên máy khôi phục về rỗng: `topics`, `knowledge_items`, `review_cards`, `study_feed_items`, `courses`, `course_items`, `lessons`, `knowledge_reminder_history` đều = 0 (kiểm bằng sqlite sau khi mở lại app); gồm cả dữ liệu do nút debug tạo ở phiên trước.
- `shared_prefs` về đúng bản gốc (`evidence/prefs_before.xml` / `prefs_after.xml`); công tắc "Proactive knowledge reminders" tắt (không còn khóa `knowledge_reminder_*`).
- Đã cài lại APK debug thường (không trỏ mock AI), dừng mock server, gỡ `adb reverse`. Ảnh sau dọn: `evidence/after_cleanup_home.png`.

## 5. Quyết định đã chốt
- **Báo thức thẻ ôn giữ inexact** (`AndroidScheduleMode.inexactAllowWhileIdle`). Độ trễ khoảng 90 giây trên CPH2325 (`windowLength` ≈ 89 000 ms; nhắc kiến thức ≈ 147 000 ms) là **hành vi đã chấp nhận**, không đổi sang exact alarm.
- **Chưa verify iOS** (không có Mac). `AppDelegate.swift` chỉ đặt `UNUserNotificationCenter.current().delegate = self`, không override `didReceive` thủ công nên không chặn plugin. `Info.plist` không đổi (quyền xin lúc chạy). Giới hạn 64 pending notification chưa kiểm.

## 6. Việc còn lại / rủi ro
- iOS chưa verify (nút "Đã hiểu"/"Đọc đầy đủ", chạm cold start, 64 pending).
- `layout_overflow_test` (3 fail) và `study_plan_screen_test` (treo) là lỗi có sẵn, chưa sửa.
- Thông báo khóa học trên ColorOS cần quyền thông báo (và nên bật "Tự khởi chạy", bỏ tối ưu pin) mới ổn định; adb không cấp được quyền này.
- Chưa chạy lại toàn bộ suite sau `dart format` (format không đổi logic; analyze vẫn 0 error).
