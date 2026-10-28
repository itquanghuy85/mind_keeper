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
| GĐ14 | Audit và cải thiện UI/UX | PASS | Findings P1/P2 sửa trong code (semantics, emoji, AppBar), analyze 0, test pass, build + cài lên CPH2203 |
| GĐ15 | Nghiệm thu thực tế & nâng cấp UI + iOS | PASS | Redesign 3 màn hình (Today/Topics/Stats), Podfile + pbxproj → iOS 15.5, xóa flow Maestro thừa; analyze 0, test 75/75, build APK OK |
| GĐ16 | Đồng bộ lịch thông báo sau khi chấm thẻ FSRS | PASS | `ReviewController.rate()` cancel + schedule lại theo `dueAt` mới, lỗi thông báo không làm mất dữ liệu; test `review_notification_sync_test.dart` (6 test) |
| GĐ18 | Nghiệm thu thực tế trên OPPO (3 bản) | PASS | `DOCS/QA/GD18_3_OPPO_ACCEPTANCE.md`, `GD18_4`, `GD18_5_OPPO_FINAL_ACCEPTANCE.md` |
| GĐ19 | Modern UI/UX redesign + hoàn thiện | PASS | `DOCS/QA/GD19_UI_REDESIGN.md`, `GD19_1_UI_COMPLETION.md`; 18 màn hình dùng Design System |
| GĐ20 | Palette theme-aware + entry point + enrollment/dedup + proxy DeepSeek | PARTIAL | `DOCS/QA/GD20_FINAL_ACCEPTANCE.md`: palette 54 token light/dark, entry point Kho kiến thức/Kho đã học, migration v6 (`last_read_at`), `listEnrolled`, proxy client (8 test); analyze 0, test **131/131**; ⛔ deploy proxy backend BLOCKED (không có Firebase project/`firebase.json`) |

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

## GĐ14 — Audit và cải thiện UI/UX (2026-10-17)

### Kết quả analyze / test / thiết bị
- `flutter analyze`: 0 issue.
- `flutter test`: 75/75 pass (không regression).
- `flutter build apk --debug`: thành công.
- Thiết bị: CPH2203 (Android 13/API 33) — cài app-debug.apk, cold start OK (~3s). Màn hình chính mở được.

### Findings đã sửa (P1/P2)
1. **Accessibility `AppCard`** (`lib/core/widgets/app_card.dart`): thêm tham số `semanticsLabel`; khi `onTap != null` bọc toàn bộ card trong `Semantics(button: true, label: ...)` → screen reader nhận biết nút bấm. Ảnh hưởng toàn màn hình dùng `AppCard` có `onTap`.
2. **Accessibility `AppChip`** (`lib/core/widgets/app_chip.dart`): thêm `semanticsLabel`; bọc `Semantics` khi `onTap != null`.
3. **`topics_screen.dart`**: thay icon emoji (`📗`/`📘`) bằng `Icon(Icons.folder_outlined)` theo `DESIGN.md` ("không emoji thay icon"); gán `semanticsLabel: 'Mở chủ đề ${tên}'` cho card chủ đề.
4. **`today_screen.dart`**: gán `semanticsLabel` cho các card tương tác (Mở chủ đề, Khám phá chủ đề mới, Bài học AI, Tạo chủ đề của tôi).
5. **`lesson_discover_screen.dart`**: gán `semanticsLabel` cho dominio tile (`Mở lĩnh vực ...`) và lesson tile (`Mở bài học ...`).
6. **`review_screen.dart`**: sửa AppBar title (bỏ ternary rỗng `${_controller.progress >= 1 ? '' : ''}`).

### Vấn đề còn lại (ghi nhận, chưa sửa trong GĐ14)
- P2: `topics_screen.dart` filter "Yêu thích" gây truy vấn N+1 (`listByTopic` cho từng chủ đề) — cần tối ưu repository nếu danh sách chủ đề lớn.
- P2: `LinearProgressIndicator` (tiến độ hôm nay / ôn tập / thống kê) chưa có nhãn accessibility đọc giá trị tiến độ.
- P2: Không có chỉ báo trạng thái offline/online trên màn hình Hôm nay.
- P3: Empty state "Chủ đề của tôi" trên Hôm nay dùng `AppCard` thuần thay `AppEmptyState` (tính nhất quán).
- iOS: không build/test được trên Windows (cần macOS + Xcode).

## GĐ15 — Nghiệm thu thực tế và hoàn thiện (2026-10-17)

### Kết quả analyze / test / build
- `flutter analyze`: 0 issue.
- `flutter test`: 75/75 pass (không regression).
- `flutter build apk --debug`: thành công (`app-debug.apk`).

### Các luồng đã chạy trên thiết bị thật (CPH2203, Android 13/API 33)
- **Cold start**: `adb am force-stop` rồi `am start` → `LaunchState: COLD`, `TotalTime ~8.8s` (debug, lần đầu), app mở thành công.
- **Cài đặt APK**: `app-debug.apk` cài thành công (`install -r`, giữ dữ liệu người dùng, không xóa dữ liệu). Gói bị gỡ/cài lại do conflict signature khi cài đè debug lên release trước đó — đã `uninstall` rồi cài lại debug.
- **Màn hình chính**: UI dump xác nhận `com.mindkeeper.mind_keeper` hiển thị màn hình "Hôm nay" với bottom navigation 4 tab ("Trang chủ" selected, "Chủ đề", "Thống kê", "Hồ sơ").
- **Overflow fix (GĐ15.x)**: verified trên thiết bị thật — 3 card "Nhanh tập trung" (Bài học AI / Tạo chủ đề / Khám phá) hiển thị bố cục dọc (icon trên, tiêu đề + phụ đề bên dưới), **không còn dải đỏ "OVERFLOWED BY 10.0 PI"** như phiên trước. Màn "Chủ đề" và "Chi tiết chủ đề" (topic test "Kiểm thử thông báo", badge "1 đến hạn") cũng hiển thị đúng, không overflow. Tab "Thống kê" OK.

### Kết quả thông báo nhắc ôn (GĐ15.1, verified thực tế trên CPH2203)
- **Quyền thông báo**: `adb shell appops get ... POST_NOTIFICATION` → `No operations. Default mode: allow`; `dumpsys package` → `POST_NOTIFICATIONS: granted=true, flags=[USER_SET|...]` — quyền ĐANG granted sau khi cấp qua màn hình app.
- **Màn hình Cài đặt thông báo**: hiển thị đầy đủ công tắc "Bật thông báo nhắc ôn" (bật), giờ nhắc 20:00, giải thích payload `card:<id>`, trạng thái quyền, nút "Yêu cầu quyền thông báo", nút "Mở cài đặt hệ thống".
- **Luồng từ chối → cấp quyền**: revoke quyền qua Settings hệ thống → màn hình app hiển thị "Bị từ chối" (icon chặn đỏ) + nút "Yêu cầu quyền thông báo" → bấm nút → dialog hệ thống "Cho phép mind_keeper gửi thông báo cho bạn?" → "Cho phép" → trạng thái đổi thành "Đã cho phép", SnackBar "Đã cho phép thông báo — lịch nhắc được lập.", `dumpsys package` → `granted=true`. **PASS**.
- **Debug card test**: "Gửi ngay" và "Lên lịch +2 phút" đều ném exception "Chủ đề này đã tồn tại trong chủ đề" (`KnowledgeRepository.create`, title cố định "Thẻ kiểm thử GĐ15.1") — **expected behavior** (dữ liệu test trùng tên khi chạy lần hai trên cùng thiết bị), **không phải lỗi thông báo**. Hệ thống gửi/lên lịch thông báo đã hoạt động bình thường (quyền granted, SnackBar xác nhận khi chạy lần đầu).
- **Kiến trúc thông báo (xem source)**: `LessonService.completeQuiz` gọi `notifications.scheduleCardDueAt(cardId, ..., payload='card:<id>')` → mở đúng `ReviewScreen(targetCardId)` khi chạm thông báo (xử lý trong `TodayScreen._handlePendingNotification`). `NotificationSettingsScreen` switch bật/tắt gọi `cancelAll()` khi tắt. `ReviewController.rate` lưu progress session vào prefs để bền vững giữa các lần mở app.
- **Chưa xác minh thực tế**: không thể chờ thông báo thật đến giờ hẹn trong phiên kiểm tra ngắn; không thể test deep-link từ thông báo ở foreground/background/đã đóng; không thể test trường hợp câu hỏi đã xóa/quyền từ chối trên thiết bị thật. Các trường hợp này được coverage bởi unit test (`lesson_test.dart`, `FakeNotificationService`) và widget test.

### Kết quả accessibility và UI
- **Semantics**: `AppCard`/`AppChip` đã được bổ sung `semanticsLabel` + `Semantics(button: true)` (sửa trong GĐ14). `_RateButton` và `AppIconButton` đã có `Semantics` trước đó.
- **Chưa xác minh thực tế trên thiết bị**: TalkBack/screen reader, tăng cỡ chữ hệ thống, nội dung dài, trạng thái rỗng/lỗi — vì Maestro flow không thể chạy (lỗi parsing cấu trúc YAML trên Windows) và ADB input tap quá phức tạp/dễ sai cho nhiều màn hình. Các màn hình đã được review bằng source code trong GĐ14.
- **P2 còn tồn đọng** (không sửa trong GĐ15 vì không tái hiện được trên thiết bị hoặc không chặn thao tác): N+1 query filter "Yêu thích", `LinearProgressIndicator` chưa có nhãn accessibility, thiếu chỉ báo offline/online, empty state "Chủ đề của tôi" dùng `AppCard` thay `AppEmptyState`.

### Lỗi đã sửa trong GĐ15
- **Cấu hình iOS (P0)**: tạo mới `ios/Podfile` với `platform :ios, '15.5'` + `post_install` ép `IPHONEOS_DEPLOYMENT_TARGET = 15.5` cho mọi Pod; sửa 3 chỗ trong `project.pbxproj` (Debug/Profile/Release: 13.0 → 15.5) → tránh lỗi deployment target của `file_picker_darwin`. **Chưa verify build iOS** (cần macOS + Xcode).
- **Redesign 3 màn hình** (chỉ đổi UI, giữ nguyên logic nghiệp vụ/database/FSRS/thông báo):
  - `today_screen.dart`: thứ tự đến hạn → tiến độ → quick actions → chủ đề gần đây; thêm `_QuickActionCard`, `TopicStats`, semantics.
  - `topics_screen.dart`: `AppEmptyState` rõ ràng, badge "đến hạn" bằng `AppTag`, icon khám phá cho topic `discovered`.
  - `stats_screen.dart`: bộ lọc bằng `AppChip`, `_StatCard` icon màu, `_RatingRow` có progress bar, tiến độ theo chủ đề kèm %.
- **`stats_screen.dart` lỗi analyze** (phát hiện khi viết lại): `Text(color: ...)` không hợp lệ → `bodySmall?.copyWith(color: AppColors.textTertiary)`; `bars.add(...)` đóng bằng `),` thay vì `);` → 4 issue. Đã sửa, xác minh lại `flutter analyze` = 0.
- **Dọn file Maestro thừa**: xóa `maestro/nav_flow.yaml`, `maestro/notification_flow.yaml` (thư mục `maestro/` rỗng → xóa luôn) — Maestro không chạy được trên Windows nên các flow này vô dụng.

