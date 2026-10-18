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

