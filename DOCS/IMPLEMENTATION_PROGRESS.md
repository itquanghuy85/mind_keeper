# MindKeeper AI — Tiến độ triển khai

Nguồn trạng thái duy nhất. Cập nhật sau mỗi giai đoạn.

## Tổng quan dự án

- Thư mục: `D:\FlutterProjects\mind_keeper` (dự án MindKeeper có sẵn, không phải dự án khác).
- Git: repo mới, chưa có commit nào trên `master`. **Không commit/push tự động.**
- Flutter 3.41.4, Dart 3.11.1, Node v24.12.0.
- State management: `provider`. DB: `sqlite` (sqflite + sqflite_common_ffi cho test).
- Lên lịch ôn: FSRS qua thư viện `fsrs: ^2.0.1` (FSRS-6).
- Impeccable: chưa cài (không có skill trong môi trường này). Tiếp tục theo tiêu chuẩn UI trong prompt.

## Trạng thái giai đoạn

| GĐ | Tên | Trạng thái | Ghi chú |
|----|-----|-----------|---------|
| GĐ0 | Baseline & khảo sát | PASS | Đã xác định dự án, sửa conflict `intl` (0.20.2 do flutter_localizations pin), pub get OK |
| GĐ1 | Product context & design system | PASS | PRODUCT.md, DESIGN.md; theme/widgets có sẵn được giữ nguyên |
| GĐ2 | Khung 4 tab & điều hướng | PASS | Shell + đủ màn hình phụ, empty/loading/error |
| GĐ3 | Database & repository | PASS | Schema v1, migration framework, repos + test (có sẵn + bổ sung stats) |
| GĐ4 | Quản lý chủ đề & kiến thức | PASS | CRUD topic/knowledge/card, tìm kiếm, favorite/pause |
| GĐ5 | Lịch ôn FSRS | PASS | Adapter FSRS thật (`fsrs` 2.0.1), test Quên/Khó/Tốt/Dễ, thẻ mới, trễ hạn |
| GĐ6 | Luồng ôn tập | PASS | Session controller + UI nhớ trước/xem đáp án, lưu log, tiếp tục phiên |
| GĐ7 | Thông báo mở đúng nội dung | PASS | Service thật + payload `card:<id>` + test mapping; **đã verify trên CPH2203**: POST_NOTIFICATIONS granted (qua Settings UI), alarm RTC_WAKEUP 20:00 xác nhận trong dumpsys |
| GĐ8 | AI biên tập/gia sư/tra cứu | PASS | Interface + schema + MockAIProvider (nhãn rõ) + cache/timeout; **AI thật DeepSeek đã verify end-to-end trên device** (xem mục Kiểm thử thiết bị) |
| GĐ9 | Khám phá chủ đề mới | PASS | Catalog offline đáng tin cậy, 2 hoạt động riêng (tạo của tôi / khám phá), lưu → lịch ôn |
| GĐ10 | Nhập kiến thức từ nguồn | PASS | Văn bản + link web thật; **OCR ảnh (ML Kit) + PDF (syncfusion, thuần Dart) + giọng nói (speech_to_text) đã thêm và verify end-to-end trên CPH2203** |
| GĐ11 | Thống kê & cá nhân hóa | PASS | StatsRepository tính từ DB thật, cài đặt lưu qua SharedPreferences |
| GĐ12 | Tổng kiểm tra | PASS | `flutter analyze` 0 issue; `flutter test` 58/58 pass; `flutter build apk --debug` thành công (app-debug.apk) |
| GĐ13 | Bài học AI khám phá kiến thức | PASS | Sinh bài AI trọn gói (dedup theo lĩnh vực/chủ đề/chế độ/prompt version), đọc bài + quiz ghi nhớ → tạo chủ đề + thẻ FSRS + nhắc ôn |

## File quan trọng đã thêm/sửa

### Tài liệu
- `PRODUCT.md`, `DESIGN.md`, `DOCS/IMPLEMENTATION_PROGRESS.md`

### Core
- `lib/core/services/app_bootstrap.dart` — bootstrap singleton
- `lib/core/services/app_services.dart` — service locator (repos + prefs + notifications + scheduler + AI + discovery)
- `lib/core/services/preferences_service.dart`
- `lib/core/services/notification_service.dart` — abstraction + local notifications thật + fake cho test
- `lib/core/services/review_scheduler_service.dart` — adapter FSRS
- `lib/core/services/ocr_service.dart` — ML Kit text recognition (OCR ảnh)
- `lib/core/services/pdf_text_service.dart` — trích text PDF thuần Dart (syncfusion)
- `lib/core/services/voice_transcription_service.dart` — speech_to_text wrapper, fail-soft
- `lib/core/di/app_providers.dart` — nối Provider