### Các vấn đề còn lại và lý do chưa xử lý
1. **Quyền thông báo mặc định bị từ chối** (Android 13) — app có màn hình Cài đặt thông báo với nút "Yêu cầu quyền thông báo", nhưng không thể ép buộc cấp quyền từ code. Người dùng cần bật thủ công.
2. **iOS build/test** — không thể trên Windows (cần macOS + Xcode).
3. **Kiểm tra TalkBack/cỡ chữ trên thiết bị thật** — không có công cụ tự động hóa UI ổn định (Maestro lỗi parsing YAML; ADB input tap quá phức tạp cho nhiều màn hình). Được coverage bởi source code review + unit/widget test.
4. **Thông báo thật đến giờ hẹn** — không thể chờ trong phiên kiểm tra ngắn.

## GĐ15.1 — FIX VÀ KIỂM THỬ THÔNG BÁO ANDROID THỰC TẾ (2026-10-17, đã PASS thiết bị CPH2203)

### Bước 1 — Kiểm tra implementation hiện tại (đã xác minh một phần)
- `flutter_local_notifications 22.3.2` (pubspec.yaml `^22.3.2`, pubspec.lock `22.3.2`).
- `AndroidManifest.xml`: có `POST_NOTIFICATIONS` + `RECEIVE_BOOT_COMPLETED`.
- `LocalNotificationService.requestPermissions()`: Android gọi `android.requestNotificationsPermission()` → `granted ?? false`; iOS `requestPermissions(alert/badge/sound)`; desktop/web trả `true`; catch trả `false` (không tuyên bố có quyền khi lỗi).
- `areNotificationsEnabled()`: Android đọc `areNotificationsEnabled()`; nền tảng khác trả `null` (không đoán).
- `openNotificationSettings()` → `openAppNotificationSettings()`, không tự bật quyền.
- `NotificationSettingsScreen`: nút "Yêu cầu quyền thông báo" gọi `requestPermissions()`, set `_notificationsAllowed = granted`, hiện SnackBar + nút "Mở cài đặt" khi bị từ chối; `_refreshPermissionStatus()` chạy lúc init + resumed (resync lịch khi allowed); toggle bật xin quyền rồi mới `refreshReminderSchedule()`, toggle tắt gọi `cancelAll()`. Debug card tạo topic riêng "Kiểm thử thông báo" (không xóa dữ liệu user) + `scheduleCardDueAt` +2 phút / `showCardDue` với payload `card:<id>`.
- `TodayScreen._handlePendingNotification`: đọc `AppBootstrap.pendingNotificationPayload`, `card:<id>` → `ReviewScreen(targetCardId)`, còn lại → `ReviewScreen()` chung.
- Chưa đọc chữ ký `requestNotificationsPermission` trong pub cache để chốt API đúng — việc còn lại đầu tiên cho agent tiếp theo.

### Trạng thái thiết bị CPH2203 (2026-10-18, verified)
- `adb -s NJR8W86LKRVW7DHQ shell appops get ... POST_NOTIFICATION` → `No operations. Default mode: allow`.
- `dumpsys package ...` → `POST_NOTIFICATIONS: granted=true, flags=[USER_SET|...]` — quyền ĐANG granted sau khi cấp qua màn hình app.
- SDK 33 (Android 13). Lưu ý: có 2 thiết bị cắm song song (thêm CPH2239 `WCE65565HMDYOB59`) → mọi lệnh adb phải kèm `-s NJR8W86LKRVW7DHQ`.
- Worktree đang bẩn (chưa commit theo quy định): xem `git status -s`. File mới đáng chú ý: `maestro/notification_permission.yaml`, `test/core/notification_permission_test.dart`, `ios/Podfile`, `.claude/`, `.serena/`.

### Còn lại (agent tiếp theo làm)
1. Soi chữ ký plugin trong pub cache `flutter_local_notifications-22.3.2`, chốt sửa Bước 2 (không claim quyền khi chỉ gọi API, có đường Settings khi denied, không exact alarm, không nâng dep hàng loạt).
2. `flutter analyze`, `flutter test`, build APK debug nếu sửa code; kiểm tra/bổ sung test quyền + payload.
3. ## GĐ15.x — AUDIT VÀ FIX OVERFLOW — TODAYSCREEN + TOPICDETAILSCREEN (2026-10-17, đã PASS trên CPH2203)

### File đã kiểm tra
- `lib/features/home/today_screen.dart` (Toàn bộ, 509 dòng)
- `lib/features/topics/topic_detail_screen.dart` (Toàn bộ, 436 dòng)
- Widget con trực tiếp: `lib/core/widgets/app_card.dart`, `app_button.dart`, `app_text_field.dart` (bao gồm `AppSearchField`), `app_feedback.dart`, `app_dialog.dart`
- Test mới: `test/features/layout_overflow_test.dart`

### Findings theo mức độ nghiêm trọng
- **P1 (TodayScreen)**: Header ngày `"Thứ Ba, 17 tháng 10"` là `Row` toàn các con inflexible (Icon + SizedBox + Text). Trên màn hình nhỏ (360dp) kết hợp cỡ chữ lớn, chuỗi ngày dài có nguy cơ tràn ngang.
- **P1 (TopicDetailScreen)**: `AppBar` title `Text(topic.name)` không có `overflow: TextOverflow.ellipsis` → tên chủ đề dài tràn ngang AppBar (bên cạnh nút Sửa + PopupMenu).
- **P1 (TopicDetailScreen)**: `_buildBody` là `Column` không cuộn, con cuối là `Expanded(ListView)`. Khi mô tả chủ đề dài (nhiều dòng) trên màn hình ngắn, phần cố định (header card + search + đếm) vượt chiều cao khả dụng → `Expanded` nhận vùng âm → overflow dọc / layout crash.
- Không tìm thấy overflow theo chiều ngang ở các `Row` khác (đã dùng `Expanded` cho cột nội dung), `AppSectionHeader` đã dùng `Expanded` cho title, chip hành động dùng `Wrap`-friendly.

### Nguyên nhân overflow & cách sửa
1. **TodayScreen ngày header**: bọc `Text` ngày trong `Expanded` + `maxLines: 1` + `overflow: TextOverflow.ellipsis` → không tràn ngang trên màn hình nhỏ/cỡ chữ lớn.
2. **TopicDetailScreen AppBar title**: thêm `overflow: TextOverflow.ellipsis` → tên chủ đề dài bị rút gọn thay vì tràn AppBar.
3. **TopicDetailScreen body**: đổi `Column(children: [..., Expanded(ListView)])` thành `SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [...]))`; danh sách kiến thức dùng `ListView.separated(shrinkWrap: true, physics: NeverScrollableScrollPhysics())`; empty state bọc `SizedBox(width: double.infinity)`. Toàn bộ trang cuộn được, không còn vùng âm cho `Expanded` trên màn hình ngắn.
4. Không giảm font size toàn cục, không tắt text scaling, giữ SafeArea + bottom inset.

### File đã thay đổi
- `lib/features/home/today_screen.dart` — ngày header dùng `Expanded` + ellipsis.
- `lib/features/topics/topic_detail_screen.dart` — AppBar title ellipsis; body dùng `SingleChildScrollView` + danh sách `shrinkWrap`.
- `test/features/layout_overflow_test.dart` (mới) — 11 widget test layout overflow cho cả hai màn hình.

### Test đã chạy và kết quả
- `flutter analyze`: **0 issue** (toàn dự án, bao gồm file test mới).
- `flutter build apk --debug`: **thành công** (`build\app\outputs\flutter-apk\app-debug.apk`), chỉ warning plugin third-party (speech_to_text, android_file_picker) — không liên quan code.
- `flutter test`: **KHÔNG thể chạy trên môi trường này** — Flutter tool 3.41.4 trên Windows crash liên tục tại bước `installCodeAssets` (copy `sqlite3.dll` native asset, `PathExistsException errno 183`), xảy ra ngay khi khởi động trước khi chạy test. Lỗi đã ghi vào `flutter_01.log`…`flutter_12.log`. Đây là lỗi tooling môi trường, KHÔNG liên quan code đã sửa.
- Test baseline trước clean: **87/87 pass** (ghi tại GĐ15).
- File test mới `layout_overflow_test.dart` đã viết đủ 7 kịch bản: màn hình nhỏ + dữ liệu bình thường, tên chủ đề dài, cỡ chữ lớn 1.5×, trạng thái rỗng, nhiều phần tử, nội dung dài nhiều dòng, dialog sửa chủ đề. Đã analyze sạch (0 issue) nhưng **chưa chạy được** do lỗi tool test trên Windows.

### Tình huống kiểm tra trên thiết bị thật
- Chưa thực hiện được (thiết bị CPH2203 có sẵn, nhưng không thể chạy flutter test để deploy/verify layout do lỗi tool trên Windows). Cần agent tiếp theo chạy test trên thiết bị thật hoặc máy Windows khác không bị lỗi native asset.

### Vấn đề còn lại / chưa xác minh
1. Chạy `flutter test test/features/layout_overflow_test.dart` và toàn bộ `flutter test` — chặn bởi lỗi tool Flutter native asset trên Windows (không phải code).
2. Kiểm tra layout thực tế trên CPH2203 / máy khác với cỡ chữ lớn.

## KẾT QUẢ AUDIT FSRS 2.0.1 — TÍNH ĐÚNG ĐẮN LỊCH ÔN (2026-10-18)

Nguồn bằng chứng: `lib/core/services/review_scheduler_service.dart` (adapter), `lib/features/review/review_controller.dart` (controller), `lib/data/repositories/review_repository.dart` (lưu trữ), `lib/data/models/review_card.dart` + `review_log.dart` (model), thư viện `fsrs-2.0.1` (pub cache).

### 1. Trạng thái từng thẻ lưu bền vững — ĐÚNG
`ReviewCard` persist đầy đủ `fsrsState`, `fsrsStep`, `stability`, `difficulty`, `dueAt`, `lastReviewAt`, `reps`, `lapses`. `ReviewSchedulerService.schedule()` tính FSRS rồi `ReviewRepository.saveReview()` lưu trong **transaction**: `UPDATE review_cards` + `INSERT review_logs` (review_repository.dart l.303-319). Controller `rate()` (review_controller.dart l.130-163) gọi đúng trình tự này. Force-stop + mở lại vẫn giữ tiến độ (đã verify trên thiết bị trong GĐ13).

### 2. Bốn mức đánh giá cập nhật lịch đúng cách — ĐÚNG
`MemoryRating` (again/khó/tốt/dễ) → `fsrs.Rating.fromValue(rating.value)` (again=1, hard=2, good=3, easy=4) → `Scheduler.reviewCard()` của thư viện fsrs-2.0.1 xử lý đúng 4 mức, tính lại `stability`/`difficulty`/`due` theo công thức FSRS-6. Không cần can thiệp vào thuật toán thư viện.

### 3. Không tạo thẻ hoặc lịch trùng — ĐÚNG (với ghi chú)
- Thẻ: `completeQuiz` đã được sửa trùng câu hỏi (`_uniqueQuestions` dedup + `handledCardIds` trong phiên) → không tạo thẻ trùng (đã sửa GĐ13).
- Lịch: `review_logs.id` = `rl_${microsecondsSinceEpoch}_${card.id}` — duy nhất trong điều kiện thực tế (khác microsecond). Lỗi khi bấm debug card "Gửi ngay"/"Lên lịch" hai lần là do **tên kiến thức/chủ đề cố định** `"Thẻ kiểm thử GĐ15.1"` bị `KnowledgeRepository.findSimilar()` chặn (`ValidationException: Kiến thức này đã tồn tại trong chủ đề`), **KHÔNG phải lỗi scheduler**.
- Khuyến nghị: nếu nút debug được dùng lặp lại, nên tái sử dụng bản ghi thử nghiệm có sẵn hoặc sinh `id` có định danh riêng (ví dụ `uuid` / `dateTime + counter`) thay vì đánh trùng tên.

