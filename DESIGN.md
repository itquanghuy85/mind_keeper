# DESIGN.md — MindKeeper AI

## Design tokens

- Font: Inter (đã bundle trong `assets/fonts`).
- Màu chủ đạo: indigo `#6355E7` (AppColors.primary), nền sáng trung tính `#F5F6FA`.
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