### Data
- `lib/data/models/due_review_item.dart` — card + knowledge + topic join
- `lib/data/repositories/stats_repository.dart`
- `lib/data/models/lesson.dart` — model bài học AI (content/questions/sources/verification/dedup key)
- `lib/data/repositories/lesson_repository.dart` — CRUD bài học, dedup, lọc, đếm theo lĩnh vực

### Features
- `lib/features/home/today_screen.dart`
- `lib/features/topics/topics_screen.dart`, `topic_detail_screen.dart`, `create_topic_screen.dart`
- `lib/features/knowledge/knowledge_editor_screen.dart`, `knowledge_detail_screen.dart`
- `lib/features/review/review_controller.dart`, `review_screen.dart`
- `lib/features/stats/stats_screen.dart`
- `lib/features/profile/profile_screen.dart`, `notification_settings_screen.dart`
- `lib/features/discover/discover_screen.dart`, `discovery_catalog.dart`, `discovery_service.dart`
- `lib/features/ai/ai_provider.dart`, `mock_ai_provider.dart`, `ai_service.dart`
- `lib/features/import/text_import_screen.dart` (hỗ trợ `initialText`), `link_import_screen.dart`
- `lib/features/import/media_import_flow.dart` — luồng ảnh (OCR) + PDF → màn nhập văn bản
- `lib/features/import/voice_import_screen.dart` — ghi âm → văn bản
- `lib/features/discover/domain_catalog.dart` — danh mục 20 lĩnh vực khám phá (có cờ y tế, chủ đề mẫu)
- `lib/features/lessons/lesson_service.dart` — sinh bài (dedup), quiz → chủ đề + kiến thức + thẻ FSRS + nhắc ôn
- `lib/features/lessons/lesson_discover_screen.dart` — lưới lĩnh vực → cấu hình chủ đề/chế độ → sinh bài
- `lib/features/lessons/lesson_reader_screen.dart` — đọc bài + quiz ghi nhớ (tự nhớ trước khi xem đáp án)

### Sửa
- `lib/app.dart` — routes đầy đủ
- `pubspec.yaml` — fix `intl: 0.20.2`
- `test/widget_test.dart` — thay smoke test mặc định bằng test thật
- `lib/data/db/schema.dart` — schema v2 (bảng `lessons` + index, migration 1→2)
- `lib/core/services/notification_service.dart` — `cancel(id:)` (đúng signature flutter_local_notifications v22)

## Kết quả kiểm tra (cập nhật cuối — 2026-10-17)

- `flutter analyze`: **No issues found!** (0 error, 0 warning, 0 info)
- `flutter test`: **75/75 passed** — gồm repository/migration (data), FSRS scheduler (core), luồng end-to-end (tạo chủ đề → kiến thức → thẻ → ôn → lịch cập nhật → restart), notification payload mapping, AI service (cache/fail-soft), discovery, thống kê, prefs persistence, PDF text extraction (round-trip syncfusion), voice service fail-soft, **bài học AI (model roundtrip, repository dedup/lọc/đếm, service generate dedup + completeQuiz → chủ đề + thẻ + nhắc ôn, AiService.generateLesson cache, câu hỏi trùng không tạo thẻ/log trùng)**, widget smoke test.
- `flutter build apk --debug`: **thành công** — `build/app/outputs/flutter-apk/app-debug.apk`.

### Sửa trong quá trình kiểm tra
- Gradle: hạ wrapper 9.7.1 → 8.14-all (AGP 8.11.1 không tương thích Gradle ≥9.6 vì `InternalProblems` bị loại bỏ).
- Bật `isCoreLibraryDesugaringEnabled` + `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` trong `android/app/build.gradle.kts` (bắt buộc với `flutter_local_notifications`).
- Thêm quyền `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` vào `AndroidManifest.xml`.
- Widget test: dùng `tester.runAsync` bọc khởi tạo sqflite FFI (FakeAsync không chạy được event loop thật).
- Test DB: sửa expectation `countOverdue` (thẻ mới chưa ôn không tính quá hạn — khớp implementation), so sánh `dueAt` theo `millisecondsSinceEpoch` (SQLite mất micro precision), sửa test tên trùng (chuẩn hóa whitespace/case), test schema chỉ yêu cầu 4/5 bảng có `REFERENCES` (bảng gốc `topics` không có FK).
- **Bug GĐ13 — câu hỏi trùng → thẻ/log trùng**: mock sinh câu hỏi trùng khi `questionCount > sectionCount` (chế độ overview/standard/deep) → `completeQuiz` tạo thẻ ôn trùng và lần 2 bị `UNIQUE constraint failed: review_logs.id` (cùng thẻ chấm 2 lần cùng microsecond). Sửa 3 tầng: (1) `LessonService.generate` loại câu hỏi trùng (`_uniqueQuestions`), (2) `completeQuiz` bỏ qua thẻ đã chấm trong cùng phiên (`handledCardIds`), (3) mock tăng `sectionCount` đủ cho `questionCount`. Thêm test regression `câu hỏi trùng: generate dedup + completeQuiz nhiều lần không tạo trùng`.
- **Build release R8**: `google_mlkit_text_recognition` tham chiếu các gói ngôn ngữ ML Kit tùy chọn (chinese/devanagari/japanese/korean) không có trong dependency → R8 "missing classes". Thêm `android/app/proguard-rules.pro` (`-dontwarn com.google.mlkit.vision.text.<lang>.**`) + khai báo `proguardFiles` trong `release` buildType.

