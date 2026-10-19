# GĐ20 — PALETTE THEME-AWARE + ENTRY POINT + SỬA ENROLLMENT/DEDUP + DEEPSEEK PROXY — BÁO CÁO NGHIỆM THU

**Ngày hoàn thành:** 2026-10-19
**Thiết bị test:** OPPO CPH2203 (Android 13, API 33), ADB serial `NJR8W86LKRVW7DHQ`
**Package:** `com.mindkeeper.mind_keeper` v1.0.0+1 (debug, `adb install -r` — giữ dữ liệu người dùng)
**Repo:** `D:\FlutterProjects\mind_keeper`, branch `master`, HEAD `e0bbea3` — **chưa commit/push**
**Trạng thái:** ✅ HOÀN THÀNH phạm vi code + test + nghiệm thu thiết bị; ⛔ 1 hạng mục BLOCKED (deploy proxy backend — xem §8)

---

## 1. TỔNG KẾT

| Hạng mục | Kết quả |
|---|---|
| `flutter analyze` | **No issues found** (0 issue, toàn dự án) |
| `flutter test` (full suite) | **+131 All tests passed** (baseline trước GĐ20: 111) |
| `dart format lib test` | Đã chạy (92 file, LF giữ nguyên — không đổi line ending) |
| `flutter build apk --debug` | **SUCCESS** → `build\app\outputs\flutter-apk\app-debug.apk` |
| `adb install -r` | **SUCCESS**, dữ liệu người dùng giữ nguyên |
| Migration DB trên dữ liệu thật | **v5 → v6 PASS**, không mất bản ghi nào |
| App cold-start + logcat | Không có exception/crash của Flutter |
| Light/Dark render trên máy thật | Đo được bằng số: luminance 212.6 → 38.1 (xem §6.3) |
| DeepSeek proxy backend (Cloud Functions) | **BLOCKED** — không có project Firebase/`firebase.json` trong repo (§8) |
| iOS build | Không đổi: cần macOS/Xcode (ngoài phạm vi) |

---

## 2. PHẠM VI 1 — PALETTE XANH DƯƠNG–TRẮNG THEME-AWARE (LIGHT + DARK)

**Vấn đề:** màu sắc UI hardcode qua `AppColors` (chỉ có giá trị light) → dark theme bị sai/khó đọc.

**Giải pháp:** thêm `AppPalette` là `ThemeExtension<AppPalette>` với **54 token** cho cả light và dark, truy cập qua `context.appColors`.

| Thành phần | File | Ghi chú |
|---|---|---|
| Palette (54 token × 2 bộ) | `lib/core/theme/app_palette.dart` *(mới)* | `AppPalette.lightPalette`, `AppPalette.darkPalette`, `AppPalette.of(context)`, `AppPalette.lerp` |
| Đăng ký extension | `lib/core/theme/app_theme.dart` | `extensions: const [AppPalette.lightPalette]` trong `AppTheme.light()`, `[AppPalette.darkPalette]` trong `AppTheme.dark()` |
| Extension tiện dụng | `lib/core/theme/app_palette.dart` | `extension AppPaletteContextX on BuildContext { AppPalette get appColors }` |
| Màn hình/widget đã chuyển sang `context.appColors` | `today_screen`, `knowledge_detail_screen`, `knowledge_library_screen`, `learned_library_screen`, `lesson_discover_screen`, `lesson_reader_screen`, `notification_settings_screen`, `profile_screen`, `review_screen`, `app_shell`, `stats_screen`, `topic_detail_screen`, `topics_screen` + `app_button`, `app_card`, `app_chip`, `app_dialog`, `app_feedback`, `app_icon_badge`, `app_text_field` | 13 màn hình + 7 widget dùng chung |
| Ngoại lệ giữ nguyên static | `lib/core/theme/app_colors.dart` | `AppColors.primary` giữ ở chỗ fill nền sau chữ trắng (`app_chip.dart`, FAB) — cặp `primary`/`textOnPrimary` không đổi theo theme |

