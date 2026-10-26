# Google Play — Mục "An toàn dữ liệu" (Data safety)

> Câu trả lời gợi ý dựa trên mã nguồn hiện tại (phiên bản 1.0.0). **Chủ ứng dụng phải rà lại** với nhà cung cấp
> AI thật sự dùng ở bản phát hành (DeepSeek trực tiếp hay qua máy chủ trung gian) và với việc có bật Firebase hay không.
> Cập nhật file này mỗi khi thay đổi SDK hoặc luồng dữ liệu.

## 1. Tổng quan
| Câu hỏi | Trả lời |
|---|---|
| Ứng dụng có thu thập hoặc chia sẻ loại dữ liệu người dùng bắt buộc nào không? | **Có** (nội dung người dùng gửi tới dịch vụ AI) |
| Mọi dữ liệu người dùng được mã hóa khi truyền? | **Có** (HTTPS) |
| Ứng dụng có cho phép tạo tài khoản? | **Không** → mục "Xóa tài khoản" không áp dụng |
| Người dùng có thể yêu cầu xóa dữ liệu? | Dữ liệu nằm trên thiết bị; xóa bằng gỡ app/xóa dữ liệu app. Nhà phát triển không lưu bản sao. |

## 2. Loại dữ liệu
| Loại dữ liệu | Thu thập? | Chia sẻ? | Mục đích | Bắt buộc/tùy chọn | Ghi chú |
|---|---|---|---|---|---|
| Nội dung người dùng khác (Other user-generated content): tên chủ đề, văn bản nhờ AI tóm tắt, câu trả lời nhờ AI chấm | Có (truyền khỏi thiết bị) | **Không** (bên xử lý AI là nhà cung cấp dịch vụ làm việc thay mặt nhà phát triển) — nếu dùng khóa API riêng của người dùng thì dữ liệu gửi thẳng nhà cung cấp theo yêu cầu của chính người dùng | Chức năng ứng dụng | Tùy chọn (chỉ khi dùng tính năng AI) | Không lưu ở máy chủ của nhà phát triển |
| Mã định danh thiết bị hoặc mã khác — FCM token | **Chỉ khi bản phát hành bật Firebase Cloud Messaging** (hiện chưa cấu hình `google-services.json` ⇒ không thu thập). Nếu bật: Có | Không | Chức năng ứng dụng (thông báo) | Tùy chọn | Nếu không dùng push từ xa, nên gỡ `firebase_*` khỏi `pubspec.yaml` để khai báo "không thu thập" |
| Vị trí, danh bạ, tin nhắn, ảnh/video đã lưu, lịch, sức khỏe, tài chính | **Không** | — | — | — | Ảnh/PDF chỉ đọc cục bộ để trích văn bản (OCR chạy trên máy) |
| Âm thanh | Không gửi tới nhà phát triển. Nhập giọng nói dùng dịch vụ nhận dạng của hệ điều hành | — | — | Tùy chọn | Khai báo quyền RECORD_AUDIO trong mục quyền |
| Hoạt động trong ứng dụng, thông tin web, phân tích, chẩn đoán/sự cố | **Không** (không có SDK phân tích/crash) | — | — | — | |

## 3. Thực hành bảo mật
- Dữ liệu được mã hóa khi truyền: **Có**.
- Bạn đã cam kết tuân thủ chính sách Gia đình của Play: **Không áp dụng** (không nhắm tới trẻ em).
- Đã được xác thực độc lập (MASA): **Không**.

## 4. Chính sách quyền riêng tư
URL: `<SITE_URL>/privacy/` (xem `site/privacy/index.html`, đăng bằng `.github/workflows/pages.yml`).

## 5. Khai báo bổ sung bắt buộc của Play
- **Nội dung do AI tạo (Generative AI policy)**: ứng dụng tạo văn bản bằng AI ⇒ cần cơ chế người dùng **báo cáo nội dung** không phù hợp/sai.
  Đã có: nút "Báo nội dung" trong màn đọc mẩu (xem `lib/features/courses/course_reader_screen.dart`).
- **Quyền nhạy cảm**: không dùng quyền SMS/Call log/Vị trí nền/Đọc toàn bộ ảnh.
- **Báo thức chính xác** (`SCHEDULE_EXACT_ALARM`): lý do khai báo — "Nhắc đọc kiến thức đúng giờ người dùng đặt (chức năng cốt lõi)".
  Nếu Play yêu cầu, chọn danh mục "Lời nhắc/Tổ chức công việc của người dùng". Nếu bị từ chối, bỏ quyền này: ứng dụng tự lùi về báo thức không chính xác (`canScheduleExactNotifications`).
