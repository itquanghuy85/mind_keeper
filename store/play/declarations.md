# Google Play — Khai báo ứng dụng (App content) & thiết lập trang

> Tất cả mục dưới đây do Play Console yêu cầu trước khi phát hành. "Trả lời gợi ý" dựa trên mã nguồn 1.0.0.

| Mục trong Play Console | Trả lời gợi ý |
|---|---|
| Chính sách quyền riêng tư | `<SITE_URL>/privacy/` |
| Quảng cáo | **Không chứa quảng cáo** |
| Quyền truy cập ứng dụng | Toàn bộ chức năng dùng được không cần đăng nhập/mã đặc biệt |
| Đối tượng mục tiêu & nội dung | Nhóm tuổi **13+** (hoặc 18+ nếu muốn thận trọng). **Không** hướng tới trẻ em |
| Ứng dụng tin tức | Không |
| Ứng dụng theo dõi COVID-19 / chính phủ / tài chính / sức khỏe | Không (nội dung sức khỏe chỉ mang tính tham khảo giáo dục, có tuyên bố miễn trừ) |
| An toàn dữ liệu | Xem `store/play/data_safety.md` |
| Xóa tài khoản | Không có tài khoản |
| Đánh giá nội dung (IARC) | Danh mục "Tham khảo, tin tức hoặc giáo dục". Trả lời **Không** cho bạo lực, nội dung người lớn, cờ bạc, ma túy, chia sẻ vị trí, mua hàng, nội dung người dùng tạo ra công khai. Kết quả mong đợi: PEGI 3 / ESRB Everyone |
| Nội dung do AI tạo | Có. Cơ chế báo cáo: nút "Báo nội dung" trong màn đọc mẩu |
| Khai báo dịch vụ nền / quyền đặc biệt | `SCHEDULE_EXACT_ALARM` (lời nhắc), `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` (khôi phục lịch nhắc sau khi khởi động lại), `RECORD_AUDIO` (nhập giọng nói, tùy chọn) |
| Danh mục & thẻ | Giáo dục; thẻ gợi ý: Học tập, Ghi nhớ |
| Chi tiết liên hệ | Email công khai (cùng email trên trang chính sách), website `<SITE_URL>/` |
| Quốc gia phân phối | Việt Nam (có thể thêm sau) |
| Giá | Miễn phí |

## Tài sản đồ họa (trang cửa hàng chính)
| Tài sản | Tệp | Yêu cầu |
|---|---|---|
| Icon ứng dụng | `store/play/icon_512.png` | PNG 512×512, ≤ 1 MB |
| Ảnh bìa (Feature graphic) | `store/play/feature_graphic_1024x500.png` | 1024×500 |
| Ảnh chụp màn hình điện thoại | `store/screenshots/android_phone/*.png` | 1080×1920, 5 ảnh (2–8 ảnh, mỗi cạnh 320–3840 px, tỷ lệ ≤ 2:1) |
| Video giới thiệu | `store/video/app_preview_1080x1920.mp4` | Play chỉ nhận **URL YouTube**: tải tệp lên YouTube (không công khai/không niêm yết) rồi dán link |

## Bản build
- `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`
- Ký bằng **upload key** (xem `store/RELEASE_CHECKLIST.md`) và bật Play App Signing.
- `versionCode` tăng mỗi lần tải lên (lấy từ `version: x.y.z+N` trong `pubspec.yaml`).
- Với tài khoản cá nhân mới: bắt buộc **closed testing ≥ 12 người thử trong ≥ 14 ngày** trước khi đăng Production.
