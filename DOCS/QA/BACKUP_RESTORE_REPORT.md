# Báo cáo nghiệm thu: Sao lưu & khôi phục (2026-10-28)

Thiết bị: OPPO **CPH2325** (`T4E6S8IFU4AQBM8L`). Bằng chứng: `DOCS/QA/evidence/v3/`.

## 1. Đã làm
| File | Nội dung |
|------|----------|
| `lib/core/services/backup_service.dart` | `BackupService`: `exportJson`, `parse` (validate), `restore` (bản sao lưu an toàn → transaction → prefs → thông báo) |
| `lib/features/profile/backup_restore_screen.dart` | Màn "Sao lưu & khôi phục": xuất (`FilePicker.saveFile`), chọn file (`FilePicker.pickFiles`), hộp thoại xác nhận "Thay thế toàn bộ dữ liệu hiện tại?" |
| `lib/core/services/preferences_service.dart` | `backupKeys`, `exportBackupPrefs`, `restoreBackupPrefs`, `onboardingCompleted`, `defaultCourseLevel` |
| `lib/app.dart`, `profile_screen.dart` | Route `/settings/backup`, mục "Sao lưu & khôi phục" trong Hồ sơ |
| `test/core/backup_service_test.dart` | 12 test |
| `maestro/v3/a_backup_screen.yaml` | Flow mở màn + xuất file |

Định dạng `.mkbackup` = JSON: `header` (format `mindkeeper-backup`, version, schemaVersion, exportedAt, appVersion, counts), `prefs`, `tables` (11 bảng: topics, lessons, sources, knowledge_items, review_cards, review_logs, knowledge_generation_tasks, knowledge_reminder_history, study_feed_items, courses, course_items).

**Không xuất** (và ghi rõ trong UI): khóa/URL/model AI (`ai_*`), phiên ôn đang chạy (`session_*`), ID thông báo đã lập, file media. `sources.storage_path` tuyệt đối bị xóa khi khôi phục.

## 2. Kết quả
- `flutter analyze`: 0 error, 7 warning có sẵn (firebase_messaging_service ×2, layout_overflow_test ×5).
- `flutter test test/core/backup_service_test.dart`: **12/12 pass** (roundtrip FSRS + prefs; không lộ API key/session/ID thông báo; từ chối JSON hỏng / sai format / schema mới hơn / version mới hơn / counts lệch; bản sao lưu an toàn tạo trước khi ghi đè; lỗi giữa chừng rollback; xóa storage_path tuyệt đối; thiếu quyền thông báo → tắt cờ + hủy lịch + vẫn lập lại; đủ quyền → giữ cờ).
- Maestro: smoke `cph2239/01_smoke.yaml` PASS (`maestro_smoke_a.log`); `v3/a_backup_screen.yaml` PASS (`maestro_a_backup_screen.log`, `screens/v3_a_*.png`).

### Roundtrip trên máy thật
1. Dữ liệu mẫu tạo bằng UI offline (Khám phá → Lưu: 1 chủ đề + 1 kiến thức + 1 thẻ) + ôn thẻ 1 lần ("Tốt") để có lịch FSRS thật; prefs đặt qua `run-as` (mục tiêu 33, 3 chủ đề mới/ngày, nhắc 07:45, chế độ bài `deep`, và một khóa API giả `sk-DEVICE-SECRET-TEST` để kiểm tra không bị xuất).
2. Xuất file qua hộp thoại lưu của hệ thống → `Download/mindkeeper-20261028-160140.mkbackup` (32 dòng, 13,7 KB): `a_backup_screen.png`, `a_export_done.png`, `a_export.mkbackup`. File **không chứa** `sk-DEVICE-SECRET-TEST` / `ai_api_key`.
3. Xóa dữ liệu app (`run-as` xóa DB + prefs; `pm clear` bị ColorOS chặn): DB về 0 dòng (`a_after_wipe_home.png`).
4. Chọn file → xác nhận → khôi phục: `a_restore_confirm.png`, `a_restore_done.png`.
5. So sánh `a_snapshot_before.json` ↔ `a_snapshot_after.json`: số dòng 11 bảng **bằng nhau**; thẻ ôn `due_at=1793178645827`, `stability=3.2602`, `difficulty=4.8846…`, `reps=1` **bằng nhau**; prefs (daily_goal 33, new_topics 3, reminder 07:45, lesson mode deep) **bằng nhau**; `ai_api_key` sau khôi phục = rỗng.
6. Bản sao lưu an toàn tự tạo trước khi ghi đè: `app_flutter/backups/truoc-khoi-phuc-1793178251785.mkbackup` (`a_safety_backup_listing.txt`).
7. File lỗi bị từ chối với thông báo rõ: file không phải JSON (`a_reject_not_backup.png`), schema v99 mới hơn ứng dụng v10 (`a_reject_newer_schema.png`).

## 3. Rủi ro / ghi chú
- Chưa có sao lưu cloud, không mã hóa file, không tự động sao lưu định kỳ.
- Thông báo sau khôi phục: logic hủy → tắt cờ nếu thiếu quyền → lập lại được kiểm bằng unit test (FakeNotificationService); trên máy thật quyền thông báo đang được cấp nên nhánh "thiếu quyền" chưa chạy bằng tay.
- Khôi phục bị `rollback` khi file có khóa chính trùng/khóa ngoại sai (đã test); dữ liệu cũ nguyên vẹn, kèm bản sao lưu an toàn.
- iOS chưa verify (cần Mac).