**Kiểm thử tự động (mới):** `test/core/theme_palette_test.dart` — **5 test PASS**
1. `AppTheme.light()/dark()` đăng ký extension `AppPalette` + `brightness` đúng.
2. Nền: light luminance > 0.85, dark < 0.20; chữ: light < 0.3, dark > 0.7 (tương phản).
3. Light và dark khác nhau ở các token chính (background, primarySoft, surface, textPrimary).
4. `lerp(light, dark, 0.5)` tạo giá trị trung gian (không trả nguyên light/dark).
5. `context.appColors` trả đúng palette theo `ThemeData` đang áp dụng (pump `MaterialApp` với `AppTheme.light()` rồi `AppTheme.dark()` + `pumpAndSettle` — **bẫy đã gặp**: ThemeData được animate (lerp) nên nếu không settle, extension trả giá trị light).

---

## 3. PHẠM VI 2 — SỬA ENROLLMENT / DEDUP + FILTER/SORT "KHO ĐÃ HỌC"

### 3.1 Lỗi đã sửa

| # | Lỗi | Nguyên nhân gốc | Sửa |
|---|---|---|---|
| 1 | Đăng ký (enroll) bài học tạo ra bản ghi **không gắn bài học** | `lesson_reader_screen.dart` gọi `enroll(...)` **thiếu `lessonId`** (dù `lesson_service.dart:311` đã truyền) | truyền `lessonId: lesson.id` + gọi `touchLastRead(enrolled.id)` sau khi enroll |
| 2 | **Trùng bản ghi** khi enroll 2 bài khác nhau có tiêu đề giống nhau | `findByTitle` fallback chỉ theo title cho mọi bản ghi | fallback title chỉ áp dụng cho bản ghi `lesson_id IS NULL` khi có `lessonId` → không gộp nhầm 2 bài khác nhau |
| 3 | "Kho đã học" **hiển thị rỗng trên máy thật** dù đã có bài đã học | màn hình gọi `search('')`, mà `search()` `return const []` khi query rỗng | dùng API mới `listEnrolled({query})` (`started_at IS NOT NULL`) |
| 4 | Filter "Chưa đánh giá" **loại nhầm** bài chưa có thẻ nào | điều kiện chỉ xét `cards.hasNewCard` | `notRated = cards.isEmpty \|\| hasNewCard` |
| 5 | Sắp xếp "Lần đọc gần nhất" **không có dữ liệu nguồn** | schema chưa có cột lưu lần đọc | thêm cột `last_read_at` (migration v6) + sort theo `lastReadAt ?? startedAt ?? updatedAt`, đổi nhãn menu thành **"Lần đọc gần nhất"** |

### 3.2 Thay đổi schema & repository

| File | Thay đổi |
|---|---|
| `lib/data/db/schema.dart` | `version` v6; `knowledge_items` thêm cột `last_read_at INTEGER`; migration **5 → 6** (`ALTER TABLE knowledge_items ADD COLUMN last_read_at INTEGER`) |
| `lib/data/models/knowledge_item.dart` | thêm field `lastReadAt` + `copyWith`/`toMap`/`fromMap` |
| `lib/data/repositories/knowledge_repository.dart` | `findByTitle` fallback có điều kiện `lesson_id IS NULL`; **`listEnrolled({String? query})`** (lọc `started_at IS NOT NULL`, tìm theo `LOWER(title/content/details)`, `limit 500`); **`touchLastRead(id, {now})`** (set `last_read_at` + `updated_at`, **không** đổi `started_at`) |
| `lib/features/lessons/lesson_reader_screen.dart` | `enroll(..., lessonId: lesson.id)` + `touchLastRead(...)` |
| `lib/features/knowledge/learned_library_screen.dart` | `_load()` dùng `listEnrolled`; filter `notRated`; sort `lastRead`; nhãn "Lần đọc gần nhất" |

### 3.3 Kiểm thử tự động

