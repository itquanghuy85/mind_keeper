# GĐ18.3 — NGHIỆM THU MIND KEEPER TRÊN OPPO THẬT

## 1. Thông tin thiết bị và bản dựng

| Thuộc tính | Giá trị |
|------------|---------|
| **Model** | OPPO CPH2203 |
| **Android version** | 13 (API 33) |
| **CPU ABI** | arm64-v8a |
| **Serial** | NJR8W86LKRVW7DHQ |
| **Package ID** | com.mindkeeper.mind_keeper |
| **Version code** | 1 |
| **Version name** | 1.0.0 |
| **APK** | `build/app/outputs/flutter-apk/app-debug.apk` (debug, signed with debug key) |
| **Render backend** | Impeller (Vulkan + OpenGLES) |
| **Cài đặt** | `adb install -r` (upgrade, không xóa dữ liệu) |

---

## 2. Kết quả CI trước khi nghiệm thu thiết bị

| Bước | Kết quả | Chi tiết |
|------|---------|----------|
| `flutter pub get` | ✅ PASS | 33 packages có version mới hơn nhưng compatible |
| `flutter analyze` | ✅ PASS | 18 issues (chỉ warning/info pre-existing, 0 error mới) |
| `flutter test` | ✅ **106/106 PASS** | Bao gồm 2 test migration v4 mới |

---

## 3. Trạng thái kiểm tra trên thiết bị (OPPO CPH2203)

### GĐ1 — Khởi động và Build
| Kiểm tra | Trạng thái | Bằng chứng |
|----------|------------|------------|
| App launch không crash | ✅ PASS | Logcat: Flutter VM listening, Impeller enabled |
| Không exception SQLite/migration | ✅ PASS | Không lỗi Flutter error trong logcat |
| Không exception notification/AI | ✅ PASS | Chỉ warning "Chưa cấu hình API key DeepSeek. Dùng MockAIProvider" (dòng 20.594s) |
| Cài đặt an toàn (không uninstall) | ✅ PASS | `adb install -r` thành công, giữ nguyên chữ ký debug |

### GĐ2 — Khởi động và Database
| Kiểm tra | Trạng thái | Bằng chứng / Ghi chú |
|----------|------------|---------------------|
| Migration v4 áp dụng đúng | ⚠️ **CHƯA XÁC MINH ĐẦY ĐỦ** | Database mới tạo tại `app_flutter/mind_keeper.db` (0 bytes - chưa init). Cần tương tác app để trigger `onCreate` + migration. |
| Dữ liệu cũ giữ nguyên | ⚠️ **KHÔNG ÁP DỤNG** | Cài đặt mới (chưa từng chạy app trước đó), không có dữ liệu cũ để migration. |
| Schema knowledge_items có `started_at` | ❌ **CHƯA KHỞI TẠO** | Sẽ được tạo khi app lần đầu ghi DB. Cần test sau khi tạo topic/bài học. |

> **Lưu ý quan trọng**: Database path trên Android thực tế là `getApplicationDocumentsDirectory()` (`/data/user/0/com.mindkeeper.mind_keeper/files/mind_keeper.db`), khác với test environment (`app_flutter/mind_keeper.db`). Cần kiểm tra database thật sau khi thao tác.

### GĐ3 — Tạo bài và Tự đăng ký ghi nhớ (enroll/findByTitle)
| Kịch bản | Trạng thái | Ghi chú |
|----------|------------|---------|
| Tạo chủ đề mới | ⏳ **CẦN TEST THỰC TẾ** | Chưa thao tác trên máy |
| Tạo/sinh bài học | ⏳ **CẦN TEST THỰC TẾ** | |
| Kiểm tra bài **chưa** vào Kho đã học khi mới tạo | ⏳ **CẦN TEST THỰC TẾ** | Logic: chỉ `enroll` khi mở đọc lần đầu |
| Mở bài → xuất hiện trong Kho đã học | ⏳ **CẦN TEST THỰC TẾ** | |
| `startedAt` được lưu | ⏳ **CẦN TEST THỰC TẾ** | Cần kiểm tra DB sau khi mở bài |
| Mở lại nhiều lần → không trùng KnowledgeItem | ⏳ **CẦN TEST THỰC TẾ** | `findByTitle` scope theo `topic_id` |
| `startedAt` không thay đổi khi mở lại | ⏳ **CẦN TEST THỰC TẾ** | Code: chỉ cập nhật nếu `startedAt == null` |
| Đọc offline (nội dung đã lưu) | ⏳ **CẦN TEST THỰC TẾ** | |
| Hai bài khác nhau cùng tiêu đề trong cùng topic | ⏳ **CẦN TEST THỰC TẾ** | **Rủi ro**: `findByTitle` dùng title → có thể gộp sai. Cần verify. |