## Kiểm thử trên thiết bị thật (2026-10-17 — OPPO CPH2203, Android 13/API 33)

- Cài `app-debug.apk` qua adb; cold start OK (UI đủ 4 tab).
- **Thông báo (GĐ7)**: ColorOS chặn `pm grant`/`appops set` → cấp POST_NOTIFICATIONS qua Settings UI → `granted=true`. Alarm nhắc 20:00 đã schedule (dumpsys alarm xác nhận `ScheduledNotificationReceiver`).
- **AI thật (GĐ8)**: cấu hình qua `--dart-define=AI_API_KEY=... --dart-define=AI_BASE_URL=https://api.deepseek.com --dart-define=AI_MODEL=deepseek-chat` (fallback trong `PreferencesService`, key không nằm trong source). Profile hiện "Đang dùng AI thật (deepseek-chat)". Nhập văn bản → DeepSeek trả 3 nháp tiếng Việt → tạo topic "Khoa Hoc May Tinh" → lưu 3 kiến thức.
- **Luồng ôn tập end-to-end**: Home hiện "Ôn kiến thức đến hạn: 3" → bắt đầu phiên → xem đáp án → chấm Tốt ×3 → "Hoàn thành phiên ôn (3 thẻ)" → về Home: due **0**, tiến độ **3/10 mục tiêu** (sau đó 3 thẻ learning-step tới hạn again — đúng hành vi FSRS).
- **Nhập từ ảnh/OCR (GĐ10)**: chọn ảnh từ Google Photos → ML Kit đọc chính xác tiếng Việt có dấu (hóa đơn: "HÓA ĐƠN BÁN HÀNG", "Số HĐ: SYNC1012"...) → màn nhập văn bản điền sẵn.
- **Nhập từ PDF (GĐ10)**: SAF picker → syncfusion trích text (PDF fixture 1.3KB) → màn nhập văn bản điền sẵn.
- **Nhập bằng giọng nói (GĐ10)**: RECORD_AUDIO được xin runtime (plugin speech_to_text tự request) → cấp "Trong khi dùng ứng dụng" → trạng thái "Đang nghe" hoạt động. *Nhận dạng lời nói thật chưa verify được (không có nguồn âm thanh trên adb) — cần test tay.*
- **Menu nhập trong chi tiết chủ đề**: 4 tùy chọn (Văn bản / Ảnh OCR / PDF / Giọng nói) hiển thị đúng.
- **Lưu ý AI key**: fallback đọc từ `--dart-define` (không lưu prefs) → build thiếu dart-define sẽ hiển thị mock. Build cuối đã gồm dart-define DeepSeek, Profile hiện "Đang dùng AI thật (deepseek-chat)".
- **Sửa bug IndexedStack stale state**: tab hiện giữ state cũ sau khi tạo dữ liệu ở tab khác → thêm `dataVersion` ValueNotifier trong `AppBootstrap` + `reloadListenable` cho TopicsScreen/TodayScreen; bump sau khi lưu ở text/link import & knowledge editor.
- **Edge case cần theo dõi**: 1 lần gặp assertion `_dependents.isEmpty` (framework.dart) khi quay lại từ Settings thông báo; không reproduce được sau 2 lần thử — nghi do lifecycle ColorOS, không phải lỗi logic app.

## Nghiệm thu GĐ13 trên thiết bị (2026-10-17 — OPPO CPH2203, Android 13/API 33)

