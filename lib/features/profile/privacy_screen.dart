import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_card.dart';

/// Quyền riêng tư & điều khoản — bản đọc trong app (offline). Bản đầy đủ có
/// địa chỉ công khai trong `site/privacy/` (đăng lên GitHub Pages cho cửa hàng).
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const List<(String, String)> _sections = <(String, String)>[
    (
      'Dữ liệu ở trên máy bạn',
      'Kiến thức, đề cương khóa học, tiến độ, thẻ ôn và cài đặt được lưu '
          'ngay trên thiết bị. MindKeeper không có tài khoản, không quảng cáo '
          'và không dùng công cụ theo dõi của bên thứ ba. Gỡ ứng dụng hoặc xóa '
          'dữ liệu ứng dụng sẽ xóa toàn bộ.',
    ),
    (
      'Khi dùng AI',
      'Tên chủ đề, cấp độ, tiêu đề mẩu, văn bản bạn nhờ AI tóm tắt và câu trả '
          'lời bạn nhờ AI chấm được gửi tới dịch vụ AI đã cấu hình để nhận kết '
          'quả. Đừng nhập thông tin nhạy cảm (mật khẩu, số thẻ, hồ sơ y tế).',
    ),
    (
      'Các tính năng khác',
      'Nhập từ link: tải đúng trang bạn nhập. Nhập giọng nói: dùng dịch vụ '
          'nhận dạng giọng nói của hệ điều hành. OCR ảnh và đọc PDF chạy trên '
          'thiết bị.',
    ),
    (
      'Nội dung AI chưa kiểm chứng',
      'Nội dung do AI soạn có thể sai hoặc lỗi thời và được gắn nhãn “Chưa '
          'kiểm chứng”. Đây là tài liệu học tập, không phải lời khuyên y tế, '
          'pháp lý hay tài chính.',
    ),
    (
      'Quyền truy cập',
      'Thông báo và báo thức chính xác (nhắc đọc/ôn đúng giờ), micro (tùy '
          'chọn), camera/ảnh/tệp (tùy chọn), internet (gọi AI, tải trang).',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Quyền riêng tư & điều khoản')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          Text(
            'MindKeeper tôn trọng dữ liệu của bạn: mọi thứ ở trên máy, chỉ '
            'gửi đi khi bạn dùng tính năng cần mạng.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final (String, String) s in _sections)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(s.$1, style: text.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      s.$2,
                      style: text.bodyMedium?.copyWith(
                        color: context.appColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Text(
            'Chính sách đầy đủ và điều khoản sử dụng có trên trang web của '
            'ứng dụng (mục Quyền riêng tư).',
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}