> **Rủi ro logic**: `KnowledgeRepository.findByTitle()` tìm theo `topic_id + LOWER(title)`. Nếu user tạo 2 bài khác nhau nhưng trùng tiêu đề trong cùng topic, sẽ bị coi là trùng. Cần test thực tế.

### GĐ4 — Quiz và FSRS
| Kịch bản | Trạng thái | Ghi chú |
|----------|------------|---------|
| Hoàn thành quiz → tạo ReviewCard | ⏳ **CẦN TEST THỰC TẾ** | |
| Ôn thẻ + chấm điểm → due date cập nhật | ⏳ **CẦN TEST THỰC TẾ** | FSRS scheduler |
| Force-stop + mở lại → dữ liệu giữ | ⏳ **CẦN TEST THỰC TẾ** | SQLite persist |
| Không tạo ReviewCard trùng khi hoàn thành lại | ⏳ **CẦN TEST THỰC TẾ** | `handledCardIds` guard trong `completeQuiz` |
| Đọc bài không tự tạo kết quả ghi nhớ giả | ⏳ **CẦN TEST THỰC TẾ** | Chỉ quiz mới tạo card |

### GĐ5 — Kho đã học (LearnedLibraryScreen)
| Chức năng | Trạng thái implementation | Ghi chú |
|-----------|--------------------------|---------|
| Danh sách bài đã đăng ký | ✅ Implemented | `_load()` filter `item.isEnrolled` (startedAt != null) |
| Tìm kiếm title/content/details | ✅ Implemented | Local filter trong `_load()` |
| Lọc: Tất cả | ✅ UI ready | `_applyFilter` trả về all (TODO logic) |
| Lọc: Chưa đánh giá | ⚠️ **UI ready, logic TODO** | `_applyFilter` chưa query review_cards |
| Lọc: Đang ghi nhớ | ⚠️ **UI ready, logic TODO** | Cần join review_cards FSRS state |
| Lọc: Đến hạn ôn | ⚠️ **UI ready, logic TODO** | Cần query `due_at <= now` |
| Lọc: Đã hoàn thành | ⚠️ **UI ready, logic TODO** | Cần định nghĩa "hoàn thành" (FSRS state?) |
| Sắp xếp: Ngày bắt đầu | ✅ Implemented | Sort by `startedAt` desc |
| Sắp xếp: Lần đọc gần nhất | ⚠️ Fallback `updatedAt` | Chưa có field `lastReadAt` |
| Sắp xếp: Sắp đến hạn ôn | ⚠️ Fallback `updatedAt` | Cần query `due_at` từ review_cards |
| Sắp xếp: Ưu tiên ôn | ⚠️ Fallback `updatedAt` | Cần thuật toán priority thực tế |
| Chạm bài → mở chi tiết | ✅ Implemented | Navigate to `KnowledgeDetailScreen` |
| Tìm kiếm + đọc offline | ✅ Implemented | Dữ liệu từ SQLite local |
| Force-stop → dữ liệu còn nguyên | ⏳ **CẦN TEST THỰC TẾ** | |

> **QUAN TRỌNG**: Các filter nâng cao (chưa đánh giá, đang ghi nhớ, đến hạn, đã hoàn thành) **chỉ có UI, chưa có logic truy vấn ReviewCard/FSRS thực tế**. `_applyFilter()` hiện tại trả về tất cả enrolled items. Cần implement join với `review_cards` để lọc chính xác.

### GĐ6 — Thông báo trên OPPO (ColorOS 13)
| Kịch bản | Trạng thái | Ghi chú |
|----------|------------|---------|
| Quyền notification (POST_NOTIFICATIONS) | ✅ Manifest có | Android 13+ yêu cầu runtime permission |
| Bật/tắt trong app | ✅ Implemented | `PreferencesService.notificationsEnabled` + `cancelAll`/`scheduleDailyReminder` |
| Cài đặt giờ/ngày nhắc | ✅ Implemented | TimePicker + daily reminder |
| Tạo lịch ôn sau chấm điểm | ✅ Implemented | `scheduleCardDueAt` trong `completeQuiz` |
| Cập nhật lịch sau ôn kế tiếp | ✅ Implemented | `review_notification_sync_test` cover 6 cases |
| Không trùng lịch khi chấm nhiều lần | ✅ Implemented | `cancelCardNotification` trước khi `scheduleCardDueAt` |
| Notification mở đúng bài/danh sách | ✅ Implemented | Payload `card:<id>` → `ReviewScreen` |
| Khởi động lại không mất lịch hợp lệ | ✅ Implemented | `AppBootstrap.refreshReminderSchedule` |
| ColorOS battery optimization | ⚠️ **CẦN TEST THỰC TẾ** | OPPO aggressive background kill → có thể delay notification. Cần test thực tế. |