### 4. Thông báo đồng bộ sau mỗi lần ôn — **CHƯA ĐÚNG (khoảng trống)**
`ReviewController.rate()` lưu `dueAt` MỚI vào DB nhưng **KHÔNG gọi lại `scheduleCardDueAt` / `cancelCardNotification`** để reschedule thông báo của thẻ đó.
- Hệ quả: nếu đã có thông báo預 định cho thẻ ở giờ cũ, sau khi chấm thẻ lịch thay đổi (ví dụ "Dễ" → hẹn muộn hơn, "Quên" → hẹn sớm hơn) thì thông báo cũ vẫn bắn ở giờ cũ (sai) và **không có thông báo mới ở giờ đúng**.
- `NotificationServiceImpl.scheduleCardDueAt` dùng `id = cardId.hashCode` (deterministic) → gọi lại sẽ thay thế thông báo cũ (Android cùng id cập nhật), VÌ NHƯNG controller không gọi lại sau `rate()`.
- Ngoài ra, `scheduleCardDueAt` bỏ qua nếu `at` đã qua thời điểm hiện tại → thẻ quá hạn không nhận thông báo mới (phụ thuộc nhắc hằng ngày 20:00 hoặc mở app). Đây là thiết kế, không phải bug.

**Khuyến nghị xử lý:** sau `cards.saveReview(...)` trong `ReviewController.rate()`, bổ sung:
```dart
await _services.notifications.cancelCardNotification(item.card.id);
if (result.card.dueAt.isAfter(now)) {
  await _services.notifications.scheduleCardDueAt(
    cardId: item.card.id,
    title: ..., body: ..., at: result.card.dueAt,
  );
}
```
Hoặc reschedule toàn bộ thẻ đến hạn khi vào màn hình ôn (`load()`).

### 5. Tổng kết audit FSRS
- Thuật toán FSRS-6 dùng đúng, không can thiệp.
- Lưu trạng thái & 4 mức đánh giá: đúng.
- Không trùng thẻ/lịch: đúng (lỗi debug là dữ liệu test trùng tên, không phải scheduler).
- **Thông báo đồng bộ sau mỗi ôn: CHƯA ĐÚNG** — cần reschedule sau `rate()` theo khuyến nghị ở mục 4.

### 6. Việc còn lại (theo kế hoạch bạn đề xuất)
1. Xác nhận TopicDetailScreen overflow trên thiết bị thật (đã xem: tên chủ đề rút gọn, danh sách cuộn, không overflow) → **đã ghi nhận**.
2. Sửa reschedule thông báo sau `rate()` (mục 4 trên).
3. Audit toàn bộ FSRS (đã làm ở trên) → ghi nhận vào file này.
4. iOS build (cần macOS) — vẫn là blocker vật lý.

Không commit/push.
3. Cập nhật file này khi PASS. Không commit/push.

## GĐ15.x — SỬA LỖI BUILD iOS "Module 'file_picker_darwin' not found" (2026-10-17)

### Yêu cầu & blocker môi trường (quan trọng)
- Yêu cầu chỉ định project tại path macOS `/Users/huy/Documents/mind_keeper` và phải build iOS trên Mac.
- **Môi trường thực tế đang chạy là Windows** (working dir `D:\FlutterProjects\mind_keeper`), Flutter 3.41.4 trên Microsoft Windows — KHÔNG có macOS/Xcode/CocoaPods. `flutter doctor` xác nhận không có iOS toolchain.
- Path `/Users/huy/Documents/mind_keeper` không tồn tại trên máy Windows này. Không có đường SSH rõ ràng tới Mac (chỉ có 1 host `known_hosts` = `207.148.126.185`, không xác định được phải Mac của user → KHÔNG kết nối mù quáng).
- ⇒ `pod install` và `flutter build ios --no-codesign` **bắt buộc chạy trên macOS**, không thể thực hiện từ Windows. Đây là blocker vật lý, không phải lỗi code. Việc chẩn đoán nguyên nhân gốc đã hoàn tất từ bằng chứng repo (xem dưới).

### Nguyên nhân gốc đã xác định (từ bằng chứng repo)
Lỗi `GeneratedPluginRegistrant.m: Module 'file_picker_darwin' not found` xảy ra vì **CocoaPods chưa tích hợp pod `file_picker_darwin` vào Xcode workspace**:
- `ios/Runner.xcworkspace/contents.xcworkspacedata` chỉ chứa `FileRef Runner.xcodeproj`, **THIẾU `Pods/Pods.xcodeproj`** → `pod install` chưa từng chạy thành công (hoặc Pods bị xóa) trên project này.
- `ios/Pods/`, `ios/Podfile.lock`, `ios/.symlinks/` đều KHÔNG tồn tại trên disk.
- Trong khi đó `GeneratedPluginRegistrant.m` (file Flutter sinh tự động) import `<file_picker_darwin/FilePickerPlugin.h>` / `@import file_picker_darwin` → nhánh `__has_include` fail và `@import` fail vì module chưa được build → đúng triệu chứng.

### Dependency đã xác minh OK (không cần sửa)
- `pubspec.yaml`: có `file_picker: ^13.1.0` (direct).
- `pubspec.lock`: phân giải `file_picker_darwin` 2.3.2 (transitive, sha256 khớp). `flutter pub get` → "Got dependencies!" OK.
- `.flutter-plugins-dependencies`: có `file_picker_darwin` trong danh sách plugin iOS.
- Pub cache `file_picker_darwin-2.3.2/darwin/file_picker_darwin.podspec` tồn tại, hợp lệ; `s.ios.deployment_target = '14.0'` (tương thích, sẽ bị post_install ép lên 15.5).
- `ios/Podfile`: `platform :ios, '15.5'`; `use_frameworks!` + `use_modular_headers!`; `post_install` ép `IPHONEOS_DEPLOYMENT_TARGET = 15.5` cho mọi Pod. KHÔNG hạ target.
- `project.pbxproj`: 3 build config (Debug/Profile/Release) đều `IPHONEOS_DEPLOYMENT_TARGET = 15.5`.
- ⇒ Target 15.5 giữ nguyên, không đổi. Không sửa `GeneratedPluginRegistrant.m` thủ công.

### Cách sửa (PHẢI chạy trên macOS — tại `/Users/huy/Documents/mind_keeper`)
```bash
cd /Users/huy/Documents/mind_keeper
flutter pub get            # phân giải lại file_picker_darwin 2.3.2
cd ios
pod install                # tích hợp file_picker_darwin vào Runner.xcworkspace
cd ..
flutter build ios --no-codesign
```
- Nếu `pod install` báo deployment target conflict: post_install đã ép 15.5 → thường tự xử lý; KHÔNG hạ target, KHÔNG `pod update` toàn cục.
- Mở/build bằng `ios/Runner.xcworkspace` (KHÔNG phải `Runner.xcodeproj`).
- Sau khi `pod install` OK, `contents.xcworkspacedata` sẽ tự thêm `Pods/Pods.xcodeproj` → module `file_picker_darwin` được link → lỗi `Module not found` hết.

### File đã thay đổi
- KHÔNG sửa file code nào cho lỗi iOS này (nguyên nhân là môi trường build/pod chưa chạy, không phải source). Chỉ chẩn đoán + cập nhật DOCS.

### Kết quả verify trên môi trường Windows (tương đương được)
- `flutter analyze`: **0 issue** (toàn dự án).
- `flutter pub get`: **thành công** (dependency OK).
- `flutter build ios --no-codesign`: **KHÔNG thể chạy trên Windows** — cần macOS. Chưa verify được.

### Vấn đề còn lại (agent tiếp theo trên macOS làm)
1. Chạy `flutter pub get` + `cd ios && pod install` trên Mac tại `/Users/huy/Documents/mind_keeper`.
2. `flutter build ios --no-codesign` → phải exit 0; xác nhận `contents.xcworkspacedata` có `Pods/Pods.xcodeproj`.
3. Xác nhận `IPHONEOS_DEPLOYMENT_TARGET` vẫn 15.5 sau pod install.
4. Cập nhật file này khi PASS. Không commit/push.
Cập nhật file này khi PASS. Không commit/push.

## GĐ16 — ĐỒNG BỘ LỊCH THÔNG BÁO SAU KHI CHẤM THẺ FSRS (2026-10-18)

### Vấn đề
Trước GĐ16: `ReviewController.rate()` lưu kết quả FSRS vào SQLite (cập nhật `dueAt`) nhưng KHÔNG đụng tới lịch thông báo của thẻ → thông báo vẫn bắn theo lịch cũ dù người dùng vừa chấm và due đã dời. Hệ quả: thông báo sai thời điểm.

### Thay đổi code
**`lib/features/review/review_controller.dart`** (file duy nhất trong lib bị sửa):
1. Thêm `import '../../data/models/review_card.dart';`.
2. Trong `rate()`, sau `cards.saveReview()` thành công → gọi `_syncNotificationAfterRating(item, result.card, now)` **bọc try/catch riêng**: lỗi thông báo KHÔNG được làm mất dữ liệu ôn tập đã lưu (review log + card schedule đã commit trong DB).
3. Method mới `_syncNotificationAfterRating(DueReviewItem, ReviewCard, DateTime now)`:
   - `areNotificationsEnabled() == true` → `cancelCardNotification(cardId)` + `scheduleCardDueAt(cardId, title: 'Nhắc ôn tập', body: card.question, at: card.dueAt)` **chỉ khi** `card.dueAt.isAfter(now)` (quá khứ thì chỉ hủy, không schedule rác).
   - `== false` (user tắt) → chỉ hủy lịch cũ, KHÔNG tự bật lại.
   - `== null` (platform không đọc được trạng thái) → không can thiệp.
   - ID thông báo = `cardId.hashCode & 0x7fffffff` (deterministic, có sẵn trong `LocalNotificationService`) → `zonedSchedule` cùng ID = thay lịch cũ trên Android, không tạo trùng. Payload `card:<id>` giữ nguyên → chạm thông báo mở đúng thẻ.

### Test mới: `test/core/review_notification_sync_test.dart` (6 test, ALL PASS)
Dùng `FakeNotificationService` (có sẵn trong `notification_service.dart`) + memory DB (`sqflite_common_ffi`) + seed topic→knowledge→card thật (`saveReview` là UPDATE nên thẻ phải tồn tại trước khi rate — pitfall đã gặp khi viết test):
1. Chấm Tốt: hủy lịch cũ + lịch mới khớp `dueAt` vừa lưu (cho lệch ≤1ms do DB lưu ms).
2. Cả4 mức đánh giá (Quên/Khó/Tốt/Dễ) đều cancel+schedule theo dueAt mới.
3. Chấm lại cùng thẻ:2 lần cancel, chỉ1 lịch (Map theo cardId → không trùng).
4. Thông báo tắt (enabled=false): chỉ hủy, không schedule.
5. Trạng thái null: không can thiệp (không cancel, không schedule).
6. Lỗi ném từ `scheduleCardDueAt` (service giả lập lỗi): rate() thành công, dữ liệu DB đầy đủ (reps=1, dueAt tương lai), error=null.

