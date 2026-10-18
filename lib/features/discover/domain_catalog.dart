import 'package:flutter/material.dart';

/// Một lĩnh vực khám phá kiến thức trong danh mục 20 lĩnh vực.
class LearningDomain {
  const LearningDomain({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.sampleTopics,
    this.isHealth = false,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;

  /// Chủ đề mẫu để "chủ đề ngẫu nhiên" không bị lặp vô vị.
  final List<String> sampleTopics;

  /// Lĩnh vực liên quan y tế → bài học bắt buộc kèm disclaimer.
  final bool isHealth;

  String randomTopic() {
    if (sampleTopics.isEmpty) return name;
    final int index =
        DateTime.now().microsecondsSinceEpoch % sampleTopics.length;
    return sampleTopics[index];
  }
}

/// Danh mục 20 lĩnh vực khám phá kiến thức.
abstract final class LearningDomains {
  static const List<LearningDomain> all = <LearningDomain>[
    LearningDomain(
      id: 'science',
      name: 'Khoa học',
      description: 'Phép thực nghiệm, hiện tượng tự nhiên, vũ trụ.',
      icon: Icons.science,
      sampleTopics: <String>[
        'Vũ trụ và hệ Mặt Trời',
        'Nguyên tử và phân tử',
        'Thuyết tiến hóa',
        'Quang học trong đời sống',
      ],
    ),
    LearningDomain(
      id: 'technology',
      name: 'Công nghệ',
      description: 'Thiết bị, phần mềm và xu hướng số.',
      icon: Icons.computer,
      sampleTopics: <String>[
        'Trí tuệ nhân tạo',
        'Internet vạn vật',
        'Điện toán đám mây',
        'Robot trong sản xuất',
      ],
    ),
    LearningDomain(
      id: 'computing',
      name: 'Khoa học máy tính',
      description: 'Lập trình, dữ liệu, thuật toán, bảo mật.',
      icon: Icons.code,
      sampleTopics: <String>[
        'Thuật toán sắp xếp',
        'Cơ sở dữ liệu',
        'Bảo mật cơ bản',
        'Ứng dụng di động',
      ],
    ),
    LearningDomain(
      id: 'history',
      name: 'Lịch sử',
      description: 'Sự kiện, nhân vật và dòng thời gian.',
      icon: Icons.history_edu,
      sampleTopics: <String>[
        'Đại Việt thời Trần',
        'Thế chiến thứ hai',
        'Cách mạng công nghiệp',
        'Lịch sử chữ viết',
      ],
    ),
    LearningDomain(
      id: 'geography',
      name: 'Địa lý',
      description: 'Bản đồ, địa hình, khí hậu, vùng lãnh thổ.',
      icon: Icons.public,
      sampleTopics: <String>[
        'Địa lý Việt Nam',
        'Biến đổi khí hậu',
        'Dòng hải lưu',
        'Các châu lục',
      ],
    ),
    LearningDomain(
      id: 'psychology',
      name: 'Tâm lý học',
      description: 'Cảm xúc, hành vi và thói quen.',
      icon: Icons.psychology,
      sampleTopics: <String>[
        'Lo âu và cách quản lý',
        'Động lực học tập',
        'Ghi nhớ dài hạn',
        'Thói quen xấu',
      ],
    ),
    LearningDomain(
      id: 'education',
      name: 'Giáo dục',
      description: 'Phương pháp học, dạy và đánh giá.',
      icon: Icons.school,
      sampleTopics: <String>[
        'Học qua dự án',
        'Kỹ năng ghi chú',
        'Cấu trúc bài luận',
        'Thi cử và đánh giá',
      ],
    ),
    LearningDomain(
      id: 'business',
      name: 'Kinh doanh',
      description: 'Doanh nghiệp, quản trị và khởi nghiệp.',
      icon: Icons.business_center,
      sampleTopics: <String>[
        'Khởi nghiệp tinh gọn',
        'Quản trị dự án',
        'Thương hiệu cá nhân',
        'Mô hình kinh doanh',
      ],
    ),
    LearningDomain(
      id: 'finance',
      name: 'Tài chính',
      description: 'Tiền bạc, đầu tư và chi tiêu.',
      icon: Icons.account_balance_wallet,
      sampleTopics: <String>[
        'Quỹ dự phòng',
        'Đầu tư dài hạn',
        'Lạm phát và lãi suất',
        'Ngân sách cá nhân',
      ],
    ),
    LearningDomain(
      id: 'health',
      name: 'Sức khỏe',
      description: 'Giấc ngủ, bệnh phổ biến, chăm sóc cơ thể.',
      icon: Icons.favorite,
      isHealth: true,
      sampleTopics: <String>[
        'Giấc ngủ và phục hồi',
        'Bệnh cúm mùa',
        'Tập thể dục mỗi ngày',
        'Nước và cơ thể',
      ],
    ),
    LearningDomain(
      id: 'nutrition',
      name: 'Dinh dưỡng',
      description: 'Thực phẩm, khẩu phần, thói quen ăn uống.',
      icon: Icons.restaurant,
      isHealth: true,
      sampleTopics: <String>[
        'Cân bằng bữa ăn',
        'Protein thực vật',
        'Đường và sức khỏe',
        'Ăn đúng giờ',
      ],
    ),
    LearningDomain(
      id: 'sports',
      name: 'Thể thao',
      description: 'Bộ môn, kỹ thuật và rèn luyện.',
      icon: Icons.sports_soccer,
      sampleTopics: <String>[
        'Bóng đá phong trào',
        'Chạy bộ bền',
        'Yoga cơ bản',
        'Tinh thần thi đấu',
      ],
    ),
    LearningDomain(
      id: 'art',
      name: 'Nghệ thuật',
      description: 'Hội họa, âm nhạc, điện ảnh.',
      icon: Icons.palette,
      sampleTopics: <String>[
        'Tranh hiện đại',
        'Nhạc cụ dân tộc',
        'Điện ảnh thế giới',
        'Nghệ thuật đường phố',
      ],
    ),
    LearningDomain(
      id: 'literature',
      name: 'Văn học',
      description: 'Tác giả, tác phẩm và trào lưu.',
      icon: Icons.menu_book,
      sampleTopics: <String>[
        'Truyện ngắn hiện đại',
        'Thơ trung đại',
        'Tiểu thuyết trinh thám',
        'Văn học dân gian',
      ],
    ),
    LearningDomain(
      id: 'languages',
      name: 'Ngoại ngữ',
      description: 'Từ vựng, phát âm, văn hóa giao tiếp.',
      icon: Icons.translate,
      sampleTopics: <String>[
        'Tiếng Anh giao tiếp',
        'Hán tự cơ bản',
        'Tiếng Nhật đời thường',
        'Dịch thuật thực hành',
      ],
    ),
    LearningDomain(
      id: 'food',
      name: 'Ẩm thực',
      description: 'Món ăn và kỹ thuật chế biến.',
      icon: Icons.local_dining,
      sampleTopics: <String>[
        'Món ăn đường phố',
        'Nấu ăn cơ bản',
        'Gia vị Việt Nam',
        'Bánh truyền thống',
      ],
    ),
    LearningDomain(
      id: 'travel',
      name: 'Du lịch',
      description: 'Đi lại, chuẩn bị và văn hóa vùng miền.',
      icon: Icons.flight,
      sampleTopics: <String>[
        'Du lịch bụi',
        'Tìm vé máy bay rẻ',
        'Di sản UNESCO',
        'Chuẩn bị hành lý',
      ],
    ),
    LearningDomain(
      id: 'environment',
      name: 'Môi trường',
      description: 'Thiên nhiên, bảo tồn và bền vững.',
      icon: Icons.eco,
      sampleTopics: <String>[
        'Phân loại rác',
        'Rừng nhiệt đới',
        'Nước sạch',
        'Năng lượng tái tạo',
      ],
    ),
    LearningDomain(
      id: 'lifestyle',
      name: 'Đời sống',
      description: 'Tổ chức nhà cửa, thói quen, sở thích.',
      icon: Icons.home,
      sampleTopics: <String>[
        'Dọn dẹp tối giản',
        'Quản lý thời gian',
        'Sở thích cuối tuần',
        'Nuôi dưỡng mối quan hệ',
      ],
    ),
    LearningDomain(
      id: 'lifeskills',
      name: 'Kỹ năng sống',
      description: 'Giao tiếp, tư duy và nghề nghiệp.',
      icon: Icons.lightbulb,
      sampleTopics: <String>[
        'Nói trước đám đông',
        'Tư duy phản biện',
        'Viết email công việc',
        'Phỏng vấn xin việc',
      ],
    ),
  ];

  static LearningDomain? byId(String id) {
    for (final LearningDomain domain in all) {
      if (domain.id == id) return domain;
    }
    return null;
  }
}
