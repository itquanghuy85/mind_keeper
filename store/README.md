# store/ — tài sản và tài liệu đăng cửa hàng

```
store/
├─ listing/                  # nội dung trang (vi-VN, en-US) — nguồn duy nhất
├─ play/                     # icon 512, ảnh bìa, khai báo, an toàn dữ liệu
├─ appstore/                 # icon 1024, nhãn quyền riêng tư
├─ screenshots/              # khung tiếp thị (android_phone, ios_6.7/6.5/5.5, ipad_12.9)
├─ raw_screenshots/          # ảnh chụp thật từ thiết bị (nguồn của khung tiếp thị)
├─ video/                    # video giới thiệu + frames nguồn
└─ RELEASE_CHECKLIST.md      # danh sách đánh dấu
```

Hướng dẫn cho AI Agent: `DOCS/STORE_AGENT_GUIDE.md`.

## Dựng lại tài sản

| Việc | Lệnh |
|---|---|
| Icon, logo splash, ảnh bìa, khung ảnh chụp, khung video | `flutter test tool/brand/render_brand_test.dart --dart-define=BRAND_OUT=<đường dẫn dự án>` |
| Áp icon vào Android/iOS | `dart run flutter_launcher_icons` |
| Ảnh chụp thật từ máy | Build APK với mock AI (`tool/mock_ai_server.js`), gieo dữ liệu mẫu, chạy `OUT_DIR=<dir> bash maestro/gd23/run.sh <serial> 05_store_screenshots`, chép các `takeScreenshot/*.png` vào `store/raw_screenshots/` |
| Video giới thiệu | `bash tool/brand/make_preview_video.sh` (cần ffmpeg) |
| Kiểm ký tự nội dung trang | `bash tool/store/check_listing.sh` |
| Cây fastlane | `SITE_URL=<url> bash tool/store/prepare_fastlane.sh` |
| Site chính sách | `CONTACT_EMAIL=… DEVELOPER_NAME=… bash tool/site/build_site.sh` |

Màu/nhận diện nằm ở `lib/core/widgets/brand_mark.dart` (`BrandColors`, `BrandMarkPainter`) — sửa một nơi, sinh lại mọi tài sản.
Ghi chú: `flutter test` trên Windows có thể khóa `build/native_assets/.../sqlite3.dll` nếu còn tiến trình `flutter_tester` treo;
khi đó chạy từ một bản sao dự án (lib, test, tool, assets, pubspec) ở thư mục tạm.