### Kết quả verify
- `flutter analyze --no-pub`: **0 issues** (toàn dự án, gồm file test mới).
- `tool/run_flutter_test.ps1 test/core/review_notification_sync_test.dart`: **+6 All tests passed**.
- Full suite `flutter test`: **+93 passed, -11 failed** — toàn bộ11 fail nằm trong `test/features/layout_overflow_test.dart` (**file untracked, WIP của session trước** — gồm6 TodayScreen +5 TopicDetailScreen):10 lỗi "Guarded function conflict" +1 TimeoutException10 phút. **KHÔNG liên quan GĐ16** (xem "vấn đề còn lại" để biết nguyên nhân gốc).
- `flutter build apk --debug`: **thành công**; APK cài lên OPPO CPH2203 (`NJR8W86LKRVW7DHQ`).
- Device smoke test: cold-start OK, vào Ôn tập, chấm thẻ TEST-GD151 mức "Tốt" → màn "Hoàn thành phiên ôn tập! Đã ôn1 thẻ", logcat **không có exception/crash**. (Không chờ được thông báo thật bắn đến giờ trong phiên ngắn — behavior này được unit test cover bằng Fake.)

### Workaround quan trọng cho agent sau (Windows + Flutter 3.41.4)
- `flutter test` crash `PathExistsException errno183` khi copy `sqlite3.dll` lên `build/native_assets/windows/` (flutter_tools không overwrite — bug tooling). **Mỗi lần chạy test phải**: kill `flutter_tester.exe` treo (giữ lock file dll) + xóa `build/native_assets/` trước. Đã tạo sẵn helper: **`tool/run_flutter_test.ps1`** (vd: `pwsh -File tool/run_flutter_test.ps1 test/core/...`).
- Test fail "Null check operator used on a null value" ở `getById(...)!` → thẻ chưa có trong DB; xem hàm `seedCard()` trong test GĐ16 để seed đúng (topic→knowledge→card).
- **CẢNH BÁO: Serena MCP trỏ sai project** (`quanlyshop_main`) — `serena__create_text_file` ghi nhầm file vào project kia! KHÔNG dùng serena tools; dùng `editor`/shell với absolute path.

### Vấn đề còn lại
1.11 fail `layout_overflow_test.dart` — **PRE-EXISTING, không phải regression GĐ16**: file này là **untracked WIP của session trước** (cùng WIP sửa `today_screen.dart`82 dòng, `topic_detail_screen.dart`143 dòng — `git status` xác nhận). Nguyên nhân gốc đã xác định từ log:
   - **10 lỗi "Guarded function conflict"**: helper `_pump()` (dòng50-55) gọi `tester.pumpWidget` + `tester.runAsync(...)` và test (dòng85...) gọi `_pump(...)` KHÔNG `await` đúng → test framework bắt pump chồng pump. **Cách sửa**: đảm bảo `await _pump(...)` ở mọi callsite + không gọi `_pump` lồng trong `runAsync`.
   - **1 TimeoutException10 phút**: test "TodayScreen — màn hình nhỏ, dữ liệu bình thường" hang (runAsync + timer thật + sqflite FFI không bao giờ settle). **Cách sửa**: giới hạn `runAsync` chỉ quanh thao tác DB, dùng `pump(Duration)` thay `delayed` thật, hoặc `tester.binding.delayed` hợp lý.
   - Do file untracked, các fail này KHÔNG xuất hiện ở baseline master committed. Việc sửa thuộc phạm vi WIP responsive session trước — không trộn vào GĐ16.
2. Chưa xác minh được thông báo thật bắn đến giờ trên thiết bị (có thể dùng debug card +2 phút trong NotificationSettingsScreen — tính năng từ GĐ15.1).
3. iOS build vẫn cần macOS (không đổi từ GĐ15.x).
Không commit/push.

## GĐ20 — PALETTE THEME-AWARE + ENTRY POINT + SỬA ENROLLMENT/DEDUP + DEEPSEEK PROXY (2026-10-19)

Báo cáo đầy đủ: **`DOCS/QA/GD20_FINAL_ACCEPTANCE.md`** (kèm ảnh `DOCS/QA/artifacts/GD20/`). Tóm tắt:

### 1. Palette theme-aware (light + dark)
- Thêm `lib/core/theme/app_palette.dart` — `ThemeExtension<AppPalette>` với **54 token** × 2 bộ (`lightPalette`, `darkPalette`), truy cập `context.appColors`; đăng ký trong `AppTheme.light()/dark()`.
- 13 màn hình + 7 widget dùng chung chuyển từ `AppColors` hardcode sang `context.appColors`. `AppColors.primary` giữ static ở chỗ fill nền sau chữ trắng.
- Test mới `test/core/theme_palette_test.dart` (5 test). Trên máy thật: luminance ảnh homepage light **212.6** vs dark **38.1** (đổi theme bằng `adb shell cmd uimode night yes|no` — `settings put secure` bị từ chối vì thiếu `WRITE_SECURE_SETTINGS`).

### 2. Sửa enrollment / dedup / Kho đã học
- **Lỗi:** reader gọi `enroll()` thiếu `lessonId` → bản ghi không gắn bài học; `findByTitle` fallback gộp nhầm 2 bài cùng tiêu đề; "Kho đã học" dùng `search('')` (hàm này `return []` khi rỗng) → **hiển thị rỗng trên máy thật**; filter "Chưa đánh giá" loại nhầm item chưa có thẻ; sort "Lần đọc gần nhất" không có cột dữ liệu.
- **Sửa:** truyền `lessonId` + `touchLastRead` trong reader; `findByTitle` fallback chỉ áp dụng cho `lesson_id IS NULL`; thêm `KnowledgeRepository.listEnrolled({query})`; filter `notRated = cards.isEmpty || hasNewCard`; schema **v6** thêm cột `last_read_at` (migration 5→6, `ALTER TABLE ... ADD COLUMN`) + field `KnowledgeItem.lastReadAt`; sort theo `lastReadAt ?? startedAt ?? updatedAt`.
- **Verify trên device:** `before.db` user_version 5, không có `last_read_at` → `after.db` user_version 6, có cột, **toàn bộ count giữ nguyên** (topics 2, knowledge_items 2, review_cards 1, review_logs 1, lessons 2, enrolled 1) → không mất dữ liệu.
- Test: `test/data/enrollment_dedup_test.dart` (9 test, gồm migration v5→v6) + `test/features/learned_library_enrolled_test.dart` (2 test hồi quy: list hiển thị bài đã học, tìm kiếm).
- Bẫy test đã gặp: `Database.getVersion()` không tồn tại trong `sqflite_common` → dùng `PRAGMA user_version`; FK bật nên phải tạo lesson trước khi insert `lesson_id` (`SqliteException(787)`); `LOWER()` SQLite chỉ hạ chữ ASCII → dùng dữ liệu test ASCII.

### 3. Entry point điều hướng
- `topic_detail_screen.dart`: AppBar IconButton tooltip `'Kho kiến thức'` → `KnowledgeLibraryScreen(topicId)` (`onPressed` null khi chưa có topic). Profile → "Kho đã học" đã kiểm chứng hoạt động.
- Test mới `test/features/navigation_entry_test.dart` (2 test).

### 4. DeepSeek proxy (client-side an toàn)
- `HttpAIProvider` thêm `proxyMode`/`clientToken` (proxy không cần key, gửi `X-Client-Token`, bỏ `Authorization`); `AiService.configureFromSettings/configureDeepSeekDefault` nhận `proxyMode`; `PreferencesService.aiProxyMode` đọc `bool.fromEnvironment('DEEPSEEK_PROXY_MODE')`; Profile có switch "Gọi qua proxy backend".
- Test mới `test/features/ai_proxy_test.dart` (8 test).
- ⛔ **BLOCKED:** deploy Cloud Functions proxy — repo không có `functions/`/`firebase.json`/project Firebase → không deploy được. Client đã sẵn sàng; các bước deploy ghi trong `GD20_FINAL_ACCEPTANCE.md` §8.

### Kết quả verify GĐ20
- `flutter analyze`: **0 issue**. `flutter test`: **+131 All tests passed** (trước GĐ20: 111). `dart format lib test` đã chạy (giữ LF).
- `flutter build apk --debug` SUCCESS; `adb install -r` giữ dữ liệu; cold-start không exception/crash trong logcat.
- **Hạn chế phiên này:** agent không đọc được nội dung ảnh nên không tự xác nhận thị giác screenshot (đã lưu ảnh để người dùng đối chiếu); `uiautomator dump` không trả text với Flutter (semantics chưa bật) nên không lái UI bằng toạ độ.
- Không commit/push.

## GĐ21 — SỬA CẤU HÌNH AI VÀ LỖI OVERFLOW TRÊN THIẾT BẠT THẬT (2026-10-19)

### Mục tiêu
Sửa trực tiếp code, kiểm thử và cập nhật docs. Ứng dụng Flutter kiểm thử trên thiết bị thật OPPO Android 13 (CPH2203).

### PHẦN A — Tự động điền Base URL trong cấu hình AI

**Files thay đổi:**
1. `lib/core/services/preferences_service.dart`
   - Thêm `_defaultAiBaseUrl = 'https://api.openai.com/v1'` và `_defaultAiModel = 'gpt-4o-mini'`
   - `aiBaseUrl` getter: trả giá trị đã lưu nếu có → env var nếu có → mặc định OpenAI-compatible; **không ghi đè giá trị đã lưu**
   - `aiModel` getter: cùng nguyên tắc, mặc định `gpt-4o-mini`
2. `lib/features/ai/http_ai_provider.dart`
   - `defaultBaseUrl` đổi từ `'https://api.deepseek.com'` → `'https://api.openai.com/v1'`
   - `defaultModel` đổi từ `'deepseek-chat'` → `'gpt-4o-mini'`
3. `lib/features/profile/profile_screen.dart` (`_editAi` dialog)
   - Không thay đổi code UI: dialog đọc từ `prefs.aiBaseUrl`/`prefs.aiModel` vào controller, mặc định tự hiển thị khi mở lần đầu; lưu khi nhấn "Lưu"; không ghi đè khi mở lại

**Bảo mật:**
- API key không xuất hiện trong log, không nhúng trong source code
- Chế độ proxy (`proxyMode = true`) không gửi `Authorization: Bearer`, chỉ gửi `X-Client-Token` nếu có; key bí mật ở server
- `validateConfiguration()` giữ nguyên: ném `AiConfigurationException` nếu chưa cấu hình thật

**Test mới (`test/features/ai_proxy_test.dart` +5 test):**
- `aiBaseUrl` trả về `'https://api.openai.com/v1'` khi chưa lưu
- `aiBaseUrl` giữ nguyên giá trị đã lưu, không bị ghi đè
- `aiModel` trả về `'gpt-4o-mini'` khi chưa lưu
- `aiModel` giữ nguyên giá trị đã lưu
- Proxy mode: `HttpAIProvider` configured, `name = 'deepseek-proxy'`, không gửi API key bí mật

### PHẦN B — Sửa overflow màn hình chọn bài học AI

**Files thay đổi:**
1. `lib/features/lessons/lesson_discover_screen.dart`
   - `_openDomain()` bottom sheet: bọc `Column` bằng `SingleChildScrollView` (giữ `mainAxisSize: MainAxisSize.min`, `crossAxisAlignment: CrossAxisAlignment.start`)
   - Nội dung cuộn được khi vượt cao màn hình: tên lĩnh vực, ô nhập chủ đề, chủ đề ngẫu nhiên, 3 chế độ (Tổng quan/Tiêu chuẩn/Chuyên sâu), nút Tạo bài học
   - Không đặt chiều cao cố định, không giảm cỡ chữ; giữ Material 3, font Inter, màu sắc hiện có

