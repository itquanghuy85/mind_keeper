# MindKeeper

> Mỗi ngày nhớ thêm một chút.

Ứng dụng Flutter (tiếng Việt, mobile-first) giúp bạn học theo lộ trình: chọn chủ đề + cấp độ, AI soạn đề cương,
app nhắc đọc từng mẩu kiến thức ngay trên thông báo và ôn lại đúng lúc bằng thuật toán FSRS. Dữ liệu lưu trên máy
(SQLite), không tài khoản, không quảng cáo.

## Tính năng chính
- **Khóa học theo cấp độ** (Cơ bản / Nâng cao / Pro / Master): chọn nhiều chủ đề, số mẩu tùy ý, AI dựng đề cương để bạn chỉnh.
- **Trang chủ một việc chính**: thẻ "Hôm nay bạn còn…", danh sách *Chưa đọc*, *Đang theo* kèm tiến độ.
- **Thông báo đọc nhanh**: vuốt mở rộng để đọc ý chính, nút "Đã hiểu", chạm mở đúng mẩu.
- **Ôn tập FSRS** theo từng thẻ; nhập kiến thức từ văn bản, link, ảnh (OCR), PDF, giọng nói.
- Nội dung AI gắn nhãn **"Chưa kiểm chứng"**; nút **Báo nội dung**.

## Chạy thử
```bash
flutter pub get
flutter run \
  --dart-define=DEEPSEEK_BASE_URL=<url> --dart-define=DEEPSEEK_API_KEY=<khóa dev> --dart-define=DEEPSEEK_MODEL=<model>
# Bản phát hành: dùng proxy backend, KHÔNG nhúng khóa:
#   --dart-define=DEEPSEEK_BASE_URL=<proxy> --dart-define=DEEPSEEK_PROXY_MODE=true
```
Không có cấu hình AI thật thì các tính năng soạn nội dung báo "AI chưa được cấu hình" (không dùng nội dung mock như thật).

## Kiểm thử
```bash
flutter analyze
flutter test                       # xem ghi chú bên dưới về study_plan_screen_test
bash maestro/gd23/run.sh <serial>  # luồng Maestro trên thiết bị (cần mock AI: node tool/mock_ai_server.js 8765 + adb reverse)
```
Ghi chú: `test/features/study_plan_screen_test.dart` bị treo/không chạy được ngay cả ở commit trước GĐ23 (lỗi có sẵn,
chưa xử lý). Các bộ còn lại xanh.

## Tài liệu
| Tài liệu | Nội dung |
|---|---|
| `PRODUCT.md`, `DESIGN.md` | Mục tiêu sản phẩm, nguyên tắc thiết kế, token |
| `DOCS/IMPLEMENTATION_PROGRESS.md` | Nhật ký từng giai đoạn |
| `DOCS/QA/` | Báo cáo nghiệm thu trên thiết bị |
| `DOCS/STORE_AGENT_GUIDE.md` | Runbook cho AI Agent đăng Google Play / App Store |
| `store/README.md` | Tài sản & tài liệu cửa hàng (icon, ảnh, video, khai báo) |
| `site/` | Trang chính sách quyền riêng tư / điều khoản / hỗ trợ (GitHub Pages) |
