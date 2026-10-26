# App Store Connect — App Privacy ("nhãn dinh dưỡng") & thông tin phát hành

> Gợi ý theo mã nguồn 1.0.0. Chủ ứng dụng rà lại với nhà cung cấp AI thực tế.

## App Privacy
| Mục | Trả lời |
|---|---|
| Có thu thập dữ liệu từ ứng dụng? | **Có** — chỉ nội dung người dùng gửi cho AI |
| Loại dữ liệu | **User Content → Other User Content** |
| Dùng để | App Functionality |
| Liên kết với danh tính người dùng? | **Không** (không có tài khoản/ID) |
| Dùng để theo dõi (Tracking)? | **Không** |
| Các loại khác (Contact Info, Health, Location, Identifiers, Usage Data, Diagnostics…) | **Không thu thập** |
| Nếu bật Firebase Cloud Messaging ở bản phát hành | Thêm **Identifiers → Device ID** (FCM token), App Functionality, không liên kết, không theo dõi |

URL chính sách quyền riêng tư: `<SITE_URL>/privacy/`.

## Thông tin phiên bản
- Tên: `MindKeeper: Học và ôn mỗi ngày` — Bundle ID: `com.mindkeeper.mindKeeper`
- Danh mục chính: Education; phụ: Productivity
- Phân loại độ tuổi: **4+** (không nội dung nhạy cảm; trả lời "Không" cho mọi câu hỏi của bảng câu hỏi)
  - Lưu ý: ứng dụng dùng AI tạo văn bản ⇒ chọn "Không" cho "Unrestricted web access" (ứng dụng chỉ tải link người dùng nhập, không phải trình duyệt).
- Bản quyền: `© <NĂM> <TÊN NHÀ PHÁT TRIỂN>`
- Giá: Miễn phí. Không mua trong ứng dụng.
- Thông tin xuất khẩu (Encryption): ứng dụng chỉ dùng HTTPS tiêu chuẩn ⇒ `ITSAppUsesNonExemptEncryption = NO` (đặt trong `ios/Runner/Info.plist` nếu chưa có).
- Review notes cho Apple: nêu rõ ứng dụng không cần tài khoản; tính năng AI cần mạng; cung cấp khóa/đường dẫn AI demo nếu bản phát hành yêu cầu.

## Ảnh & video
- iPhone 6.7": `store/screenshots/ios_6.7/` (1290×2796) — bắt buộc
- iPhone 6.5": `store/screenshots/ios_6.5/` (1284×2778)
- iPhone 5.5": `store/screenshots/ios_5.5/` (1242×2208)
- iPad 12.9": `store/screenshots/ipad_12.9/` (2048×2732) — chỉ bắt buộc nếu bản build hỗ trợ iPad
- App Preview: `store/video/app_preview_886x1920.mp4` (18,6 giây; Apple yêu cầu 15–30 giây, H.264, tối đa 500 MB)
- Icon: `store/appstore/icon_1024.png` (không trong suốt)