> **Cách verify thực tế**: Dùng `adb shell dumpsys notification --noredact | grep mindkeeper` để xem lịch đã đăng ký. Test nhanh: đặt reminder 1-2 phút, quan sát lockscreen.

### GĐ7 — DeepSeek API Thật
| Kiểm tra | Trạng thái | Bằng chứng |
|----------|------------|------------|
| Endpoint/model từ cấu hình | ✅ PASS | `HttpAIProvider` đọc từ `PreferencesService` (SharedPreferences + env var) |
| API key **không** hardcode | ✅ PASS | `String.fromEnvironment('DEEPSEEK_API_KEY')` + user prefs |
| MockAIProvider fallback | ✅ PASS | Logcat: "Chưa cấu hình API key DeepSeek. Dùng MockAIProvider" |
| Request thật gửi DeepSeek | ❌ **BLOCKED** | Không có API key test an toàn. Không đưa production key vào APK. |
| Kiến trúc: gọi trực tiếp từ Flutter | ⚠️ **RỦI RO** | API key bí mật trong app client → rủi ro lộ key. **Đề xuất**: Chuyển qua backend proxy. |

### GĐ8 — Ổn định và Hồi quy
| Kiểm tra | Trạng thái | Ghi chú |
|----------|------------|---------|
| Unit/widget tests (Windows) | ✅ 106/106 PASS | Chạy lại sau build |
| Build debug APK | ✅ SUCCESS | `flutter build apk --debug` |
| Force-stop + mở lại | ⏳ **CẦN TEST THỰC TẾ** | |
| Không crash unhandled | ✅ PASS (logcat) | Chỉ system warnings, không Flutter error |

---

## 4. Log lỗi và nguyên nhân (từ logcat thiết bị)

| Log | Nguồn | Mức độ | Nguyên nhân / Hành động |
|-----|-------|--------|------------------------|
| `hiddenapi: Accessing hidden method Landroid/window/BackEvent...` | Flutter/Framework | Warning | Predictive back gesture API bị block trên Android 13+. Không ảnh hưởng chức năng. |
| `ANR_LOG: Blocked msg... cost = 2008 ms` | Android System | Warning | Khởi động app mất ~2s (cold start). Chưa gây ANR thực sự. |
| `Can't load library: libmagtsync.so` | MediaTek framework | Warning | Thư viện hệ thống OPPO, không liên quan app. |
| `UpgradeScoreDataVerifyUtil: updScoreDto == null` | OPPO Market | Warning | System app check update, không liên quan. |
| `ofbOpen failed with error=No such file or directory` | Flutter engine | Warning | File I/O nội bộ, không crash. |

**Kết luận**: Không có lỗi crash hoặc exception từ code Dart/Flutter.

---

## 5. File đã sửa trong phiên bản này

| File | Loại | Mô tả |
|------|------|-------|
| `lib/data/db/schema.dart` | Fix | Schema v4: thêm `started_at` column; migration chain v1→v2 (sources, review_cards, review_logs, lessons), v2→v3 (knowledge_generation_tasks), v3→v4 (ALTER TABLE started_at) |
| `test/core/notification_permission_test.dart` | Fix | Target đúng SwitchListTile "Bật thông báo nhắc ôn" (tránh 2 switch) |
| `test/data/migration_v4_test.dart` | New | 2 test: v3→v4 add column, v1→v4 full chain preserve data |

---

## 6. Kết quả kiểm thử tự động

| Suite | Tests | Pass | Fail | Skip |
|-------|-------|------|------|------|
| Unit/Widget (Windows) | 106 | 106 | 0 | 0 |
| Integration (thiết bị) | — | — | — | — |

> Chưa chạy integration test trên thiết bị thật (cần `flutter drive` hoặc `integration_test` package).

---

## 7. Tóm tắt trạng thái nghiệm thu