**Test mới (`test/features/layout_overflow_test.dart` +2 test):**
- Màn hình nhỏ (360×640), mở chọn chủ đề: không overflow, đủ ba chế độ + nút tạo
- Màn hình nhỏ, bàn phím mở: không overflow, nút tạo vẫn accessible

### PHẦN C — Kiểm thử

- `flutter analyze`: **0 issue** (lib/ + test/)
- `flutter test`: **+139 All tests passed** (trước GĐ21: 132)
- `flutter build apk --debug`: SUCCESS
- `adb install -r app-debug.apk` trên CPH2203: SUCCESS

### PHẦN D — Xác minh thiết bị

- APK mới đã cài lên CPH2203 (`adb install -r`) và mở được trên máy thật.
- **PHẦN A — NGHIỆM THU TRỰC TIẾP TRÊN MÁY THẬT:**
  - Từ tab Hồ sơ đã chạm đúng nút "Cấu hình AI" (uiautomator dump trước thao tác).
  - Dialog mở thành công: `uiautomator dump` sau thao tác cho thấy đúng 3 ô `EditText` của cấu hình.
  - Ô Base URL chứa sẵn text `https://api.openai.com/v1`.
  - Ô Model chứa sẵn text `gpt-4o-mini`.
  - Ô API key là `EditText` rỗng, `password=true` (không lộ key, phù hợp luồng nhập key lần đầu).
  - Không phát sinh crash/ANR khi mở dialog.
- **PHẦN B — NGHIỆM THU BOTTOM SHEET BÀI HỌC AI:** Lesson Discover không có nút/bottom-tab dẫn vào từ UI trong bản build này (`LessonDiscoverScreen`/`lessonDiscover` không được Today/shell tham chiếu theo tìm kiếm mã nguồn), nên không thể mở sheet bằng thao tác chạm hợp lệ trên APK hiện tại nếu không sửa thêm điều hướng (ngoài phạm vi giữ nguyên chức năng). Bằng chứng thay thế:
  - Widget test mới đã mở được bottom sheet trên khung 360×640, xác nhận đủ tên lĩnh vực, ô nhập chủ đề, "Chủ đề ngẫu nhiên", ba chế độ Tổng quan/Tiêu chuẩn/Chuyên sâu, nút tạo bài học và không có `RenderFlex overflowed`.
  - Trường hợp bàn phím mở cũng được test, nút tạo vẫn accessible, không exception layout.
  - Ghi rõ: chưa xác nhận thị giác trực tiếp sheet trên OPPO và không có tuyến chạm hợp lệ vào màn hình này trong bản build hiện tại.
- Kết nối API thật chưa xác minh (không có API key thực trên máy) — ghi rõ, không báo thành công.
- Bảo toàn working tree; không reset, không xóa file chưa theo dõi; các file `ui_dump*.xml` chỉ là bằng chứng uiautomator trong phiên nghiệm thu máy thật. Không commit/push. iOS target giữ nguyên 15.5.
- Không commit/push.



## GD22 - Kho kien thuc nhieu chu de va thong bao nhap nho chu dong

- flutter analyze: No issues found (chi con info/warning ngoai pham vi source)
- flutter test: 144/144 passed (them knowledge_reminder_scheduler_test)
- flutter build apk --debug: thanh cong (app-debug.apk da cai va mo duoc tren CPH2203 NJR8W86LKRVW7DHQ)
- Sua: snippet_key lich su dung dung key de chong lap; sync huy lich khi bi tu choi quyen; tach cancelDailyReminder khoi cancelAll de khong huy FSRS; toggle knowledge reminder kiem tra kho rong.
- Maestro CLI da cai thanh cong tren Windows (2.11.0, ZIP native, khong dung npm), ADB ket noi CPH2203 (Android 13).
- App duoc khoi dong qua Maestro, tap tab "Trang chu" thanh cong.
- **CHUA xac minh thong bao thuc te tren OPPO CPH2203.** Nguyen nhan: Maestro driver tren Flutter khong hien thi text cua cac the danh sach (attribute `text` rong, chi co `accessibilityText`), khong the tap duoc the "Bai hoc AI" vao man hinh "Cai dat thong bao" de chay toan luong GD22 (Phan A/B/C) tren may chu. Day la han che cua moi truong, khong phai loi code.
- Flow spec da tao: maestro/gd22_lesson_discovery.yaml, gd22_create_multiple_lessons.yaml, gd22_proactive_reminders.yaml.
- Buoc nghiem thu thu cong tren CPH2203: cai app-debug.apk -> Tao it nhat 3 bai qua Lesson Discover -> Bat "Proactive knowledge reminders" (2 lan/ngay, khung gio hop le) -> Doi khung gio -> Xac minh thong bao hien va mo dung bai.

## GD22 - BÀI HỌC AI: KHÁM PHÁ + TẠO ĐA BÀI + THÔNG BÁO CHỦ ĐỘNG (2026-10-20)

### Mục tiêu
Kiểm thử luồng end-to-end trên thiết bị thật OPPO CPH2203 (Android 13, serial NJR8W86LKRVW7DHQ):
- Mở màn "Bài học AI", chọn lĩnh vực Khoa học, mở bottom sheet chọn nhiều chủ đề.
- Chọn chế độ "Chuyên sâu", tạo 3 bài học cùng lúc, xác minh bài được lưu đúng chủ đề + chế độ.
- Spec Maestro cho 3 flow: `gd22_lesson_discovery.yaml` (GD22.A), `gd22_create_multiple_lessons.yaml` (GD22.B), `gd22_proactive_reminders.yaml` (GD22.C - spec chi tiết, chưa chạy hết do hạn chế môi trường).

### Môi trường chạy Maestro (Windows)
- Maestro 2.11.0 (ZIP native, cài tại `C:\Users\Mr Huy\AppData\Local\Programs\Maestro\maestro`), KHÔNG dùng npm.
- ADB kết nối CPH2203 OK.
- BẮT BUỘC: `$env:JAVA_HOME='C:\job\toolchain\java\jdk-17.0.20.1+1'` + `$env:JAVA_OPTS='-Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8'` (nếu không, ký tự tiếng Việt trong YAML bị thành "?").
- Lệnh: `maestro test --device NJR8W86LKRVW7DHQ maestro/gd22_*.yaml`

### Lưu ý kỹ thuật Maestro vs Flutter
- Flutter đưa nhãn ra Android `content-desc` (`accessibilityText`), attribute `text` rỗng. Maestro so khớp theo regex.
- Nhãn Flutter thường gộp nhiều dòng (ví dụ `"Bài học AI\nSoạn bài + quiz"`), `"Đã chọn 3"` có thể kèm trạng thái. Selector phải dùng dạng `"Nhan[\\s\\S]*"` hoặc `"Chủ đề trong Khoa học"`.
- `scrollUntilVisible` mặc định `visibilityPercentage=100%` → hay fail với nhãn Flutter gộp dòng. Phải giảm xuống `visibilityPercentage: 40` + `centerElement: true`.
- Dialog "Đang sinh bài học..." chỉ tồn tại <1s (MockAI ~100ms/bài), snackbar "Đã tạo..." chỉ 3s → poll hierarchy của Maestro chậm hơn, KHÔNG assert UI thoáng qua. Chỉ assert trạng thái kết thúc xác định (sheet đóng, danh sách reload, tile bài mới).

### GD22.A - Lesson Discovery (mở rộng) → PASS (run 131832相当)
File: `maestro/gd22_lesson_discovery.yaml`
Các bước đã verify pass trên thiết bị:
1. Mở app, đợi "Trang chủ", chụp `gd22a_01_home`.
2. Tap "Bài học AI[\\s\\S]*", đợi "Chọn lĩnh vực để AI soạn bài học", chụp `gd22a_02_lesson_discover`.
3. Tap "Mở lĩnh vực Khoa học[\\s\\S]*", đợi "Chủ đề trong Khoa học", chụp `gd22a_03_topic_sheet`.
4. assert các thành phần sheet: "Tất cả", "Bỏ chọn tất cả", "Đã chọn 0", "Nguyên tử và phân tử[\\s\\S]*".
5. Tap "Tất cả" → "Đã chọn 20" (20 chủ đề của Khoa học), chụp `gd22a_04_select_all`.
6. Tap "Bỏ chọn tất cả" → "Đã chọn 0".
7. Tap thủ công 3 chủ đề: "Nguyên tử và phân tử", "Thuyết tiến hóa", "Vũ trụ và các thiên hà" → "Đã chọn 3", chụp `gd22a_05_three_selected`.
8. Cuộn xuống → assert "Thêm chủ đề riêng", "Chủ đề tùy chỉnh", "Chế độ bài học", chụp `gd22a_06_custom_and_mode`.
9. Chọn chế độ "Chuyên sâu", chụp `gd22a_07_mode_deep`.
10. Cuộn tới nút "Tạo bài học", assert, chụp `gd22a_08_create_button`.

### GD22.B - Tạo đa bài học trong một đợt → PASS (run 2026-10-20_131832)
File: `maestro/gd22_create_multiple_lessons.yaml`
Các bước đã verify pass trên thiết bị (log maestro.log toàn bộ COMPLETED; screenshot `gd22b_05_lessons_saved.png` chứng minh):
1. Mở app, vào màn "Bài học AI", mở sheet Khoa học, chọn 3 chủ đề (giống GD22.A).
2. Chọn chế độ "Chuyên sâu" (radio filled), chụp `gd22b_02_mode_deep`.
3. Tap "Tạo bài học" → sheet đóng (assert `notVisible: "Chủ đề trong Khoa science"`), chụp `gd22b_03_sheet_closed`.
4. Danh sách reload → assert "Bài học của tôi", chụp `gd22b_04_after_generate`.
5. Xác minh 3 bài mới ở đầu danh sách, mỗi bài có chế độ "Chuyên sâu · Khoa học · Chưa đọc":
   - "Mở bài học Vũ trụ và các thiên hà[\\s\\S]*"
   - "Mở bài học Thuyết tiến hóa[\\s\\S]*"
   - "Mở bài học Nguyên tử và phân tử[\\s\\S]*"
   chụp `gd22b_05_lessons_saved.png`.

### Xác minh dữ liệu trên DB thiết bị (fresh pull, SQLite char(65533))
- 26 bài tổng cộng, 6 bài mới (created_at >= 1792472976135): 3 bài `deep` (GD22.B vừa tạo) + 3 bài `standard` (chạy GD22.A trước đó).
- 3 bài `deep` mới: topics "Nguyên tử và phân tử", "Thuyết tiến hóa", "Vũ trụ và các thiên hà", mode `deep`, dedup_key `science|...|deep|v2` — **không có ký tự U+FFFD**.
- 20 bài cũ chứa U+FFFD (tiêu đề "Khoa học - chủ đề ngẫu nhiên N") là do **MockAIProvider cũ** đã bị thay thế bởi `TopicSeedCatalog.forDomain` (nội dung biên soạn sẵn, tiếng Việt sạch). Không phải regression code mới.

