# Báo cáo nghiệm thu: Quick capture từ share sheet Android (2026-10-28)

Thiết bị: OPPO **CPH2325** (`T4E6S8IFU4AQBM8L`). Bằng chứng: `DOCS/QA/evidence/v3/` (ảnh trong `screens/` và `c_*.png`).

## 1. Đã làm
| File | Nội dung |
|------|----------|
| `android/.../MainActivity.kt` | `MethodChannel('mindkeeper/share')`: cold start (`getInitialShared`), warm start (`onNewIntent` → `onShared`), vẫn gọi `super.onNewIntent` cho thông báo |
| `android/app/src/main/AndroidManifest.xml` | intent-filter `SEND` + `text/plain` |
| `lib/core/services/share_intake.dart` | `SharedPayload` (tách link, `isLink`), `ShareIntake` (giữ payload chờ → giao khi có listener) |
| `lib/features/capture/quick_capture_service.dart` | `ensureInbox`, `suggestTitle`, `save` (kiến thức + thẻ due ngay + Source link, chống trùng) |
| `lib/features/capture/quick_capture_screen.dart` | Màn "Lưu nhanh": tiêu đề/nội dung sửa được, chọn chủ đề, "Lưu nhanh", "Mở đầy đủ", "Tóm tắt bằng AI" (chỉ khi AI thật) |
| `lib/features/shell/app_shell.dart`, `lib/main.dart` | Đăng ký listener / khởi tạo `ShareIntake` |
| `lib/features/import/link_import_screen.dart` | `initialUrl` điền sẵn |
| `test/features/quick_capture_test.dart` | 11 test |
| `maestro/v3/c_*.yaml`, `c_run.sh` | 4 flow + script điều phối (bắn intent rồi chạy flow) |

Không thêm package: dùng `MethodChannel` trên `MainActivity` (không có package share trong README/pubspec; tránh rủi ro tương thích AGP/Flutter và không đụng cold start thông báo). Không gọi AI tự động.

## 2. Kết quả
- `flutter analyze`: 0 error, 7 warning có sẵn.
- `flutter test test/features/quick_capture_test.dart`: **11/11** (payload/link; `ShareIntake`; `suggestTitle`; lưu văn bản tạo Inbox + thẻ due ngay; link lưu `Source(link, reference_url)`; chống trùng nội dung và link; lưu vào chủ đề đã chọn; widget: Lưu nhanh, Hộp thư đến đã tồn tại, Mở đầy đủ cho link/văn bản).
- `flutter test test/core/android_manifest_receivers_test.dart`: 5/5.
- Maestro (`c_run_result.txt`, `maestro_c_*.log`) — **6/6 PASS**: warm văn bản (`c_save_warm`), warm trùng lặp (`c_dup_warm`), warm Mở đầy đủ văn bản (`c_open_text`), **cold** link (`c_save_cold`), **cold** trùng link (`c_dup_cold`), warm Mở đầy đủ link (`c_open_link`).

### Trên máy thật
1. **Cold start** (app bị giết, intent SEND link + subject): mở thẳng "Lưu nhanh" (`c_cold_share_screen.png`) → Lưu nhanh → snackbar xanh (`c_cold_saved.png`).
2. **DB** (`c_db_after_cold.txt`, `c_db_after_flows.txt`): chủ đề **"Hộp thư đến"** tự tạo; 2 kiến thức (văn bản + link), 2 thẻ ôn **due ngay**, 1 nguồn `link` với `reference_url=https://example.com/giac-ngu-cold`; chia sẻ lại cùng nội dung/cùng link → "không lưu trùng", không thêm dòng nào.
3. **Warm start** (app đang chạy): màn "Lưu nhanh" (`c_warm_share_screen.png`), lưu và báo trùng (`screens/v3_c_saved.png`, `v3_c_duplicate.png`).
4. **Mở đầy đủ**: văn bản → màn nhập văn bản điền sẵn (`screens/v3_c_open_text.png`); link → màn nhập liên kết điền sẵn URL (`screens/v3_c_open_link.png`).
5. **Share sheet hệ thống thật** (không chỉ `am start -n`): MindKeeper xuất hiện trong hộp chia sẻ (`c_system_chooser.png`), chọn khi app bị giết → mở "Lưu nhanh" (`c_system_chooser_result.png`).
6. **Không phá cold start thông báo**: `am start -a SELECT_NOTIFICATION --es payload card:<id>` khi app bị giết → mở đúng màn "Ôn thẻ được nhắc" (`c_notification_cold_regression.png`).

### Lỗi phát hiện và đã sửa khi nghiệm thu
- Khi "Hộp thư đến" đã tồn tại, giá trị `DropdownButton` trỏ tới id không có trong danh sách → assertion đỏ trên máy. Sửa: mặc định `null` (= Hộp thư đến), không đưa id vào danh sách; thêm test hồi quy.
- `ShareIntake.deliver` không bỏ qua văn bản toàn khoảng trắng (test phát hiện) → đã `trim`.
- Snackbar kết quả 3 giây quá ngắn để kiểm tự động → nâng lên 6 giây (cũng dễ đọc hơn).

## 3. Rủi ro / ghi chú
- **iOS** (Share Extension) để sau, **chưa verify**.
- Chỉ nhận `text/plain`; ảnh/file chia sẻ chưa hỗ trợ.
- Link không được tải trang tự động ở "Lưu nhanh" (offline-first); muốn trích nội dung trang dùng "Mở đầy đủ".
- "Tóm tắt bằng AI" chỉ hiện khi đã cấu hình AI thật; chưa thử trên máy thật vì máy không có key (không dùng key giả).

## 4. Tổng hợp kiểm tra cả 3 việc (A sao lưu, B onboarding, C quick capture)
- `flutter analyze`: **0 error**, 7 warning có sẵn (`firebase_messaging_service.dart` ×2, `layout_overflow_test.dart` ×5), 27 issue tổng — không có cảnh báo mới từ 3 việc.
- `flutter test` từng file (timeout 180 s; log `evidence/v3/flutter_test_per_file.txt`): **40 file → 37 file pass = 281 test passed**, 0 skipped.
  - `layout_overflow_test.dart`: 0 pass / 3 fail — **có sẵn** (đã xác nhận trên HEAD ở báo cáo trước).
  - `study_plan_screen_test.dart`: chạy riêng, timeout 180 s (rc=124) — **treo có sẵn**.
  - `learned_library_enrolled_test.dart`: lần đầu 1 pass / 1 fail, chạy lại riêng **2/2 pass** → flaky có sẵn.
- Maestro: smoke `cph2239/01_smoke.yaml` PASS ở bản cuối (`maestro_smoke_final.log`); flow mới: A `a_backup_screen`, B `b_onboarding`/`b2_skip`/`b3_review`/`b4_legacy`, C 6 lượt `c_*` — tất cả PASS (log `evidence/v3/maestro_*.log`).
- Dọn dẹp máy: đã xóa các file `.mkbackup` thử nghiệm trong `Download`.

