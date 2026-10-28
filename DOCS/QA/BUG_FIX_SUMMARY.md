# Báo cáo sửa lỗi — MindKeeper (2026-10-28)

## Mục tiêu
Sửa lỗi cụ thể trong kho `D:\JOB\mind_keeper` (branch `master`), tạo báo cáo `.md` + cập nhật tài liệu, commit/push. Thiết bị kiểm thử: OPPO CPH2239 (Android 13).

## Lỗi đã sửa

### 1. `test/features/layout_overflow_test.dart` — 11 fail (Guarded function conflict + TimeoutException)
**Nguyên gốc:** helper `_pump()` gọi `tester.pumpWidget` + `tester.runAsync(...)` lồng nhau, và test gọi `_pump(...)` không `await` → test framework bắt pump chồng pump. `Future.delayed` thật trong `runAsync` + sqflite FFI không bao giờ settle → TimeoutException 10 phút.

**Sửa:**
- `_pump()` chỉ `await tester.pumpWidget` + `await tester.pumpAndSettle()`, KHÔNG dùng `runAsync`.
- Thay `Future.delayed(const Duration(...))` bằng `tester.binding.delayed(...)`.
- Mọi `_pump(...)` đều được `await` đầy đủ.

**File:** `test/features/layout_overflow_test.dart`

### 2. Maestro test cho thiết bị CPH2239
Tạo flow smoke: launch app → chờ màn hình chính (nút "Thêm") → chụp ảnh → assert không crash.

**File:** `maestro/cph2239/01_smoke.yaml`, `maestro/cph2239/run.sh`

## Kết quả `flutter analyze`
- 0 error.
- Còn lại: `info`/`warning` pre-existing (doc comment angle bracket, deprecated `groupValue`/`onChanged`/`window`, unused import trong tool/fix_entry_test). Không phải do bản sửa này.

## File liên quan (tổng quát)
| File | Vai trò |
|------|---------|
| `test/features/layout_overflow_test.dart` | Test layout overflow (TodayScreen, TopicDetailScreen, LessonDiscoverScreen) — ĐÃ SỬA |
| `maestro/cph2239/01_smoke.yaml` | Flow smoke test thiết bị CPH2239 — MỚI |
| `maestro/cph2239/run.sh` | Lệnh chạy maestro trên CPH2239 — MỚI |
| `DOCS/IMPLEMENTATION_PROGRESS.md` | Sổ tiến độ — ĐÃ CẬP NHẬT |
| `DOCS/QA/BUG_FIX_SUMMARY.md` | Báo cáo này — MỚI |

## Lỗi chưa xử lý (khuyên xử lý phiên sau)
- `test/features/study_plan_screen_test.dart` treo/không chạy (lỗi có sẵn từ trước GĐ23).
- Thông báo thực sự không hiện trên OPPO (kênh `mind_keeper_course` chưa tạo; nghi ColorOS chặn broadcast nền).
- Proxy DeepSeek backend BLOCKED (repo không có `functions/` / `firebase.json`).
- `flutter test` trên Windows bị khóa `sqlite3.dll` → cần `tool/run_flutter_test.ps1`.
- iOS build cần macOS (không thể verify trên Windows).

## Ràng buộc commits
- Đã commit/push (theo yêu cầu). Không ghi bí mật (API key, keystore) vào repo.