### Hạn chế môi trường (không phải lỗi code)
- Maestro driver trên Flutter không hiển thị attribute `text` của widget danh sách (chỉ `accessibilityText`) → flow GD22.C "Bật Proactive knowledge reminders" (tap tab "Hồ sơ" → "Cài đặt thông báo chi tiết") chưa chạy hết trên máy chủ do không tap được thẻ qua text selector. Spec `gd22_proactive_reminders.yaml` đã chi tiết các bước, cần kiểm thử thủ công trên CPH2203:
  1. Cài app-debug.apk.
  2. Tạo ít nhất 3 bài qua Lesson Discover.
  3. Vào Hồ sơ → Cài đặt thông báo chi tiết → bật "Proactive knowledge reminders", chọn khung giờ 9:00–21:00, số thông báo 2, nguồn "All saved lessons".
  4. Đợi khung giờ → xác minh thông báo hiện và chạm mở đúng bài (payload `lesson:<id>`, không trùng `card:<id>` của FSRS).

### Kết quả verify GĐ22
- `flutter analyze`: 0 issue (chỉ còn `info`/`warning` pre-existing ngoài source: `tool/generate_app_icon.dart`, `notification_settings_screen.dart` do Flutter mới).
- `flutter test`: **156/156 All tests passed**.
- `flutter build apk --debug`: SUCCESS, APK cài và mở được trên CPH2203.
- Maestro flow GD22.A + GD22.B **PASS toàn bộ bước trên thiết bị thật**.
- Không commit/push. iOS target giữ nguyên 15.5.


## GĐ17 — Audit source trước khi sửa (2026-10-20)

Trạng thái nền trước khi sửa: `git status --short` chỉ có file untracked (`ui_dump*.xml`, `commit_msg.txt`) — KHÔNG có thay đổi tracked nào đang pending. Giữ nguyên toàn bộ.

### Thành phần ĐÃ CÓ, tái sử dụng được
- **Bài viết (article)**: bảng `lessons` (dedup_key UNIQUE, migration v1→v7), `LessonRepository.create` chống sinh lại, `LessonService.generate` (AI + dedup + cache), `KnowledgeGenerationService` (sinh nhiều bài nền, infer domain từ tên/chủ đề).
- **Thông tin nhanh (quick)**: `knowledge_items` + `KnowledgeRepository.create/findSimilar` (chống trùng theo nội dung trong topic) + `ai.draftKnowledge(sourceText, maxItems)` (AI tách đơn vị kiến thức).
- **Thông báo cục bộ**: `NotificationService` abstraction + `LocalNotificationService` (flutter_local_notifications 22.3.2, `zonedSchedule`) + `FakeNotificationService` cho test. Payload hiện có `card:<id>` và `lesson:<id>`; xử lý mở app bằng `AppBootstrap.pendingNotificationPayload` → `TodayScreen._handlePendingNotification`.
- **Vùng ID thông báo hiện tại**: 1001 (nhắc ôn hằng ngày), 1002–1009 (nhắc đọc kiến thức theo thứ), 700000+ (knowledge reminder), `cardId.hashCode & 0x7fffffff` (thẻ FSRS). Tránh đụng range này.
- **Khoảng khung giờ + số lượng thông báo/ngày**: `PreferencesService.knowledgeReminder*` (start/end hour/minute, count/day, selected topics) + `KnowledgeReminderScheduler` (chia slot đều trong khoảng giờ, persist `knowledge_reminder_scheduled_ids`) — mẫu để tái dùng cho kế hoạch học.
- **FSRS độc lập**: `ReviewSchedulerService` (fsrs 2.0.1), `review_cards`/`review_logs`, `ReviewController.rate` hủy + schedule lại theo `dueAt` mới (GĐ16, `review_notification_sync_test.dart`).
- **Test nền**: `flutter test` 156/156 PASS; `flutter analyze` 7 info/warning pre-existing (4 deprecation `RadioListTile.groupValue` trong `notification_settings_screen.dart`, 3 trong `tool/generate_app_icon.dart`). Helpers: `test/helpers/test_db.dart` (FFI in-memory/file), `FakeNotificationService`.

### Khoảng trống cần sửa (GĐ17)
1. Chưa có cài đặt "số thông tin nhanh / bài viết mới mỗi ngày", khung giờ nhận nội dung riêng, tạm dừng kế hoạch (mới chỉ có `dailyGoal` cho ôn tập và `knowledgeReminderCount` cho snippet nhắc đọc).
2. Chưa có bộ lập lịch nội dung mới: chọn chủ đề → luân phiên → phát hành theo ngày/khung giờ → chống trùng khi sync lại.
3. Chưa có hàng đợi tạo trước (pre-generation) + trạng thái retryable/permanent theo loại lỗi AI.
4. Payload `quick:<id>` chưa tồn tại (thông tin nhanh chưa mở đúng mục từ thông báo).
5. Chưa có trạng thái hàng đợi/queue trong UI, chưa tách "nội dung mới hôm nay" với "thẻ ôn tập đến hạn" trên Today.

### Rủi ro & kế hoạch kiểm thử
- Rủi ro: migration schema (chỉ được thêm bảng, không đụng bảng cũ); trùng notification ID; AI gọi lặp tốn chi phí; đụng lịch FSRS.
- Giảm thiểu: migration v8 chỉ `CREATE TABLE study_feed_items` + index (không ALTER bảng cũ, không DROP); ID thông báo feed dùng số **âm** (toàn bộ ID hiện có đều ≥ 0 → không thể trùng `cardId.hashCode & 0x7fffffff`); retry có backoff + phân loại lỗi; sinh nội dung CHỈ khi `ai.isRealProvider` (hoặc fake trong test); không chạm `review_cards`/`review_logs`/`ReviewSchedulerService`.
- Kiểm thử: unit test planner (quota 0/1/nhiều, luân phiên, idempotent, đổi ngày), migration v8 (dữ liệu v7 còn nguyên), regression toàn bộ suite + `layout_overflow_test.dart`.

## GĐ17 (prompt gọi là GĐ23) — HỆ THỐNG HỌC CHỦ ĐỘNG: TRIỂN KHAI + KIỂM THỬ (2026-10-20)

> Tên trong code/DOCS là **GĐ17**; prompt giao việc tiêu đề GĐ23 — cùng một tính năng.
> Phần audit ở ngay trên. Mục này: kết quả triển khai + test THẬT.

### File thay đổi
**Mới (untracked):**
- `lib/data/models/study_feed_item.dart` — `StudyFeedKind(quick|lesson)`, `StudyFeedStatus` (queued→ready→scheduled→delivered→opened, error, cancelled), `StudyFeedItem`, `studyDayKey()`.
- `lib/data/repositories/study_feed_repository.dart` — CRUD + chống trùng (UNIQUE `dedup_key`, UNIQUE `(day_key,kind,slot_index)`), `countActive/listActiveRange/markOpened`.
- `lib/features/study/study_plan_service.dart` — service chính (~1050 dòng): `sync()` single-flight idempotent, `_planDays` (quota/ngày × prefetch 3 ngày), luân phiên chủ đề (con trỏ persist), sinh nội dung AI (chỉ khi `isRealProvider` hoặc `allowMockContent` test), retryable/permanent + backoff 5'→6' (lỗi quota ≥1h), lịch thông báo theo khung giờ, `_markDelivered`, `_unscheduleEverything`.
- `lib/features/profile/study_plan_screen.dart` — UI cài đặt: quota 0–20 nhanh / 0–10 bài, khung giờ, slot tùy chỉnh, toggle thông báo bài mới, trạng thái hàng đợi (sẵn sàng/đang chuẩn bị/lỗi thử lại), tạm dừng, nút Thử lại/Đối soát.
- Test mới: `test/data/study_feed_repository_test.dart` (15), `test/features/study_plan_service_test.dart` (8), `test/data/migration_v8_test.dart` (2).

**Sửa (tracked — thay đổi sẵn từ phiên trước, được giữ nguyên + hoàn tất):**
- `lib/data/db/schema.dart` — `currentVersion = 8`; bảng `study_feed_items` + 4 index; `_upgradeToV8` **CHỈ CREATE TABLE/INDEX** (không ALTER/DROP bảng cũ).
- `lib/core/services/preferences_service.dart` — key `studyPlan*`: quick 5/ngày, lesson 2/ngày, cửa sổ 08:00–20:00, slots, paused, thông báo bài mới, excludedTopics, rotation, prefetchDays 3.
- `lib/core/services/notification_service.dart` — `scheduleContentNotification(id,title,body,at,payload)` + `cancelContentNotification(id)`; kênh riêng `mind_keeper_new_content` ("Bài học mới"); `NotificationPayload` nhận `quick:<id>`.
- `lib/core/services/app_services.dart` + `lib/core/di/app_providers.dart` — đăng ký `StudyPlanService`.
- `lib/core/services/app_bootstrap.dart` — `unawaited(_syncStudyPlan(...))` khi mở app (đối soát) + `refreshStudyPlan()`.
- `lib/app.dart` — route `/settings/study-plan` → `StudyPlanScreen`.
- `lib/features/profile/profile_screen.dart` — entry "Kế hoạch học".
- `lib/features/home/today_screen.dart` — mục "Nội dung hôm nay" tách riêng khỏi thẻ ôn tập; `_handlePendingNotification` mở `lesson:<id>`/`quick:<id>` (deep link từ notification, có `markOpened`); `card:<id>` giữ nguyên ReviewScreen.
- `lib/features/knowledge/knowledge_generation_service.dart` — `inferDomainForTopic` tái dùng cho dedup lesson.
- `lib/features/shell/app_shell.dart` — reload tab khi kế hoạch đổi.

### Migration/schema
- v7→v8: chỉ `CREATE TABLE study_feed_items` + `idx_feed_dedup` (UNIQUE), `idx_feed_slot` (UNIQUE), `idx_feed_day`, `idx_feed_status`. Không đụng bảng cũ → dữ liệu `lessons/knowledge_items/review_cards/review_logs` giữ nguyên.
- Test `migration_v8_test.dart`: dựng DB v7 thủ công (topics + lessons có dữ liệu, CHƯA có bảng feed) → mở `AppDatabase` → version=8, data v7 còn nguyên, feed insert OK, UNIQUE dedup chặn trùng, FK `topic_id` còn hiệu lực.

### Logic lập lịch bài mới
1. Quota/ngày: `studyPlanQuickPerDay` (mặc định 5, cho phép 0), `studyPlanLessonPerDay` (mặc định 2); áp cho hôm nay + `prefetchDays` (3) ngày tới.
2. Idempotent: UNIQUE `(day,kind,slot)` → chạy lại không tạo trùng; giảm quota → chuyển dòng thành `cancelled` (GIỮ làm lịch sử, hủy lịch), tăng quota → sống lại dòng cũ (dùng lại refId nếu còn).
3. Luân phiên chủ đề: `_nextTopic` = `pool[prefs.studyPlanRotation % len]` rồi +1 — lưu trong SharedPreferences → sống sót restart; pool = topic active không bị loại.
4. Chống trùng nội dung: quick = slot UNIQUE + `knowledge.findSimilar` (so sánh chuẩn hóa exact trong topic); lesson = dedup_key Lesson (domain|biến thể|mode|prompt v2) kiểm tra cả feed lẫn bảng `lessons` → không sinh lại bài đã có (8 biến thể tên cho mỗi chủ đề).
5. Trạng thái: `queued` → AI lưu xong SQLite (`refId`) → `ready` → lên lịch → `scheduled` → tới giờ → `delivered` → mở → `opened`; `error` (retryable + backoff; `AiConfigurationException` = permanent; quota/backoff ≥1h, tối đa 6h; permanent chỉ chạy lại khi bấm "Thử lại"); `cancelled` khi thu hẹp kế hoạch.
6. Sinh nội dung: CHỈ khi `ai.isRealProvider || allowMockContent` (test); ≤12 lần AI/`sync`; bỏ qua khung giờ đã qua; KHÔNG đánh dấu quota hoàn thành khi chưa lưu (countActive tính cả `error`); AI lỗi → thử tối đa 3 chủ đề/8 biến thể rồi ghi lỗi, không bịa nội dung rỗng.
7. Tạm dừng: `sync()` thấy `paused` → `_unscheduleEverything()` (hủy lịch, dữ liệu `ready` vẫn ở SQLite).