**`test/data/enrollment_dedup_test.dart`** (mở rộng) — **9 test PASS**, gồm:
- enroll cùng `lessonId` chỉ tạo 1 `KnowledgeItem`;
- enroll không có `lessonId` vẫn fallback tìm theo title (không phá hành vi cũ);
- `findByTitle` ưu tiên `lessonId` hơn title;
- `listEnrolled` trả đủ item đã đăng ký **kể cả khi query rỗng**;
- `touchLastRead` cập nhật `last_read_at` mà **không đổi `startedAt`**;
- migration v4→v5 (`lesson_id`) và **migration v5→v6 (`last_read_at`)**.

**`test/features/learned_library_enrolled_test.dart`** *(mới)* — **2 test PASS** (hồi quy trực tiếp lỗi #3):
1. Seed 1 bài đã đăng ký → màn "Kho đã học" **hiển thị tiêu đề bài** và **không** hiện empty state;
2. Nhập từ khóa không tồn tại → hiện "Không tìm thấy kết quả"; xóa từ khóa → bài hiện lại.

**Bẫy kỹ thuật đã gặp (ghi lại cho agent sau):**
- `getVersion()` **không tồn tại** trên interface `Database` của `sqflite_common` → dùng `rawQuery('PRAGMA user_version')`.
- FK bật trong test DB → insert `lesson_id` phải tạo lesson trước, nếu không: `SqliteException(787) FOREIGN KEY constraint failed`.
- `LOWER()` của SQLite chỉ hạ chữ **ASCII** → test dữ liệu tiếng Việt có dấu sẽ không match; dùng title ASCII trong test tầng repository.

---

## 4. PHẠM VI 3 — ENTRY POINT ĐIỀU HƯỚNG

| Từ | Tới | Cách vào |
|---|---|---|
| Topic Detail | **Kho kiến thức** (`KnowledgeLibraryScreen`) | IconButton trên AppBar, tooltip `'Kho kiến thức'`, icon `Icons.library_books_outlined`; `onPressed: null` khi `_topic == null` (chống null), push `MaterialPageRoute` với `topicId: _topic!.id` |
| Profile | **Kho đã học** (`LearnedLibraryScreen`) | tile có sẵn trong Hồ sơ (đã xác minh hoạt động bằng test) |

**Kiểm thử:** `test/features/navigation_entry_test.dart` *(mới)* — **2 test PASS**
(tap tooltip `'Kho kiến thức'` → `KnowledgeLibraryScreen` xuất hiện; cuộn tới tile "Kho đã học" → tap → `LearnedLibraryScreen` xuất hiện).

---

## 5. PHẠM VI 4 — DEEPSEEK PROXY (CLIENT-SIDE, AN TOÀN)

**Mục tiêu:** không nhúng API key DeepSeek vào app; app gọi backend proxy, backend giữ key.

| File | Thay đổi |
|---|---|
| `lib/features/ai/http_ai_provider.dart` | thêm `proxyMode` + `clientToken`; `name = 'deepseek-proxy'` khi bật proxy; `isConfigured`: proxy chỉ cần `baseUrl`, chế độ trực tiếp cần `apiKey`; khi proxy **bỏ header `Authorization`**, gửi `X-Client-Token` nếu có |
| `lib/features/ai/ai_service.dart` | `configureFromSettings(proxyMode:)`, `configureDeepSeekDefault(proxyMode:)`; proxy thiếu `baseUrl` → fallback `MockAIProvider` + trả `false` (không giả vờ đã cấu hình) |
| `lib/core/services/preferences_service.dart` | khóa `_keyAiProxyMode`; mặc định đọc từ build: `bool.fromEnvironment('DEEPSEEK_PROXY_MODE')`; getter `aiProxyMode`; `setAiConfig(proxyMode: ...)` |
| `lib/core/services/app_services.dart` | truyền `proxyMode: preferences.aiProxyMode` vào AI service + cập nhật log cảnh báo (`DEEPSEEK_API_KEY` **hoặc** `DEEPSEEK_BASE_URL + DEEPSEEK_PROXY_MODE=true`) |
| `lib/features/profile/profile_screen.dart` | dialog cấu hình AI dùng `StatefulBuilder` + `SwitchListTile.adaptive` **"Gọi qua proxy backend"**; label ô key đổi theo chế độ; lưu `proxyMode` vào prefs |

**Kiểm thử:** `test/features/ai_proxy_test.dart` *(mới)* — **8 test PASS** (proxy mode + clientToken gửi `X-Client-Token` thay vì key; chế độ trực tiếp vẫn `Authorization: Bearer`; thiếu key ở chế độ trực tiếp → `isConfigured == false`; `configureFromSettings(proxyMode: true)` không cần key; proxy thiếu `baseUrl` → mock; `configureDeepSeekDefault(proxyMode)` bật provider khi có `baseUrl`).

**Bật khi build:**
```
flutter build apk --dart-define=DEEPSEEK_BASE_URL=https://<proxy-host>/v1 --dart-define=DEEPSEEK_PROXY_MODE=true
# tùy chọn: --dart-define=DEEPSEEK_CLIENT_TOKEN=<token>
```

---

## 6. NGHIỆM THU TRÊN THIẾT BỊ THẬT (OPPO CPH2203)

### 6.1 Migration v5 → v6 trên **dữ liệu người dùng thật**

| Chỉ số | `before.db` (trước cài) | `after.db` (sau cài + mở app) |
|---|---|---|
| `PRAGMA user_version` | 5 | **6** |
| Cột `knowledge_items` | không có `last_read_at` | **có** `last_read_at` |
| `topics` / `knowledge_items` | 2 / 2 | **2 / 2** |
| `review_cards` / `review_logs` | 1 / 1 | **1 / 1** |
| `lessons` | 2 | **2** |
| Bài đã đăng ký (`started_at IS NOT NULL`) | 1 | **1** |

→ Migration chạy đúng, **không mất dữ liệu**, cột mới `last_read_at` (NULL cho dữ liệu cũ — đúng thiết kế).

Lệnh dùng: `adb install -r build\app\outputs\flutter-apk\app-debug.apk` (giữ data) rồi `adb exec-out run-as com.mindkeeper.mind_keeper cat app_flutter/mind_keeper.db`.

### 6.2 Cold-start & logcat

Sau `adb install -r` + `am start`: app vào MainActivity, `adb logcat -d` lọc `flutter|mind_keeper` **không có exception/crash** của Dart/Flutter (chỉ còn log hệ thống của ColorOS).

### 6.3 Light / Dark theme — đo bằng số (không chỉ cảm quan)

Chuyển theme hệ thống bằng `adb shell cmd uimode night yes|no` (không dùng được `settings put secure` — máy không cấp `WRITE_SECURE_SETTINGS`), rồi chụp màn hình và đo độ sáng trung bình:

| Ảnh | Kích thước | Mean luminance (0–255) |
|---|---|---|
| `DOCS/QA/artifacts/GD20/01_home_light.png` | 1080×2400 | **212.6** (nền sáng) |
| `DOCS/QA/artifacts/GD20/02_home_dark.png` | 1080×2400 | **38.1** (nền tối) |

→ Palette theme-aware thực sự áp dụng khi đổi theme hệ thống (chênh lệch 174 điểm sáng).

### 6.4 Giới hạn của phiên nghiệm thu này (minh bạch)

- Phiên agent này **không đọc được nội dung ảnh** → không thể "nhìn" screenshot để xác nhận bố cục chữ/màu từng thành phần. Bù lại:
  - hành vi chức năng (list đã học, filter/sort, entry point, migration, proxy) được phủ bằng **test tự động** (widget/unit);
  - light/dark được xác nhận bằng **số đo luminance** và logcat không crash;
  - ảnh chụp vẫn được lưu trong `DOCS/QA/artifacts/GD20/` để người dùng đối chiếu thị giác.
- `uiautomator dump` **không trả text** với app Flutter (chưa bật accessibility/semantics) → điều hướng UI bằng toạ độ là cách duy nhất, nên không thực hiện trong phiên này.

---

## 7. DANH SÁCH TEST MỚI/MỞ RỘNG TRONG GĐ20

| File test | Số test | Kết quả | Nội dung |
|---|---|---|---|
| `test/core/theme_palette_test.dart` *(mới)* | 5 | PASS | Palette theme-aware light/dark, `lerp`, `context.appColors` |
| `test/features/ai_proxy_test.dart` *(mới)* | 8 | PASS | Proxy mode, header/token, cấu hình AiService |
| `test/features/navigation_entry_test.dart` *(mới)* | 2 | PASS | Entry point TopicDetail→Kho kiến thức, Profile→Kho đã học |
| `test/features/learned_library_enrolled_test.dart` *(mới)* | 2 | PASS | Hồi quy: list bài đã học + tìm kiếm |
| `test/data/enrollment_dedup_test.dart` *(mở rộng)* | 9 | PASS | Dedup, `listEnrolled`, `touchLastRead`, migration v4→v5, v5→v6 |
| **Full suite** | **131** | **ALL PASS** | Không có test nào bị bỏ/xoá |

---

## 8. HẠNG MỤC BLOCKED — DEPLOY PROXY BACKEND

**Trạng thái:** ⛔ Không thực hiện được trong repo này. Client đã sẵn sàng, backend chưa deploy.

**Bằng chứng blocker:** repo không có thư mục `functions/`, không có `firebase.json`, không có project Firebase nào được liên kết (`firebase use` không có target) → không thể `firebase deploy --only functions`.

**Các bước cần làm (khi có môi trường/quyền):**
1. `npm i -g firebase-tools && firebase login && firebase init functions` (tạo `functions/`, `firebase.json`).
2. Viết function proxy (Node 20) nhận `POST /v1/chat/completions`, giữ `DEEPSEEK_API_KEY` trong Secret Manager (`firebase functions:secrets:set DEEPSEEK_API_KEY`), forward sang `https://api.deepseek.com`, kiểm tra `X-Client-Token` nếu dùng.
3. `firebase deploy --only functions` → lấy URL `<region>-<project>.cloudfunctions.net/proxy`.
4. Build app với `--dart-define=DEEPSEEK_BASE_URL=<url>/v1 --dart-define=DEEPSEEK_PROXY_MODE=true` (+ `DEEPSEEK_CLIENT_TOKEN` nếu có).
5. Verify end-to-end trên device: gọi 1 tác vụ AI, xác nhận **không** có key trong APK (`strings`/APK analysis) và request không mang `Authorization: Bearer <key>`.

---

## 9. VIỆC CÒN LẠI / KHUYẾN NGHỊ

1. **Đối chiếu thị giác ảnh chụp** `DOCS/QA/artifacts/GD20/*.png` (light/dark) do người dùng thực hiện — agent phiên này không đọc được ảnh.
2. Deploy proxy backend theo §8 rồi chạy verify bước 5.
3. iOS build vẫn cần macOS/Xcode (`flutter build ios --no-codesign` trên Mac + `pod install`) — không đổi từ GĐ15.x.
2 lượt cold-start đã ổn; nên chạy thêm smoke các luồng chính (Đọc bài → Ôn tập) bằng tay trên bản build này nếu cần mức chứng cứ cao hơn.
3. **Không commit/push** — toàn bộ thay đổi GĐ20 đang ở working tree (32 file tracked đã sửa + 5 file mới: `lib/core/theme/app_palette.dart`, 4 file test, 1 file báo cáo này).

---

## 10. FILE THAY ĐỔI TRONG GĐ20 (tóm tắt)

**Thêm mới:** `lib/core/theme/app_palette.dart`, `test/core/theme_palette_test.dart`, `test/features/ai_proxy_test.dart`, `test/features/navigation_entry_test.dart`, `test/features/learned_library_enrolled_test.dart`, `DOCS/QA/GD20_FINAL_ACCEPTANCE.md`, `DOCS/QA/artifacts/GD20/*.png`

**Sửa:** `lib/core/theme/app_theme.dart`, `lib/core/theme/app_colors.dart`, `lib/core/widgets/*` (7 widget), 13 màn hình feature, `lib/core/services/app_services.dart`, `lib/core/services/preferences_service.dart`, `lib/data/db/schema.dart`, `lib/data/models/knowledge_item.dart`, `lib/data/repositories/knowledge_repository.dart`, `lib/features/ai/ai_service.dart`, `lib/features/ai/http_ai_provider.dart`, `test/data/enrollment_dedup_test.dart`
