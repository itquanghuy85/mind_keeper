# GĐ20.1 — VISUAL POLISH TRANG CHỦ (TodayScreen) — BÁO CÁO NGHIỆM THU

**Ngày hoàn thành:** 2026-10-19
**Thiết bị test:** OPPO CPH2203 (Android 13, API 33), ADB serial `NJR8W86LKRVW7DHQ`
**Package:** `com.mindkeeper.mind_keeper` v1.0.0+1 (debug, `adb install -r` — giữ dữ liệu người dùng)
**Repo:** `D:\FlutterProjects\mind_keeper`, branch `master`, HEAD `3f1d643` — **chưa commit/push (yêu cầu của GĐ20.1)**
**Trạng thái:** ✅ HOÀN THÀNH phạm vi code + test + nghiệm thu thiết bị (pixel-measured)

---

## 1. TỔNG KẾT

| Hạng mục | Kết quả |
|---|---|
| `flutter analyze` | **No issues found** (0 issue, toàn dự án) |
| `flutter test` (full suite) | **+141 All tests passed** (baseline GĐ20: 131 → thêm 10 test mới) |
| `dart format` (file đã sửa) | Đã chạy |
| `flutter build apk --debug` | **SUCCESS** → `build\app\outputs\flutter-apk\app-debug.apk` |
| `adb install -r` | **SUCCESS**, dữ liệu người dùng giữ nguyên |
| Thẻ thao tác nhanh light | Nền **#FFFFFF**, 3 thẻ **rộng bằng nhau 308px**, nền **#F4F8FF** (đúng Design System xanh dương–trắng) |
| Card nhắc ôn + chữ | Không tràn mép; số đếm 1 dòng, trong phạm vi thẻ |
| Font scale 2.0× @ 320px | **Không còn overflow** (trước fix: `RenderFlex overflowed by 80 pixels`) |
| Light/Dark luminance | 216.0 / 38.1 — khớp baseline GĐ20 (212.6 / 38.1), không regression |
| Giao dịch/FSRS/notification/AI | **Không đụng tới** (chỉ UI + shadow token + test) |
| Commit/push | **KHÔNG thực hiện** |

---

## 2. NGUYÊN NHÂN GỐC ĐÃ SỬA

### 2.1 Card hiện màu xám (đúng triệu chứng trong screenshot)