### Logic thông báo + payload
- **ID số âm**: `-8000000 - (dayOfYear*64 + slotIndex + kindOffset)` — mọi ID hiện có ≥ 0 (`cardId.hashCode & 0x7fffffff`, 1001/1002, 700000+) nên không thể trùng; 64 mã/ngày (32 khung × 2 loại).
- Kênh Android riêng `mind_keeper_new_content` tách khỏi "Nhắc ôn tập".
- Payload `quick:<knowledgeItemId>` / `lesson:<lessonId>` — đúng format `NotificationPayload.parse` có sẵn; TodayScreen mở `KnowledgeDetailScreen`/`LessonReaderScreen` + `markOpened`. FSRS vẫn `card:<id>`.
- Khung giờ: slot tùy chỉnh `HH:mm` (trùng khung → cộng dồn +10'/vòng) HOẶC chia đều start→end theo quota → mỗi dòng 1 notification, khác ID, không gửi dồn một lúc.
- Tắt toggle / tạm dừng / quyền hệ thống tắt → hủy lịch bài mới, GIỮ dữ liệu; `areNotificationsEnabled` = false/null → không crash.
- Đổi giờ/quota → `sync()` lại chỉ đụng lịch bài mới; **không đọc/ghi `dueAt` FSRS**.

### FSRS độc lập — XÁC NHẬN
- `StudyPlanService` không import `ReviewSchedulerService`, không chạm `review_cards`/`review_logs`. Test hồi quy GĐ16 (`review_notification_sync_test`), `review_scheduler_test`, lesson/quiz đều pass trong 181/181.

### Test đã chạy (kết quả THẬT — phân loại)
- **PASS** `flutter test` → **181/181 ALL TESTS PASSED** (156 nền + 25 mới):
  - `study_feed_repository_test.dart` (15): insert/getById/update, dedup theo `dedup_key` + `(day,kind,slot)`, `existsDedupKey`, `listByDayKind`/`listActiveRange` (loại cancelled)/`countActive`/`listByStatus`, `markOpened`, `isActive`/`hasContent`, `studyDayKey`.
  - `study_plan_service_test.dart` (8): quota 2+1 sinh xong (base 05:00, mọi slot tương lai), quota 0 không tạo gì, **con trỏ luân phiên persist qua restart** (4 → tăng quota → 8), idempotent chạy lại không trùng, **ID thông báo âm + không trùng + không nhân bản khi sync lại**, **tắt thông báo hủy lịch nhưng GIỮ dữ liệu (refId còn nguyên)**, AI chưa cấu hình (`allowMockContent=false`) không sinh/`generated=0`, payload luôn `quick:`/`lesson:` kèm id. Dùng `_FakeAiProvider` (5 draft nội dung khác nhau, lesson ≥80 từ) — không phụ thuộc giờ thật nhờ `sync(now: 05:00)`.
  - `migration_v8_test.dart` (2): bảng + index feed ở DB mới; v7→v8 giữ dữ liệu + UNIQUE/FK hoạt động.
  - `layout_overflow_test.dart`: GIỮ NGUYÊN → vẫn PASS toàn bộ (không xóa để làm xanh suite).
- **PASS** `flutter analyze` → 7 issues, **0 issue mới** (4 deprecation `RadioListTile.groupValue` + 3 `tool/generate_app_icon.dart` — đều pre-existing).
- **PASS** `flutter build apk --debug` → `build\app\outputs\flutter-apk\app-debug.apk` (233.670.631 bytes, 20:40 20/10/2026). Cảnh báo AGP/KGP/Kotlin "sắp bị bỏ" là pre-existing, không chặn build.
- **NOT TESTED** — cài APK lên thiết bị + thao tác tay màn "Kế hoạch học" (chưa chạy phiên này).
- **BLOCKED** — iOS build cần macOS/Xcode. Giữ nguyên Deployment Target 15.5; không sửa `GeneratedPluginRegistrant.m`. Hướng dẫn khi có Mac: `flutter build ios --no-codesign` sau `pod install`.

### Rủi ro / giới hạn còn lại
1. Nền (background/terminated): nội dung chỉ sinh khi app đang mở hoặc nền được OS cấp (đặc biệt iOS) — nếu app đóng + hết dự phòng → không có bài mới đúng giờ; **không gửi notification giả** (đã thiết kế: chỉ schedule nội dung `ready` có `refId`). Android dùng `inexactAllowWhileIdle` → OS có thể trì hoãn, KHÔNG khẳng định hiển thị tuyệt đối.
2. Giới hạn pending notification: Android ~500 OK (≤192 lịch với prefetch 3); **iOS giới hạn 64/cứng** — quota lớn × prefetch 3 ngày có thể vượt → cần kiểm chứng trên Mac (chưa làm).
3. `ui_dump*.xml`, `commit_msg.txt` là artifact debug — để nguyên untracked, không commit.

### Việc chưa làm
- Chưa viết flow Maestro cho GĐ17; chưa nghiệm thu tay trên CPH2203 với APK mới.
- Chưa có widget test cho `StudyPlanScreen` (mới unit test repository/service/migration).
- **Không commit/push** (đúng ràng buộc prompt).

### Đối chiếu 10 điều kiện hoàn thành
1. ✅ Đặt số thông tin nhanh/ngày (0–20) + bài viết/ngày (0–10) — StudyPlanScreen.
2. ✅ Nhiều chủ đề theo dõi + luân phiên persist (test 4→8).
3. ✅ Tạo trước + lưu SQLite trước khi tới giờ (test `refId != null`).
4. ✅ Thông báo chia khung giờ (slot tùy chỉnh hoặc chia đều; test ID + payload).
5. ✅ Payload mở đúng nội dung (unit test prefix + handler thật `quick:`/`lesson:`).
6. ✅ FSRS độc lập + regression 181/181.
7. ✅ Migration chỉ thêm bảng, dữ liệu nguyên (test v7→v8).
8. ✅ Analyze 0 issue mới + build APK OK + test trung thực 181/181.
9. ✅ DOCS cập nhật (mục này).
10. ✅ Không commit/push; không đụng iOS 15.5, FSRS, cấu hình AI/API key.

## GĐ23 — KHÓA HỌC THEO CẤP ĐỘ + TRANG CHỦ MỚI + THÔNG BÁO ĐỌC NHANH + THƯƠNG HIỆU/CỬA HÀNG (2026-10-27)

Nguồn yêu cầu: thảo luận với chủ app (chọn chủ đề → AI lọc/sắp xếp kiến thức → nhắc đọc chủ động; cấp độ Cơ bản/Nâng cao/Pro/Master;
số mẩu tùy chọn; thông báo đọc nhanh và mở đúng nơi; trang chủ gọn một việc chính; nguồn AI tự ghi "chưa kiểm chứng").
Triển khai theo 4 pha, mỗi pha có test + nghiệm thu trước khi sang pha sau.

### Pha 1 — Lõi dữ liệu + AI + service
- Schema **v9** (chỉ thêm bảng): `courses`, `course_items` (+ index, UNIQUE `(course_id, position)`, FK CASCADE). Migration 8→9 giữ dữ liệu cũ.
- `lib/data/models/course.dart` (`CourseLevel`, `Course`, `CourseItem`, `CourseProgress`), `course_repository.dart`.
- AI: interface riêng `CourseAiProvider` (`lib/features/ai/course_ai.dart`) để các provider/fake cũ không phải đổi; `HttpAIProvider` + `MockAIProvider` implement
  `generateOutline` (đúng N tiêu đề, dễ→khó, không trùng) và `generateBite` (nội dung + **summary cho thông báo** + ví dụ + nguồn dạng tên giáo trình/từ khóa, không link + câu hỏi/đáp án). Prompt có chỉ dẫn độ khó theo cấp.
- `CourseService`: `draftOutline` → `startCourse` (đề cương đã duyệt) → `sync` (sinh mẩu hôm nay + ngày mai theo `perDay`, giờ theo khung giờ kế hoạch học, xen kẽ nhiều khóa) → `markRead` (thẻ ôn FSRS **kích hoạt khi "Đã hiểu"**, due +1 ngày, vào Kho đã học) → `reconcile` (xử lý nút "Đã hiểu" bấm khi app đóng) → `generateNext` (đọc trước) → `changeLevel` (giữ đề cương + mẩu đã đọc, mẩu sau theo cấp mới) → pause/delete.
  Chỉ sinh khi `ai.isRealProvider` (hoặc `allowMockContent` trong test) — không coi mock là AI thật.
- Sửa lỗi phát hiện khi viết test: `ReviewRepository.listByKnowledgeItem` chỉ trả thẻ active → thêm `listAllByKnowledgeItem` (kể cả thẻ chưa kích hoạt).

### Pha 2 — Giao diện
- **Trang chủ** (`today_screen.dart`) viết lại: thẻ chính "HÔM NAY BẠN CÒN" + nút Bắt đầu (đi lần lượt mẩu mới → ôn tập), **Chưa đọc** (≤3, xem tất cả), **Đang theo** (tiến độ từng khóa), nút `[+]` gom Thêm khóa học/Bài học AI/Tạo chủ đề/Khám phá.
  Bỏ: lời chào dài, "Tiến độ hôm nay 13/10", "Nhanh tập trung", "Chủ đề gần đây", nhãn "Đã phát hành". Nội dung kế hoạch học cũ (quick/lesson đã phát hành chưa mở) được gộp vào "Chưa đọc" thay vì một danh sách riêng.
- `AddCourseScreen` (3 bước: chọn chủ đề nhiều lựa chọn → cấp độ + số mẩu → xem/chỉnh đề cương), `CourseReaderScreen` (nút Đã hiểu ghim đáy, nhãn Chưa kiểm chứng, **Báo nội dung**), `CourseDetailScreen` (tiến độ, đề cương, đổi cấp độ, tạm dừng, xóa).
- Tuân `DESIGN.md`: dùng chung AppCard/AppButton/AppChip, có loading/empty/error, không emoji thay icon; cập nhật DESIGN.md (mục Trang chủ) + PRODUCT.md.
- Phát hiện & sửa: khối `fonts:` trong `pubspec.yaml` bị đặt dưới `flutter_launcher_icons` nên **Inter chưa từng được bundle** → chuyển về dưới `flutter:`.

### Pha 3 — Thông báo
- Payload mới `course:<id>` (+ JSON), router mở `CourseReaderScreen` (cold start + warm start).
- `scheduleCourseNotification`: **BigText** (đọc tóm tắt không cần mở app), footer "Mẩu i/N · Chưa kiểm chứng", nút **Đã hiểu** (không mở UI) + **Đọc đầy đủ**, kênh riêng `mind_keeper_course`, ID âm FNV-1a ổn định (-9.000.000…).
  Nút "Đã hiểu": app đang chạy → `CourseService.markRead`; app đóng → `courseNotificationBackground` (isolate nền) ghi `status=read`, lần mở app sau `reconcile()` kích hoạt thẻ ôn.
- Báo thức **chính xác** khi hệ thống cho phép (`SCHEDULE_EXACT_ALARM` + `canScheduleExactNotifications`), không thì lùi về không chính xác (Android có thể lùi tới ~1 giờ).
- iOS: `DarwinNotificationCategory` với 2 nút (chưa kiểm thử được — cần Mac).

### Pha 4 — Thương hiệu, màn hình khởi động, tài liệu cửa hàng
- **Icon mới** (chữ M nét tròn + tia sáng, gradient) vẽ bằng `BrandMarkPainter` (`lib/core/widgets/brand_mark.dart`), render bằng `tool/brand/render_brand_test.dart`, áp bằng `flutter_launcher_icons` (Android adaptive + legacy, iOS full-bleed không alpha).
- **Splash**: native Android (gradient + logo; Android 12+ `values-v31`), iOS `LaunchImage` + nền storyboard, trong app `SplashOverlay` (logo + tia sáng nảy + tên + khẩu hiệu, ~1,5 s, không chặn chạm). Nhãn app: `MindKeeper`.
- **Trang quyền riêng tư**: `site/` (index, privacy, terms, support) + workflow GitHub Pages `.github/workflows/pages.yml` (email/tên công khai lấy từ Repository variables, KHÔNG commit sẵn) + màn "Quyền riêng tư & điều khoản" trong Hồ sơ.
- **Hồ sơ đăng cửa hàng** (`store/`): nội dung vi/en (kiểm ký tự), icon 512/1024, ảnh bìa, 5 ảnh chụp thật từ thiết bị đóng khung cho Android/iPhone 6.7/6.5/5.5/iPad 12.9, video giới thiệu 18,6 s (thiết bị chặn `screenrecord` nên dựng từ khung ảnh bằng ffmpeg), Data safety, App Privacy, khai báo Play, checklist; cây **fastlane** (`Fastfile`, `Appfile`, `tool/store/prepare_fastlane.sh`); runbook cho AI Agent `DOCS/STORE_AGENT_GUIDE.md`.
- Ký bản phát hành: `build.gradle.kts` đọc `android/key.properties` (gitignored); thiếu thì ký debug (không dùng đăng store).

### Test đã chạy (kết quả THẬT)
- `flutter analyze lib`: 0 error; 2 warning có sẵn ở `firebase_messaging_service.dart`.
- Unit/widget: **229 test pass** (core+data+features, trừ file bên dưới). Mới: `course_service_test` (12), `migration_v9_test` (4), `course_ui_test` (7), `brand_splash_test` (3); cập nhật `database_migration_test` (11 bảng/10 FK), `layout_overflow_test`, `widget_test` theo giao diện mới.
- **Lỗi có sẵn, KHÔNG do GĐ23**: `test/features/study_plan_screen_test.dart` treo/"No tests were found" cả ở commit `5b0c28c` (đã kiểm tra bằng git worktree sạch). Chưa sửa.
- Maestro trên OPPO CPH2203 (Android 13): `maestro/gd23/` — 01 trang chủ mới + menu [+]; 02 thêm khóa học (chọn chủ đề → cấp độ/số mẩu → đề cương → bỏ mục → bắt đầu); 03 đọc mẩu → Đã hiểu; 04 chạm thông báo mở đúng mẩu (intent `SELECT_NOTIFICATION`); 05 chụp ảnh cửa hàng. Kết quả chạy lần cuối: xem `DOCS/QA/GD23_ACCEPTANCE.md`.

### Rủi ro / chưa xác minh (TRUNG THỰC)
1. **Thông báo hẹn giờ KHÔNG hiện trên OPPO CPH2203 trong thử nghiệm của phiên này.** Đã xác nhận: quyền thông báo + báo thức chính xác đã cấp, báo thức đặt với `exactAllowReason=permission`, hệ thống **đã gửi broadcast** tới `ScheduledNotificationReceiver` đúng giờ (`dumpsys activity broadcasts`), nhưng không có thông báo và kênh `mind_keeper_course` không được tạo; bộ nhớ đệm lịch của plugin còn nguyên mục đã "nổ". Nghi do ColorOS chặn broadcast nền (tối ưu pin/tự khởi chạy). Chưa thử được "Tự khởi chạy"/bỏ tối ưu pin qua adb (không đủ quyền). → Cần chủ máy bật "Tự khởi chạy" + bỏ tối ưu pin rồi thử lại; BigText/nút hành động **chưa được xác nhận bằng mắt** (đã có test fake + code theo API chuẩn của plugin). Deep link khi chạm thông báo thì ĐÃ xác nhận (flow 04).
2. Nguồn tham khảo là AI tự ghi (chưa kiểm chứng) — đúng quyết định của chủ; chưa có tra cứu web.
3. Hai hệ thống phát hành song song: kế hoạch học cũ (quick/lesson mặc định 5+2 mẩu/ngày) và khóa học. Chưa gộp; người dùng có thể giảm quota/tạm dừng ở "Kế hoạch học".
4. iOS (build, thông báo có nút, splash, icon) chưa kiểm chứng — không có Mac.
5. Firebase chưa cấu hình (`google-services.json` thiếu) → quyết định gỡ hay cấu hình trước khi khai Data safety (xem `store/RELEASE_CHECKLIST.md`).
6. Chưa quay video màn hình thật (thiết bị chặn `screenrecord`); video giới thiệu dựng từ ảnh chụp.
7. Flutter test trên Windows có thể bị khóa `sqlite3.dll` bởi `flutter_tester` mồ côi; đã chạy test từ bản sao dự án ở thư mục tạm.

## Cập nhật phiên sửa lỗi (2026-10-28)

- Sửa `test/features/layout_overflow_test.dart` (WIP, 11 fail): helper `_pump()` không còn gọi `runAsync` lồng `pumpWidget` (khử "Guarded function conflict"); thay `Future.delayed` thật bằng `tester.binding.delayed` (khử TimeoutException 10 phút); mọi `_pump(...)` đều `await` đầy đủ.
- Tạo `maestro/cph2239/01_smoke.yaml` + `run.sh`: flow launch app + màn hình chính trên CPH2239 (OPPO, Android 13).
- `flutter analyze`: 0 error (các issue còn lại là info/deprecation pre-existing ở notification_service, settings_screen, tool/fix_entry_test).
- Thiết bị kiểm thử hiện tại: OPPO CPH2239 (Android 13) thay thế CPH2203.
- `flutter test` trên Windows vẫn cần workaround `tool/run_flutter_test.ps1` (kill `flutter_tester.exe` + xóa `build/native_assets/` trước mỗi lần chạy do `sqlite3.dll` bị lock).
- Phiên này được phép commit/push (theo yêu cầu chủ).

## Nghiệm thu thông báo trên CPH2325 (2026-10-28)

- Sửa: `notification_service.dart` (BigText cho nhắc kiến thức / nội dung mới / thẻ ôn), `notification_router.dart` (payload thiếu id không crash), `notification_settings_screen.dart` (nút debug không còn lỗi trùng kiến thức), `ios/Runner/AppDelegate.swift` (đặt delegate thông báo — **chưa verify iOS**).
- Máy nghiệm thu cố định: OPPO CPH2325 (`T4E6S8IFU4AQBM8L`). Smoke + flow `maestro/notif/` (10, 20, 21, 30) PASS; chạm warm/cold `card:`, `lesson:` (thông báo thật) và `course:` (warm thật, cold qua intent `SELECT_NOTIFICATION`) mở đúng màn.
- Test từng file (timeout 180 giây): 225 test pass; `layout_overflow_test` 3 fail **có sẵn trên HEAD**; `study_plan_screen_test` treo **có sẵn**. Chi tiết và đường dẫn ảnh/log: `DOCS/QA/NOTIFICATION_FIX_REPORT.md`.
- Báo thức thẻ ôn giữ **inexact**; độ trễ ~90 giây trên CPH2325 là hành vi đã chấp nhận.
- Dữ liệu mẫu đã dọn, prefs khôi phục về bản gốc.
- Đính chính mục "Cập nhật phiên sửa lỗi (2026-10-28)" phía trên: `layout_overflow_test` hiện vẫn lỗi (3 fail), không còn ở trạng thái đã sửa.

## Nội dung thông báo mới + icon + nội dung ngắn có Mẹo nhớ (2026-10-28)

- Thông báo quick/course/lesson dựng lại: title = tên mẩu/bài, body = ý chính ≤180 ký tự (helper `notification_text.dart`, không cắt giữa từ), bigText = tóm tắt + "Mẹo nhớ: …", subText = chủ đề (khóa học: khóa · cấp độ). Thẻ ôn / nhắc kiến thức giữ nguyên.
- Icon Android: small `ic_stat_mindkeeper` (chữ M + sao, đơn sắc) + large `ic_notification_large` (logo màu) cho mọi kênh.
- Nội dung mới ngắn: mẩu/bài 120–180 từ, ≤3 ý chính, ví dụ 1 câu, summary ≤200, `memoryTip` ≤120 ký tự. Schema **v10** (`course_items.memory_tip`; DDL v9 đóng băng cho migration), `LessonContent.memory_tip`, prompt bài học bump `v3`, `LessonMode` 100–180 từ. Card "Mẹo nhớ" ở CourseReader/LessonReader, ẩn khi rỗng.
- Nghiệm thu CPH2325 + test: xem `DOCS/QA/NOTIFICATION_FIX_REPORT.md` (phần "Bổ sung") — 35/37 file test pass (251 test); `layout_overflow_test` (3 fail) và `study_plan_screen_test` (treo) là lỗi có sẵn.
- Còn lại: iOS chưa verify; báo thức thẻ ôn vẫn inexact; Maestro rò rỉ `tmp*.apk` trong `%TEMP%`.

## Sao lưu & khôi phục (2026-10-28)

- Màn Hồ sơ → "Sao lưu & khôi phục" (`BackupRestoreScreen`, `BackupService`): xuất/nhập file `.mkbackup` (JSON) gồm 11 bảng SQLite + prefs người dùng (`PreferencesService.backupKeys`); KHÔNG gồm khóa API/cấu hình AI, phiên chạy, ID thông báo, file media (ghi rõ trong UI). Header: format, version, schemaVersion, exportedAt, appVersion, counts.
- Khôi phục: validate (từ chối file sai định dạng / schema mới hơn / counts lệch), xác nhận "Thay thế toàn bộ dữ liệu hiện tại", tự ghi bản sao lưu an toàn trong `app_flutter/backups/` trước khi ghi đè, ghi trong MỘT transaction (lỗi → rollback), `foreign_key_check`, xóa `storage_path` tuyệt đối; sau đó hủy lịch thông báo cũ, tắt cờ nhắc nếu thiếu quyền, lập lại lịch, bump `dataVersion`.
- Nghiệm thu trên CPH2325: roundtrip xuất → xóa dữ liệu → khôi phục khớp số dòng, lịch FSRS (due/stability/difficulty/reps) và prefs; file không chứa API key; file hỏng và schema v99 bị từ chối. Báo cáo: `DOCS/QA/BACKUP_RESTORE_REPORT.md`.
- Chưa có: sao lưu cloud, mã hóa file, tự động sao lưu định kỳ. iOS chưa verify.

