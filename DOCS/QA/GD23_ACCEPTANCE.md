# GĐ23 — Nghiệm thu: khóa học theo cấp độ, trang chủ mới, thông báo, thương hiệu

**Thiết bị:** OPPO CPH2203 (Android 13, serial `NJR8W86LKRVW7DHQ`), APK debug build với
`--dart-define=DEEPSEEK_BASE_URL=http://127.0.0.1:8765/v1 --dart-define=DEEPSEEK_API_KEY=mock --dart-define=DEEPSEEK_MODEL=mock`
(AI giả lập `tool/mock_ai_server.js` qua `adb reverse tcp:8765 tcp:8765`, dùng riêng cho kiểm thử — không phải AI thật).
**Ngày:** 2026-10-27.

## Pha 1 — Lõi (unit)
| Hạng mục | Kết quả |
|---|---|
| Migration v8→v9 giữ dữ liệu, UNIQUE/FK/CASCADE | PASS (`migration_v9_test`) |
| Dựng đề cương đúng N mẩu, không trùng | PASS |
| Chưa cấu hình AI thật → không soạn/không sinh (không coi mock là thật) | PASS |
| `sync`: sinh mẩu hôm nay + ngày mai, lưu nội dung, thẻ ôn ẩn, lên lịch thông báo (ID âm, payload `course:`), idempotent | PASS |
| `perDay = 2`, nhiều khóa xen kẽ giờ | PASS |
| `markRead` kích hoạt thẻ FSRS (due +1 ngày), hủy thông báo, idempotent | PASS |
| `reconcile` sau nút "Đã hiểu" bấm khi app đóng | PASS |
| Đổi cấp độ giữa chừng giữ đề cương, mẩu sau theo cấp mới | PASS |
| Tạm dừng hủy lịch nhưng giữ dữ liệu; hết mẩu → khóa hoàn thành | PASS |
| `generateNext` (đọc trước), xóa khóa hủy thông báo | PASS |

## Pha 2 — Giao diện
| Hạng mục | Kết quả |
|---|---|
| Widget test trang chủ (có mẩu / hết việc / chưa có khóa), Thêm khóa học (AI chưa cấu hình; luồng đầy đủ với HTTP giả), Đọc mẩu (Đã hiểu, Báo nội dung → tạm dừng ôn), Quyền riêng tư | PASS (`course_ui_test`, 7 test) |
| Layout không tràn ở 360×640 và cỡ chữ 1,5× | PASS (`layout_overflow_test`) |
| Maestro 01: trang chủ mới không còn "Nhanh tập trung / Tiến độ hôm nay / Chủ đề gần đây"; menu [+] đủ 4 lối tắt | PASS (thiết bị thật) |
| Maestro 02: thêm khóa học 3 bước + bỏ mục đề cương + bắt đầu | PASS (thiết bị thật) |
| Maestro 03: Bắt đầu/Đọc trước → Đã hiểu → xác nhận, nút Báo nội dung | PASS (thiết bị thật) |

## Pha 3 — Thông báo
| Hạng mục | Kết quả |
|---|---|
| Payload `course:<id>` (legacy + JSON) | PASS (unit) |
| Chạm thông báo (cold start) mở **đúng mẩu** — Maestro 04 (intent `SELECT_NOTIFICATION`, `ITEM_ID=ci_store_1`) | PASS (thiết bị thật) |
| Lên lịch báo thức: `exactAllowReason=permission` trên máy | PASS (`dumpsys alarm`) |
| Hệ thống gửi broadcast tới `ScheduledNotificationReceiver` đúng giờ | PASS (`dumpsys activity broadcasts`) |
| **Thông báo thực sự hiện (BigText + nút Đã hiểu/Đọc đầy đủ)** | **CHƯA XÁC NHẬN — KHÔNG hiện** trên CPH2203 (kênh `mind_keeper_course` không được tạo). Nghi ColorOS chặn broadcast nền; cần bật "Tự khởi chạy"/bỏ tối ưu pin rồi thử lại, hoặc thử máy khác (xem `DOCS/IMPLEMENTATION_PROGRESS.md` GĐ23 mục Rủi ro 1) |
| iOS nút hành động | CHƯA KIỂM THỬ (không có Mac) |

## Pha 4 — Thương hiệu & cửa hàng
| Hạng mục | Kết quả |
|---|---|
| Icon mới trên launcher (adaptive + legacy), iOS AppIcon | Sinh xong, build APK OK (`flutter_launcher_icons`) |
| Splash native Android (gradient + logo, Android 12 `values-v31`) + `SplashOverlay` trong app | Quan sát trên máy: nền thương hiệu + logo M; test `brand_splash_test` PASS |
| Trang `site/` + workflow Pages | Dựng được bằng `tool/site/build_site.sh` (cần `CONTACT_EMAIL`, `DEVELOPER_NAME`); **chưa đăng** (cần quyết định của chủ) |
| Ảnh chụp thật (5) + khung cho Android/iPhone/iPad, ảnh bìa, icon 512/1024 | Sinh xong trong `store/` (Maestro 05 chụp từ thiết bị thật) |
| Video giới thiệu 18,6 s (1080×1920 và 886×1920) | Dựng từ ảnh chụp bằng ffmpeg (thiết bị chặn `screenrecord`) |
| Nội dung trang vi/en trong giới hạn ký tự | PASS (`tool/store/check_listing.sh`) |
| Cây fastlane sinh được từ `store/` | PASS (`tool/store/prepare_fastlane.sh`) — chưa chạy lane thật (cần khóa/tài khoản) |

## Lỗi/giới hạn có sẵn phát hiện thêm
- `test/features/study_plan_screen_test.dart` treo/không có test chạy được ở cả commit trước GĐ23.
- Khối font Inter trong `pubspec.yaml` đặt sai chỗ từ trước (đã sửa ở GĐ23).
- Mỗi lần chạy Maestro 02 tạo thêm một khóa "Bep tu" trên máy (dữ liệu thử).