| | |
|---|---|
| **Triệu chứng** | Nền thẻ trên trang chủ ra xám đục thay vì trắng (#FFFFFF light / #182334 dark) |
| **Root cause** | `AppCard` gắn `boxShadow` ở lớp **không có nền** (DecoratedBox nằm ngoài Material) → bóng translucent nhìn xuyên qua mặt thẻ, hòa với nền tạo ra màu xám |
| **Fix** | `lib/core/widgets/app_card.dart`: tách 2 lớp — **DecoratedBox (chỉ bóng)** ở ngoài + **Material đục (nền thẻ)** ở trong → bóng nằm dưới nền, không còn "vệt xám" |
| **Shadow token làm nhẹ** | `lib/core/theme/app_colors.dart`: `shadow` `0x120A1B33` → `0x0F0A1B33`, `shadowStrong` `0x1F0A1B33` → `0x1A0A1B33` (`shadowDark` giữ nguyên `0x33000000`) |
| **Xác minh** | Test pixel + đo ảnh thiết bị (§5): light thẻ `#FFFFFF` — vùng `#EEEFF0` (màu xám cũ) chỉ còn ~0.03% pixel (do anti-alias), dark thẻ = `surfaceDark #182334`, bề mặt trắng chiếm 0.16% (chỉ chữ) |

### 2.2 Tràn layout ở cỡ chữ lớn (`RenderFlex overflowed by 80 pixels`)

| | |
|---|---|
| **Root cause** | `AppSectionHeader` dùng `Row(Expanded(title), actionLabel non-flex)` — nhãn hành động (vd `0/3 mục tiêu`) là child **không flex** → nhận constraint không giới hạn theo trục ngang, đến 2.0× thì vượt quá bềng 288px → tràn 80.3px |
| **Chứng minh** | Probe tái hiện đúng tại chỗ (dùng hook `FlutterError.onError` quét `RenderFlex` khi lỗi xảy ra): `FLEX OVER by 80.3 w=288.0 sum=368.3 CHAIN=Row > Padding > AppSectionHeader > ...` |
| **Fix** | `app_card.dart`: `AppSectionHeader` đổi `Row` → **`Wrap(alignment: spaceBetween, runSpacing: xs)`** — khi vừa một dòng vẫn là *tiêu đề trái / hành động phải*, khi không vừa thì nhãn hành động **xuống dòng** thay vì tràn. Ảnh hưởng chung mọi màn hình dùng header (sửa tại component dùng chung, đúng nguyên tắc GĐ20) |

### 2.3 Các polish khác trên `today_screen.dart`

| Vị trí | Thay đổi |
|---|---|
| Dòng quick actions | Bọc `IntrinsicHeight` + `Row(crossAxisAlignment: stretch)` → **3 thẻ cao bằng nhau** kể cả khi subtitle dài khác nhau |
| Subtitle quick action | Rút gọn: `'Soạn bài + quiz'`, `'Từ ghi chú của bạn'`, `'Lĩnh vực mới mỗi ngày'` (giảm chiều cao, tránh cắt chữ) |
| `_QuickActionCard` | title `maxLines: 2`; subtitle `maxLines: 2` + `height: 1.25` |
| Card nhắc ôn — số đếm | `Text('$_dueCount', maxLines: 1, softWrap: false, textAlign: end)` — số luôn 1 dòng, không bị nội dung đẩy |
| Card nhắc ôn — title/subtitle | Thêm `maxLines: 2` + `overflow: ellipsis` — nội dung dài xuống dòng có kiểm soát, **không đè** lên số đếm |

---

## 3. TEST MỚI (10 test — không sửa/xoá test cũ)

| File test | Số test | Kết quả | Nội dung |
|---|---|---|---|
| `test/core/app_card_rendering_test.dart` *(mới)* | 4 | **PASS** | Pixel-level: nền thẻ light = `#FFFFFFFF`; nền thẻ dark == `AppColors.surfaceDark`; không bóng lem sát mép dưới thẻ; dark surface không bị ép trắng (luminance < 0.25) |
| `test/features/today_screen_polish_test.dart` *(mới)* | 6 | **PASS** | 3 test bố cục thẻ thao tác nhanh (cao bằng nhau, top/bottom khớp, chữ không tràn mép thẻ ở 1.0×; hình học lại ở 1.3×; 2.0×@320 không ném exception) + 2 test card nhắc ôn (số đếm 1 dòng, nằm trong thẻ, ở 2.0× không tràn mép phải) + 1 test tổng `takeException isNull` |
| **Full suite** | **141** | **ALL PASS** | Baseline 131 của GĐ20 giữ nguyên, không test nào bị bỏ |

**Bẫy test đã gặp (ghi lại cho agent sau):**

1. **Font mặc định của test pessimistic**: mỗi ký tự đúng bằng `fontSize` (chữ Việt không dấu cũng chiếm đủ ô) → `didExceedMaxLines` luôn `true` với chuỗi dài dù máy thật hiển thị trọn. **Kết luận:** không assert ellipsis bằng font test; assert **hình học** (rect chữ nằm trong rect thẻ) — chính xác ở cả font thật lẫn font test.
2. **ListView lazy-build**: thẻ thao tác nhanh nằm ngoài khung nhìn 360×640 → `tester.getRect` miss; phải `tester.scrollUntilVisible(find.text('Khám phá'), ...)` trước khi đo.
3. **Đặt `textScaler` ở đâu quyết định tái hiện được lỗi**: chỉ khi `MediaQuery(textScaler)` nằm **ngoài** `MaterialApp` (đúng pattern `_withTextScale`) thì overflow 80px mới xuất hiện; đặt trong `home:` thì không (MediaQuery bị theme/App-level MediaQuery override).
4. **DB trong test**: `sqfliteFfiInit` + mở DB + seed **bắt buộc** trong `tester.runAsync`, ngược lại main-isolate treo.
5. **Probe kỹ thuật tái hiện overflow tại chỗ** (dùng lại được): ghi đè `FlutterError.onError`, trong handler quét `tester.allRenderObjects.whereType<RenderFlex>()`, cộng `child.size.width` (bỏ qua flex child = size đã phân bổ) → nếu `sum > ro.size.width` là thủ phạm; lấy chuỗi widget qua `debugCreator.element.visitAncestorElements`. File probe `test/_probe_test.dart` đã dùng xong và **đã xoá**.

---

## 4. NGHIỆM THU TRÊN THIẾT BẬT THẬT (pixel, không chỉ cảm quan)

Ảnh trong `DOCS/QA/artifacts/GD20/`: `gd201_after_light.png` (đầu trang), `gd201_after_light_mid.png` / `gd201_after_light_bottom.png` (đã cuộn), `gd201_after_dark.png`, `gd201_after_dark_bottom.png` (+ crop `crop_header.png`, `crop_review.png`, `crop_dark_header.png`).

### 4.1 Light (1080×2400, dpr 3)

| Chỉ số | Đo được |
|---|---|
| Top colors (đầu trang) | `#F4F8FF` **38.4%** (nền app), `#FFFFFF` **28.8%** (thẻ), `#0068FF` 5.9% (primary) |
| Top colors (đã cuộn) | `#FFFFFF` **39.5%**, `#F4F8FF` 25.1% |
| Màu xám cũ `#EEEFF0`-ish | **~0.03%** pixel (chỉ anti-alias) — trước fix là vùng lớn |
| 3 thẻ thao tác nhanh | Rộng **308px mỗi thẻ** (x = 50–357 / 386–693 / 722–1029), pitch đều 336px, lề 50px hai bên; cao bằng nhau (y = 887…1499 ở cột cả 3 thẻ) |
| Khe giữa 3 thẻ | `#EFF3FA` (bg + bóng nhẹ delta −5) — đúng mong đợi sau khi làm nhẹ shadow |
| Section header (`Tiến độ hôm nay` + `0/3 mục tiêu`) | Chữ tối **x 50–471** và nhãn xanh **x 742–1004** nằm **cùng một dải y** → cùng 1 dòng, không tràn |
| Mean luminance | **216.0** (đầu trang) / **219.0** (đã cuộn) — khớp baseline GĐ20 212.6 |

### 4.2 Dark (1080×2400)

| Chỉ số | Đo được |
|---|---|
| Top colors | `#101722` **45.6%** (`backgroundDark`), `#182334` **28.9%** (`surfaceDark` = thẻ), `#0068FF` 5.6% |
| Bề mặt trắng tuyệt đối | **0.16%** (chỉ glyph chữ) — **không còn thẻ/surface nào bị ép trắng** |
| Mean luminance | **38.1** (đầu trang) / **36.9** (đã cuộn) — khớp baseline GĐ20 38.1 |

### 4.3 Bottom nav / SafeArea

- `gd201_after_light_bottom.png`: nội dung kết thúc, có vùng nền trước `NavigationBar`, thanh nav + system nav bar không che nội dung (đã check ở phiên trước: ~106px nền trước nav).
- Không đổi hành vi nav trong GĐ20.1 (chỉ verify).

---

## 5. BẪY KỸ THUẬT TRONG PHIÊN NÀY (cho agent sau)

1. **`flutter test` crash `errno 183`/`errno 2`**: zombie process `flutter_tester` giữ lock `build\native_assets\windows\sqlite3.dll` khiến Flutter copy file thất bại. **Recipe bắt buộc trước mỗi lần chạy test:**
   ```powershell
   Get-Process flutter_tester -EA SilentlyContinue | Stop-Process -Force
   Remove-Item -Force build\native_assets\windows\sqlite3.dll -EA SilentlyContinue
   flutter test
   ```
   ⚠️ **KHÔNG** kill process `dart.exe` (LSP của VS Code/serena).
2. **Build APK fail `PathNotFoundException ... download-a42fa9d0\libsqlite3.so`**: cache native assets Android bị hỏng (thư mục hash cũ mất `.so`, hook dùng lại `output.json` cache nên không tải lại). **Fix:**
   ```powershell
   Remove-Item -Recurse -Force .dart_tool\flutter_build
   Remove-Item -Recurse -Force .dart_tool\hooks_runner\sqlite3
   Remove-Item -Recurse -Force build\native_assets
   flutter build apk --debug   # cần mạng để hook tải lại libsqlite3
   ```
3. **App activity**: package `com.mindkeeper.mind_keeper`, activity `.MainActivity` (KHÔNG phải `com.example.mind_keeper`).
4. **Máy hay ngủ** → screencap trả ảnh đen: `adb shell input keyevent KEYCODE_WAKEUP` + `adb shell wm dismiss-keyguard` trước khi chụp. Ảnh chụp được ngay sau `am start` có thể là splash (màu `#080C11`) → chờ ~14s rồi chụp lại.
5. **Đổi theme**: `adb shell cmd uimode night yes|no` (không dùng `settings put secure` — máy không cấp quyền).
6. Agent không đọc được nội dung ảnh (model không hỗ trợ image input) → xác nhận bố cục bằng **đo pixel bằng PIL** (crop + quét dải màu/vị trí chữ) và để người dùng đối chiếu thị giác.

---

## 6. VIỆC CÒN LẠI / KHUYẾN NGHỊ

1. **Người dùng đối chiếu thị giác** 5 ảnh trong `DOCS/QA/artifacts/GD20/gd201_after_*.png` (+ 3 crop) — agent xác minh bằng số đo pixel ở §4.
2. **Không commit/push** — toàn bộ GĐ20.1 đang ở working tree: 3 file tracked sửa + 2 file test mới + báo cáo này.
3. Dọn file nháp ngoài phạm vi repo (không phải code app): `create_*.py`, `screen_*.png`, `ui1.xml` ở gốc repo — **hỏi người dùng trước khi xoá**.
4. Smoke tay các luồng chính (Đọc bài → Ôn tập) trên bản build này nếu cần mức chứng cứ cao hơn.
5. Hạng mục BLOCKED của GĐ20 (deploy proxy backend) **không đổi** — xem §8 `GD20_FINAL_ACCEPTANCE.md`.

---

## 7. FILE THAY ĐỔI TRONG GĐ20.1

**Sửa (tracked):**
- `lib/core/widgets/app_card.dart` — fix bóng `AppCard` (nội dung + Material đục); `AppSectionHeader` `Row` → `Wrap`
- `lib/core/theme/app_colors.dart` — làm nhẹ `shadow` / `shadowStrong`
- `lib/features/home/today_screen.dart` — polish quick actions (IntrinsicHeight/stretch), subtitle rút gọn, maxLines/ellipsis card nhắc ôn, số đếm 1 dòng

**Thêm mới (untracked):**
- `test/core/app_card_rendering_test.dart` (4 test)
- `test/features/today_screen_polish_test.dart` (6 test)
- `DOCS/QA/GD20_1_VISUAL_POLISH.md` (báo cáo này)
- `DOCS/QA/artifacts/GD20/gd201_after_*.png`, `crop_*.png` (bằng chứng nghiệm thu)

**Không đổi:** schema/DB, FSRS, notification, AI, navigation, Design System token màu (chỉ shadow alpha 2 giá trị).