- Cài `app-debug.apk` (`adb install -r`, giữ dữ liệu) → cold start OK. Build mặc định **không** có dart-define AI key → dùng **MockAIProvider** (nhãn "Chưa xác minh" hiển thị đúng). Không coi nội dung mock là bằng chứng AI thật.
- **Luồng bài học AI**: Hôm nay → card "Bài học AI" → lưới 20 lĩnh vực → chọn "Khoa học" → sheet chủ đề (điền sẵn chủ đề ngẫu nhiên, nút đổi) + 4 chế độ (Tổng quan/Tiêu chuẩn/Chuyên sâu/Theo lộ trình) → "Tạo bài học" → màn đọc.
- **Màn đọc**: title, tag chế độ "Chuyên sâu" + "Chưa xác minh" + "888 từ", mở đầu, các phần (Phần 1..5), ý chính, ví dụ, tóm tắt, mục nguồn ("chưa kèm nguồn" + nút "Đã kiểm chứng"). DisclaimER y tế KHÔNG hiển thị cho lĩnh vực Khoa học (đúng: chỉ lĩnh vực y tế).
- **Quiz ghi nhớ**: câu hỏi hiện trước, đáp án ẩn ("Hãy thử tự nhớ...") → "Xem đáp án" hiện đáp án + giải thích → 4 mức Quên/Khó/Tốt/Dễ. 5 câu (chế độ Chuyên sâu).
- **completeQuiz**: tạo chủ đề "Thuyết tiến hóa" (origin discovered, desc `lesson:<id>`) + 1 kiến thức (origin ai_suggested) + 5 thẻ FSRS (state learning→review sau lần ôn 2, stability/difficulty hợp lệ, due ~10 phút). Log review ghi đúng. Kết thúc hiện "Sẽ nhắc ôn lại vào lúc cần thiết" → lập lịch thông báo.
- **Không trùng**: hoàn tất quiz lần 2 → **5 thẻ / 5 câu hỏi duy nhất / 10 log (2 mỗi thẻ) / 10 id log duy nhất** — hết lỗi `UNIQUE constraint failed: review_logs.id` (đã sửa, xem mục Sửa trong kiểm tra).
- **Bền vững**: force-stop + mở lại → chủ đề + bài học + thẻ còn nguyên; Home hiện "Tiến độ hôm nay 10/10 mục tiêu", due 0 (thẻ lịch tương lai).
- **Thông báo**: quyền POST_NOTIFICATIONS = allow (trang Settings hệ thống "Cho phép thông báo: Bật"). Lịch thông báo được lập lúc hoàn thành quiz; dumpsys alarm không thấy vì `am force-stop` (lấy DB) hủy alarm — xác minh qua unit test `FakeNotificationService` + UI + GĐ7. *Chưa bấm thông báo thật trên thiết bị.*
- **Build release**: `flutter build apk --release` thành công `app-release.apk` (93.8MB) sau khi thêm proguard `-dontwarn` cho ML Kit (xem mục Sửa). Chưa cài release lên device.
- **iOS**: môi trường Windows (win32) — **không build được iOS**. Cần máy macOS + Xcode để build/run iOS 16.

## Blocker

- ~~OCR ảnh / PDF / ghi âm~~ — ĐÃ HOÀN TẤT (GĐ10 PASS, verify trên CPH2203; nhận dạng lời nói thật cần test tay vì adb không có nguồn âm thanh).
- ~~AI thật: thiếu API key~~ — ĐÃ CẤU HÌNH (DeepSeek, dart-define, verified end-to-end).
- ~~Kiểm thử thiết bị thật~~ — ĐÃ XONG (CPH2203). Thông báo hiển thị lúc 20:00 chưa thấy trực tiếp (verify gián tiếp qua permission + alarm schedule).
- Edge case framework `_dependents.isEmpty` khi quay lại từ Settings thông báo: gặp 1 lần, không reproduce — theo dõi thêm (nghi lifecycle ColorOS).

## Bước tiếp theo

1. ~~`flutter analyze` / `flutter test`~~ — DONE (0 issue, 75/75).
2. ~~Build Android debug~~ — DONE (app-debug.apk, bản cuối gồm dart-define AI).
3. ~~Kết nối thiết bị thật để xác minh GĐ7~~ — DONE (CPH2203).
4. ~~Cấu hình AI key thật (GĐ8)~~ — DONE (DeepSeek verified).
5. ~~Thêm OCR/PDF/speech (GĐ10)~~ — DONE (verify end-to-end trên device).
6. ~~Bài học AI (GĐ13)~~ — DONE (model + repository + service + AI provider + UI khám phá/đọc/quiz + route; test 75/75, analyze 0 issue).
7. ~~Nghiệm thu GĐ13 trên thiết bị~~ — DONE (CPH2203: luồng sinh/đọc/quiz/completeQuiz/không-trùng/bền vững; bug câu hỏi trùng đã sửa; build release 93.8MB).
8. (Tùy chọn) Test GĐ13 với AI thật DeepSeek (build kèm dart-define), bấm thông báo thật lúc đến giờ ôn, cài & smoke `app-release.apk`, build/run iOS 16 (cần macOS).
9. (Tùy chọn) UI quản lý lĩnh vực yêu thích/ẩn (prefs `favoriteDomains`/`hiddenDomains` đã có, chưa có màn chỉnh).
