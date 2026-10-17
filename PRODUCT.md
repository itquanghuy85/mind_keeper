# PRODUCT.md — MindKeeper AI

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

Học sinh, sinh viên, người học kỹ thuật, kinh doanh và kiến thức đời sống. Dùng cá nhân, mobile-first, tiếng Việt.

## Product Purpose

Ứng dụng giúp người dùng lưu kiến thức, nhớ lại theo lịch ngắt quãng (FSRS), khám phá chủ đề mới và học mỗi ngày với ít thao tác.

Vấn đề cần giải quyết:

- kiến thức phân tán, dễ quên
- ôn tập không có lịch khoa học
- nội dung dài gây quá tải

Thành công nghĩa là: người dùng ghi được kiến thức nhanh, ôn đúng hạn, học mỗi ngày với ít thao tác.

## Positioning

Cơ chế khác biệt mà app ghi chú/flashcard thông thường không có:

- Lịch ôn riêng theo từng ReviewCard theo FSRS, không lịch chung theo chủ đề.
- AI hỗ trợ ghi nhận/tóm tắt nội dung nhưng không bao giờ thay thuật toán lịch ôn.
- Chủ đề mới và ôn kiến thức cũ là hai hoạt động riêng biệt.
- Dữ liệu cục bộ bền vững qua SQLite (offline-first, không bắt buộc online).

## Operating Context

- App Flutter, tiếng Việt, chỉ hướng dọc (khóa orientation trong `lib/main.dart`).
- Shell 4 tab (IndexedStack): Hôm nay, Chủ đề, Thống kê, Cá nhân.
- Màn hình phụ: chi tiết chủ đề, danh sách kiến thức, ôn tập, tạo/sửa kiến thức, khám phá, tạo chủ đề, import, cài đặt thông báo.
- Ôn tập: một câu hỏi mỗi lần, ẩn đáp án đến khi người dùng bấm "Xem đáp án"; đánh giá nhớ 4 mức Quên / Khó / Tốt / Dễ.
- Thông báo cục bộ mở đúng nội dung được nhắc (notification payload `card:<id>`).
- Nhập nội dung qua PDF, ảnh (OCR), và giọng nói.

## Capabilities and Constraints

Chức năng đã xác nhận:

- Lưu/tạo/sửa kiến thức, quản lý chủ đề, khám phá, thống kê.
- Lịch ôn FSRS theo từng ReviewCard + thông báo cục bộ.
- Nhập nội dung: PDF, OCR ảnh (ML Kit), speech-to-text.
- AI hỗ trợ (tóm tắt/gợi ý), phân biệt rõ với nội dung đã xác nhận; tiết kiệm token/call AI; cache hợp lý.

Ràng buộc:

- Không nhúng API key vào client; không commit credentials.
- Không dùng mock để báo cáo dịch vụ thật đã hoạt động.
- Không hiển thị số liệu giả.

Chưa quyết định: chuẩn accessibility chính thức (xem `## Accessibility & Inclusion`).

## Brand Commitments

- Tên: MindKeeper AI.
- Ngôn ngữ giao diện: tiếng Việt (bắt buộc).
- Giọng giao diện: đơn giản, hiện đại; không dashboard dày đặc; không nút trang trí.
- Design tokens và bộ component dùng chung đã chốt nằm trong `DESIGN.md` (Inter, primary indigo `#6355E7`, AppCard/AppButton/...) — DESIGN.md là nguồn duy nhất, không nhân bản tại đây.

## Evidence on Hand

- `DESIGN.md` — design tokens & UI principles đã chốt.
- `lib/` — 64 file Dart; bộ component `lib/core/widgets`; features: home, topics, knowledge, review, discover, import, stats, profile, ai, shell.
- `assets/fonts` — Inter bundle.
- Packages thật đang dùng: `fsrs`, `sqflite`, `google_mlkit_text_recognition`, `syncfusion_flutter_pdf`, `speech_to_text`.

Vắng mặt (công việc tương lai không được bịa):

- Chưa implement accessibility: 0 chỗ dùng `Semantics` trong `lib/`.
- Chưa có press/testimonial/số liệu người dùng thật.
- README còn template mặc định.

## Product Principles

1. Nội dung học mặc định ngắn gọn, một ý.
2. Người dùng tự nhớ trước khi xem đáp án.
3. Lịch ôn riêng theo từng ReviewCard (FSRS), không lịch chung theo chủ đề.
4. Chủ đề mới và ôn kiến thức cũ là hai hoạt động riêng.
5. Thông báo mở đúng nội dung được nhắc.
6. AI hỗ trợ, không thay thuật toán lịch ôn.
7. Dữ liệu bền vững qua SQLite.
8. Nội dung AI/gợi ý phân biệt với nội dung đã xác nhận.
9. Tiết kiệm token/call AI; cache hợp lý.
10. Giao diện tiếng Việt, đơn giản, hiện đại.

## Accessibility & Inclusion

- Yêu cầu nền (quyết định ủy quyền 2026-10-17): hỗ trợ cỡ chữ theo cài đặt hệ thống (system text scale); tương phản màu đủ đọc trên nền sáng; giao diện tiếng Việt.
- Chưa cam kết chuẩn WCAG / screen-reader chính thức; repo hiện chưa implement accessibility (0 `Semantics`) — cần pass riêng trước khi tuyên bố hỗ trợ.