| Giai đoạn | Trạng thái | Ghi chú |
|-----------|------------|---------|
| **GĐ1: Build & Cài đặt** | ✅ **PASS** | APK debug cài thành công, launch OK |
| **GĐ2: Khởi động & DB** | ⚠️ **PARTIAL** | App chạy, DB chưa init (cần thao tác), migration logic đúng (test pass) |
| **GĐ3: Tạo bài & Enroll** | ⏳ **PENDING** | Cần test thực tế trên máy; rủi ro `findByTitle` gộp sai title trùng |
| **GĐ4: Quiz & FSRS** | ⏳ **PENDING** | Cần test thực tế |
| **GĐ5: Kho đã học** | ⚠️ **PARTIAL** | UI sẵn sàng, **filter nâng cao chưa có logic** (TODO implement) |
| **GĐ6: Thông báo** | ⚠️ **PARTIAL** | Code đúng, cần test thực tế trên ColorOS (battery opt) |
| **GĐ7: DeepSeek thật** | ❌ **BLOCKED** | Thiếu API key test an toàn; kiến trúc client-side key = rủi ro bảo mật |
| **GĐ8: Ổn định** | ⚠️ **PARTIAL** | Test auto pass, cần soak test trên thiết bị |

---

## 8. Rủi ro và Việc chưa xác minh

| Rủi ro | Mức độ | Khuyến nghị |
|--------|--------|-------------|
| **`findByTitle` gộp sai 2 bài khác nhau cùng title trong 1 topic** | **HIGH** | Test case: Tạo 2 bài "Bài 1" trong topic A → kiểm tra `enroll` chỉ tạo 1 KnowledgeItem. Fix: thêm `content` hash hoặc dùng `source_id`/`lesson_id` làm dedup key. |
| **Filter Kho đã học chưa chính xác** | **MEDIUM** | Implement `_applyFilter` join `review_cards` để lấy FSRS state, due date thực tế. |
| **ColorOS kill background → notification delay/miss** | **HIGH** | Test thực tế đặt reminder 5-10 phút. Hướng dẫn user whitelist app trong Battery settings. |
| **DeepSeek API key trong client app** | **HIGH (Security)** | Không bao giờ ship production key trong APK. Cần backend proxy hoặc user tự nhập key (encrypted storage). |
| **Database path khác biệt test vs production** | **MEDIUM** | Test dùng `inMemoryDatabasePath` / temp dir; production dùng `getApplicationDocumentsDirectory()`. Cần integration test trên device. |
| **Chưa test migration v1→v4 trên dữ liệu production thực tế** | **MEDIUM** | Backup DB user cũ, test upgrade path trước khi release. |

---

## 9. Kết luận

> **NGHIỆM THU: CHƯA ĐẠT (CONDITIONAL PASS)**

### Đã đạt:
- ✅ Build, cài đặt, khởi động app trên OPPO CPH2203 Android 13 thành công
- ✅ Tất cả unit/widget tests (106/106) pass trên CI
- ✅ Migration v4 logic đúng (test pass), schema `started_at` đã thêm
- ✅ Notification permission flow, FSRS sync logic đúng (test pass)
- ✅ Không crash, không exception Dart/Flutter trên thiết bị
- ✅ API key không hardcode, MockAIProvider fallback hoạt động

### Cần hoàn thiện trước khi release:
1. **Test thực tế GĐ3-GĐ6 trên thiết bị** (tạo topic, bài học, quiz, ôn, notification, filter)
2. **Fix `findByTitle` dedup logic** — thêm content hash hoặc source_id để tránh gộp sai bài trùng title
3. **Implement filter nâng cao Kho đã học** (`_applyFilter` join `review_cards`)
4. **Test ColorOS battery optimization** — verify notification delivery thực tế
5. **DeepSeek API**: Không test được request thật. Cần quyết định: (a) user tự nhập key, (b) backend proxy, (c) ship test key riêng.

### Hành động tiếp theo:
- [ ] Test manual GĐ3-GĐ6 trên OPPO (có người test thực tế)
- [ ] Fix `KnowledgeRepository.enroll` dedup logic
- [ ] Implement `LearnedLibraryScreen._applyFilter` / `_applySort` với ReviewCard join
- [ ] Thêm integration test cho migration v1→v4 với data thật
- [ ] Review kiến trúc AI: tách API key ra backend

---

*Báo cáo tạo ngày: 2026-10-18*  
*Người thực hiện: AI Assistant (opencode)*  
*Thiết bị: OPPO CPH2203 (Android 13, API 33)*  
*Repo: `D:\FlutterProjects\mind_keeper`*