# DESIGN.md — MindKeeper AI

## Design tokens

- Font: Inter (bundle trong `assets/fonts`, khai báo dưới `flutter:` → `fonts:` trong `pubspec.yaml`; trước GĐ23 khối này bị đặt nhầm dưới `flutter_launcher_icons` nên app thực tế dùng font hệ thống).
- Màu giao diện: `AppColors.primary` = `#0068FF` (xem `lib/core/theme/app_colors.dart`), nền sáng xanh nhạt.
- Màu **thương hiệu** (icon, splash, tài liệu cửa hàng): gradient `#6D5DF6` → `#2F6FED`, điểm nhấn `#FFC857` — `BrandColors` trong `lib/core/widgets/brand_mark.dart`.
- Semantic: success `#22B573`, warning `#F0A02A`, danger `#E5484D`, info `#3B82F6`.
- Spacing: 4/8/12/16/20/24/32 (AppSpacing).
- Radius: 8/12/16/20/28/pill (AppRadius).

## Nguyên tắc UI

- Mobile-first, tiếng Việt, một phong cách component dùng chung (`AppCard`, `AppButton`, `AppChip`, `AppTag`, `AppTextField`, `AppLoading`, `AppEmptyState`, `AppErrorState`).
- Mỗi màn hình đều có loading / empty / error / success feedback.
- Không nút trang trí, không dashboard dày đặc, không emoji thay icon.
- Ôn tập: một câu hỏi mỗi lần, ẩn đáp án đến khi người dùng bấm "Xem đáp án".
- Đánh giá nhớ: 4 mức Quên / Khó / Tốt / Dễ (tông màu riêng AppColors.rating*).

## Điều hướng

- Shell 4 tab (IndexedStack).
- Route đặt tên cho: chủ đề, chi tiết chủ đề, kiến thức, ôn tập, khám phá, import, cài đặt.
- Notification payload `card:<id>` mở thẳng thẻ cần ôn.
- Màn đọc mẩu khóa học / bài học: thẻ **Mẹo nhớ** (`MemoryTipCard`: icon bóng đèn + tiêu đề + 1 câu) nằm sau nội dung/tóm tắt; **ẩn hoàn toàn** khi mẹo rỗng (nội dung cũ).
- Thông báo Android: small icon đơn sắc `ic_stat_mindkeeper` (chữ M + sao, trắng/trong suốt) và large icon logo màu `ic_notification_large` cho mọi kênh; title = tên mẩu/bài, body = ý chính ≤180 ký tự, bigText = tóm tắt + "Mẹo nhớ: …", subText = chủ đề (khóa học: khóa · cấp độ).

## Trang chủ (GĐ23) — một việc chính mỗi lần mở

- Đầu trang: ngày + nút `[+]` (menu: Thêm khóa học, Bài học AI, Tạo chủ đề, Khám phá). Không lời chào/khẩu hiệu.
- **Thẻ chính** gộp việc hôm nay: "HÔM NAY BẠN CÒN · N mẩu mới · M thẻ ôn · ≈ X phút" + một nút **Bắt đầu** đi lần lượt (mẩu mới trước, hết thì sang ôn tập).
  Hết việc → "Xong cho hôm nay" + "Đọc trước mẩu kế tiếp". Chưa có khóa học → "Học một chủ đề mới" + "Thêm khóa học".
- **Chưa đọc**: tối đa 3 mục (có "Xem tất cả"), mỗi mục: `Chủ đề · Cấp độ`, tiêu đề đầy đủ (≤ 3 dòng), thời gian đọc ước tính từ độ dài thật.
- **Đang theo**: mỗi khóa một dòng (tên, cấp độ, thanh tiến độ `đã đọc/tổng`).
- Quy tắc: danh sách chỉ chứa việc chưa làm; không con số khó hiểu; không dùng emoji thay icon; tên màn trong nhãn semantics để Maestro bám vào.
- Màn đọc mẩu: nút **Đã hiểu** luôn ghim ở đáy; nhãn "AI tự soạn · Chưa kiểm chứng"; nút cờ **Báo nội dung** trên AppBar.
- Màn khởi động: nền gradient thương hiệu + logo M, nối liền với splash native (Android 12+ `values-v31`, iOS `LaunchImage`) rồi mờ dần (`SplashOverlay`, ~1,5 s, không chặn chạm).
