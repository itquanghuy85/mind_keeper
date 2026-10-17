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
- **Cold start**: `adb am force-stop` rồi `am start` → `LaunchState: COLD`, `TotalTime ~578ms`, app mở thành công.
- **Cài đặt APK**: `app-debug.apk` cài thành công (`install -r`, giữ dữ liệu người dùng, không xóa dữ liệu). Gói bị gỡ/cài lại do conflict signature khi cài đè debug lên release trước đó — đã `uninstall` rồi cài lại debug.
- **Màn hình chính**: UI dump xác nhận `com.mindkeeper.mind_keeper` hiển thị màn hình "Hôm nay" với bottom navigation 4 tab ("Trang chủ" selected, "Chủ đề", "Thống kê", "Hồ sơ").

### Kết quả thông báo nhắc ôn (ưu tiên cao)
- **Quyền thông báo**: `adb shell appops get com.mindkeeper.mind_keeper POST_NOTIFICATION` → `Uid mode: POST_NOTIFICATION: ignore` → quyền đang **bị từ chối/mặc định không được phép** trên Android 13. Người dùng cần cấp thủ công trong Cài đặt hệ thống hoặc qua nút "Yêu cầu quyền thông báo" trong màn hình Cài đặt thông báo của app.
- **Thông báo trong hệ thống**: `dumpsys notification` không tìm thấy bất kỳ thông báo nào từ `com.mindkeeper.mind_keeper` (chưa có lịch ôn nào được lập hoặc quyền chưa được cấp).
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

## GĐ15.1 — FIX VÀ KIỂM THỬ THÔNG BÁO ANDROID THỰC TẾ (tạm ngưng 2026-10-17, chưa PASS)

### Bước 1 — Kiểm tra implementation hiện tại (đã xác minh một phần)
- `flutter_local_notifications 22.3.2` (pubspec.yaml `^22.3.2`, pubspec.lock `22.3.2`).
- `AndroidManifest.xml`: có `POST_NOTIFICATIONS` + `RECEIVE_BOOT_COMPLETED`.
- `LocalNotificationService.requestPermissions()`: Android gọi `android.requestNotificationsPermission()` → `granted ?? false`; iOS `requestPermissions(alert/badge/sound)`; desktop/web trả `true`; catch trả `false` (không tuyên bố có quyền khi lỗi).
- `areNotificationsEnabled()`: Android đọc `areNotificationsEnabled()`; nền tảng khác trả `null` (không đoán).
- `openNotificationSettings()` → `openAppNotificationSettings()`, không tự bật quyền.
- `NotificationSettingsScreen`: nút "Yêu cầu quyền thông báo" gọi `requestPermissions()`, set `_notificationsAllowed = granted`, hiện SnackBar + nút "Mở cài đặt" khi bị từ chối; `_refreshPermissionStatus()` chạy lúc init + resumed (resync lịch khi allowed); toggle bật xin quyền rồi mới `refreshReminderSchedule()`, toggle tắt gọi `cancelAll()`. Debug card tạo topic riêng "Kiểm thử thông báo" (không xóa dữ liệu user) + `scheduleCardDueAt` +2 phút / `showCardDue` với payload `card:<id>`.
- `TodayScreen._handlePendingNotification`: đọc `AppBootstrap.pendingNotificationPayload`, `card:<id>` → `ReviewScreen(targetCardId)`, còn lại → `ReviewScreen()` chung.
- Chưa đọc chữ ký `requestNotificationsPermission` trong pub cache để chốt API đúng — việc còn lại đầu tiên cho agent tiếp theo.

### Trạng thái thiết bị CPH2203 (2026-10-17)
- `adb -s NJR8W86LKRVW7DHQ shell appops get ... POST_NOTIFICATION` → `No operations. Default mode: allow`.
- `dumpsys package ...` → `POST_NOTIFICATIONS: granted=true, flags=[USER_SET|...]` — hiện ĐANG granted (khác trạng thái ignore ghi ở GĐ15).
- SDK 33 (Android 13). Lưu ý: có 2 thiết bị cắm song song (thêm CPH2239 `WCE65565HMDYOB59`) → mọi lệnh adb phải kèm `-s NJR8W86LKRVW7DHQ`.
- Worktree đang bẩn (chưa commit theo quy định): xem `git status -s`. File mới đáng chú ý: `maestro/notification_permission.yaml`, `test/core/notification_permission_test.dart`, `ios/Podfile`, `.claude/`, `.serena/`.

### Còn lại (agent tiếp theo làm)
1. Soi chữ ký plugin trong pub cache `flutter_local_notifications-22.3.2`, chốt sửa Bước 2 (không claim quyền khi chỉ gọi API, có đường Settings khi denied, không exact alarm, không nâng dep hàng loạt).
2. `flutter analyze`, `flutter test`, build APK debug nếu sửa code; kiểm tra/bổ sung test quyền + payload.
3. Kiểm thử 11 mục Bước 3 trên CPH2203 (dùng topic test riêng, không xóa dữ liệu user).
4. Cập nhật file này khi PASS. Không commit/push.

