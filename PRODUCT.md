# PRODUCT.md — MindKeeper AI

## Mục tiêu

Ứng dụng giúp người dùng lưu kiến thức, nhớ lại theo lịch ngắt quãng (FSRS), khám phá chủ đề mới và học mỗi ngày với ít thao tác.

## Đối tượng

Học sinh, sinh viên, người học kỹ thuật, kinh doanh và kiến thức đời sống.

## Vấn đề cần giải quyết

- kiến thức phân tán, dễ quên
- ôn tập không có lịch khoa học
- nội dung dài gây quá tải

## Nguyên tắc sản phẩm

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

## Cấu trúc chính

- 4 tab: Hôm nay, Chủ đề, Thống kê, Cá nhân.
- Màn hình phụ: chi tiết chủ đề, danh sách kiến thức, ôn tập, tạo/sửa kiến thức, khám phá, tạo chủ đề, import, cài đặt thông báo.

## Ràng buộc

- Không nhúng API key vào client; không commit credentials.
- Không dùng mock để báo cáo dịch vụ thật đã hoạt động.
- Không hiển thị số liệu giả.
