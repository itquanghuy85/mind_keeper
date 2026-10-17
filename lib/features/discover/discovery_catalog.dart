import '../../data/models/enums.dart';

/// Mục trong danh mục khám phá offline (nội dung mẫu đã biên soạn, không phải AI sinh).
class DiscoveryEntry {
  const DiscoveryEntry({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.minutes,
    required this.items,
  });

  final String id;
  final String category;
  final String title;
  final String description;
  final int minutes;
  final List<DiscoveryKnowledge> items;
}

class DiscoveryKnowledge {
  const DiscoveryKnowledge({
    required this.title,
    required this.content,
    this.question = '',
    this.answer = '',
  });

  final String title;
  final String content;
  final String question;
  final String answer;
}

/// Danh mục khám phá — nguồn biên soạn offline, đánh dấu origin = discovered.
abstract final class DiscoveryCatalog {
  static const List<String> categories = <String>[
    'Khoa học',
    'Lịch sử',
    'Tâm lý',
    'Công nghệ',
    'Địa lý',
    'Kinh doanh',
    'Ngoại ngữ',
    'Đời sống',
  ];

  static const List<DiscoveryEntry> entries = <DiscoveryEntry>[
    DiscoveryEntry(
      id: 'disc_memory_curve',
      category: 'Tâm lý',
      title: 'Vì sao chúng ta hay quên?',
      description: 'Khám phá đường cong lãng quên của Ebbinghaus.',
      minutes: 3,
      items: <DiscoveryKnowledge>[
        DiscoveryKnowledge(
          title: 'Đường cong lãng quên',
          content:
              'Ebbinghaus phát hiện trí nhớ giảm rất nhanh trong những ngày đầu, sau đó ổn định hơn nếu được ôn lại đúng thời điểm.',
          question: 'Đường cong lãng mô tả điều gì?',
          answer:
              'Mức độ quên thông tin theo thời gian: giảm nhanh ban đầu rồi chậm lại.',
        ),
        DiscoveryKnowledge(
          title: 'Ôn tập ngắt quãng',
          content:
              'Ôn lại sau các khoảng cách ngày giúp củng cố trí nhớ lâu dài hơn ôn dồn dập trong một buổi.',
          question: 'Ôn tập ngắt quãng là gì?',
          answer:
              'Ôn lại sau các khoảng cách ngày giúp củng cố trí nhớ lâu dài hơn.',
        ),
      ],
    ),
    DiscoveryEntry(
      id: 'disc_space',
      category: 'Khoa học',
      title: 'Vũ trụ có bao nhiêu hành tinh?',
      description: 'Hệ Mặt Trời và các ngoại hành tinh.',
      minutes: 3,
      items: <DiscoveryKnowledge>[
        DiscoveryKnowledge(
          title: 'Hệ Mặt Trời',
          content:
              'Hệ Mặt Trời có 8 hành tinh: Thủy, Kim, Trái Đất, Hỏa, Mộc, Thổ, Thiên Vương, Hải Vương.',
          question: 'Hệ Mặt Trời có mấy hành tinh?',
          answer: '8 hành tinh.',
        ),
        DiscoveryKnowledge(
          title: 'Ngoại hành tinh',
          content:
              'Ngoại hành tinh là hành tinh nằm ngoài hệ Mặt Trời, quay quanh một ngôi sao khác; hàng nghìn đã được phát hiện.',
          question: 'Ngoại hành tinh là gì?',
          answer: 'Hành tinh ngoài hệ Mặt Trời quay quanh sao khác.',
        ),
      ],
    ),
    DiscoveryEntry(
      id: 'disc_printing',
      category: 'Lịch sử',
      title: 'Một phát minh thay đổi thế giới',
      description: 'Máy in của Gutenberg và cách lan tỏa tri thức.',
      minutes: 3,
      items: <DiscoveryKnowledge>[
        DiscoveryKnowledge(
          title: 'Máy in chữ rời',
          content:
              'Khoảng 1440, Johannes Gutenberg chế tạo máy in chữ rời, giúp sách được sản xuất hàng loạt và tri thức lan tỏa nhanh.',
          question: 'Ai phát minh máy in chữ rời?',
          answer: 'Johannes Gutenberg, khoảng năm 1440.',
        ),
      ],
    ),
    DiscoveryEntry(
      id: 'disc_ai',
      category: 'Công nghệ',
      title: 'Công nghệ AI đang thay đổi gì?',
      description: 'AI hoạt động cơ bản và ứng dụng hằng ngày.',
      minutes: 3,
      items: <DiscoveryKnowledge>[
        DiscoveryKnowledge(
          title: 'AI là gì?',
          content:
              'Trí tuệ nhân tạo là hệ thống máy mô phỏng khả năng học và suy luận của con người để xử lý ngôn ngữ, hình ảnh, dữ liệu.',
          question: 'AI viết tắt của gì?',
          answer: 'Artificial Intelligence — Trí tuệ nhân tạo.',
        ),
        DiscoveryKnowledge(
          title: 'AI và công việc',
          content:
              'AI hỗ trợ dịch thuật, tóm tắt, gợi ý và phân tích dữ liệu, nhưng vẫn cần con người kiểm chứng kết quả quan trọng.',
          question: 'Vì sao cần kiểm chứng kết quả AI?',
          answer: 'AI có thể sai; kết quả quan trọng cần người xác nhận.',
        ),
      ],
    ),
    DiscoveryEntry(
      id: 'disc_world',
      category: 'Địa lý',
      title: 'Địa lý thế giới',
      description: 'Những địa danh và hiện tượng nổi bật.',
      minutes: 3,
      items: <DiscoveryKnowledge>[
        DiscoveryKnowledge(
          title: 'Sông dài nhất thế giới',
          content:
              'Sông Nile được coi là sông dài nhất thế giới, chảy qua Bắc Phi và đổ vào Địa Trung Hải.',
          question: 'Sông nào dài nhất thế giới?',
          answer: 'Sông Nile.',
        ),
        DiscoveryKnowledge(
          title: 'Dãy núi Himalaya',
          content:
              'Himalaya là dãy núi cao nhất thế giới, chứa đỉnh Everest cao khoảng 8.849 m.',
          question: 'Đỉnh núi cao nhất thế giới?',
          answer: 'Everest, khoảng 8.849 m.',
        ),
      ],
    ),
    DiscoveryEntry(
      id: 'disc_habits',
      category: 'Tâm lý',
      title: 'Thói quen thành công',
      description: 'Cách thói quen nhỏ tạo thay đổi lớn.',
      minutes: 3,
      items: <DiscoveryKnowledge>[
        DiscoveryKnowledge(
          title: 'Quy luật 1%',
          content:
              'Cải thiện 1% mỗi ngày giúp tiến bộ đáng kể sau một năm nhờ sức mạnh của sự tích lũy nhỏ.',
          question: 'Quy luật 1% nói về điều gì?',
          answer: 'Cải thiện nhỏ mỗi ngày tạo tiến bộ lớn theo thời gian.',
        ),
      ],
    ),
    DiscoveryEntry(
      id: 'disc_business',
      category: 'Kinh doanh',
      title: 'Hiểu biết nền tảng về kinh doanh',
      description: 'Doanh thu, lợi nhuận và khách hàng.',
      minutes: 3,
      items: <DiscoveryKnowledge>[
        DiscoveryKnowledge(
          title: 'Doanh thu và lợi nhuận',
          content:
              'Doanh thu là tổng tiền thu được; lợi nhuận là doanh thu trừ đi chi phí. Doanh thu cao không đồng nghĩa lợi nhuận cao.',
          question: 'Lợi nhuận được tính thế nào?',
          answer: 'Doanh thu trừ đi chi phí.',
        ),
      ],
    ),
    DiscoveryEntry(
      id: 'disc_language',
      category: 'Ngoại ngữ',
      title: 'Mẹo học từ vựng hiệu quả',
      description: 'Ghi nhớ từ mới bằng liên kết ngữ cảnh.',
      minutes: 2,
      items: <DiscoveryKnowledge>[
        DiscoveryKnowledge(
          title: 'Học theo cụm từ',
          content:
              'Học từ mới trong cụm từ hoặc câu ví dụ giúp nhớ lâu hơn học riêng lẻ từng từ.',
          question: 'Vì sao nên học từ theo cụm?',
          answer: 'Ngữ cảnh giúp gắn kết và dễ gợi nhớ từ.',
        ),
      ],
    ),
    DiscoveryEntry(
      id: 'disc_life',
      category: 'Đời sống',
      title: 'Ngủ và sức khỏe',
      description: 'Vai trò của giấc ngủ với trí nhớ.',
      minutes: 2,
      items: <DiscoveryKnowledge>[
        DiscoveryKnowledge(
          title: 'Giấc ngủ củng cố trí nhớ',
          content:
              'Não củng cố ký ức trong khi ngủ; thiếu ngủ làm giảm khả năng ghi nhớ và tập trung.',
          question: 'Giấc ngủ ảnh hưởng trí nhớ thế nào?',
          answer: 'Giúp củng cố ký ức; thiếu ngủ làm giảm ghi nhớ.',
        ),
      ],
    ),
    DiscoveryEntry(
      id: 'disc_photosynthesis',
      category: 'Khoa học',
      title: 'Quang hợp là gì?',
      description: 'Cách cây xanh tạo năng lượng.',
      minutes: 2,
      items: <DiscoveryKnowledge>[
        DiscoveryKnowledge(
          title: 'Quang hợp',
          content:
              'Quang hợp là quá trình cây dùng ánh sáng mặt trời để biến CO₂ và nước thành đường và thải oxy.',
          question: 'Quang hợp tạo ra chất gì?',
          answer: 'Đường (glucose) và oxy.',
        ),
      ],
    ),
    DiscoveryEntry(
      id: 'disc_ww2',
      category: 'Lịch sử',
      title: 'Tóm tắt Thế chiến II',
      description: 'Các mốc chính của cuộc chiến.',
      minutes: 4,
      items: <DiscoveryKnowledge>[
        DiscoveryKnowledge(
          title: 'Thời gian và phe tham chiến',
          content:
              'Thế chiến II (1939–1945) gồm phe Đồng Minh và phe Trục; kết thúc sau khi Đức và Nhật đầu hàng.',
          question: 'Thế chiến II kéo dài từ năm nào đến năm nào?',
          answer: '1939 đến 1945.',
        ),
      ],
    ),
    DiscoveryEntry(
      id: 'disc_net',
      category: 'Công nghệ',
      title: 'Internet hoạt động ra sao?',
      description: 'Giao thức và dữ liệu trên mạng.',
      minutes: 3,
      items: <DiscoveryKnowledge>[
        DiscoveryKnowledge(
          title: 'Giao thức TCP/IP',
          content:
              'Internet truyền dữ liệu bằng cách chia thành các gói tin và định tuyến qua nhiều máy trung gian theo giao thức TCP/IP.',
          question: 'Internet chia dữ liệu thành gì?',
          answer: 'Các gói tin (packets).',
        ),
      ],
    ),
  ];

  static List<DiscoveryEntry> byCategory(String category) => entries
      .where((DiscoveryEntry e) => e.category == category)
      .toList(growable: false);

  static DiscoveryEntry? byId(String id) {
    for (final DiscoveryEntry e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  static TopicOrigin get origin => TopicOrigin.discovered;
}
