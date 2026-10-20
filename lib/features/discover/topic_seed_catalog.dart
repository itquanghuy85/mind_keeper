/// Một gợi ý chủ đề offline kèm mô tả tiếng Việt.
///
/// Dùng khi AI thật không khả dụng (mock / fallback) để người dùng vẫn có
/// danh sách chủ đề **đọc được, có dấu đầy đủ và khác nhau về nội dung**.
class TopicSeed {
  const TopicSeed(this.title, this.description);

  final String title;
  final String description;
}

/// Catalog chủ đề tiếng Việt theo tên lĩnh vực.
///
/// Mỗi lĩnh vực có đủ 20 chủ đề khác nhau về nội dung. Nội dung ở đây là
/// dữ liệu biên soạn sẵn (không phải AI sinh) — dùng làm fallback hợp lệ.
abstract final class TopicSeedCatalog {
  static const Map<String, List<TopicSeed>> byDomain =
      <String, List<TopicSeed>>{
        'Khoa học': <TopicSeed>[
          TopicSeed(
            'Nguyên tử và phân tử',
            'Cấu trúc nguyên tử và cách các phân tử liên kết thành vật chất.',
          ),
          TopicSeed(
            'Thuyết tiến hóa',
            'Cơ chế chọn lọc tự nhiên giải thích sự đa dạng của sự sống.',
          ),
          TopicSeed(
            'Vũ trụ và các thiên hà',
            'Cấu trúc vũ trụ, dải thiên hà và những gì quan sát được.',
          ),
          TopicSeed(
            'Quang học trong đời sống',
            'Ánh sáng, thị giác và ứng dụng của hiện tượng quang học.',
          ),
          TopicSeed(
            'Hóa học hữu cơ cơ bản',
            'Cấu trúc phân tử hữu cơ và các phản ứng thường gặp.',
          ),
          TopicSeed(
            'Cơ chế vận động cơ bản',
            'Hệ xương, cơ và cách cơ thể tạo chuyển động.',
          ),
          TopicSeed(
            'Hệ điều dưỡng và trao đổi chất',
            'Cách cơ thể hấp thu và chuyển hóa năng lượng.',
          ),
          TopicSeed(
            'Trái đất và các lớp địa lý',
            'Vỏ Trái đất, kiến tạo và những lớp đất đá.',
          ),
          TopicSeed(
            'Năng lượng và vật lý hiện đại',
            'Cơ sở của điện tử lượng tử và vật lý hạt.',
          ),
          TopicSeed(
            'Khí hậu và hệ sinh thái',
            'Mối liên hệ giữa khí hậu, đất và các hệ sinh thái.',
          ),
          TopicSeed(
            'Âm thanh và sóng cơ',
            'Cách sóng âm truyền trong không khí và trong vật liệu.',
          ),
          TopicSeed(
            'Điện tử và mạch điện',
            'Dòng điện, mạch điện và cách tín hiệu được truyền tải.',
          ),
          TopicSeed(
            'Nghiên cứu khoa học đúng cách',
            'Thiết kế giả thuyết, đối chứng và kiểm chứng kết quả.',
          ),
          TopicSeed(
            'Toán học trong đời sống',
            'Ứng dụng xác suất, thống kê và hình học vào bài toán thực.',
          ),
          TopicSeed(
            'Sinh học tế bào',
            'Cấu trúc tế bào và các quá trình trao đổi chất cơ bản.',
          ),
          TopicSeed(
            'Tính chất vật liệu',
            'Cấu trúc vật liệu quyết định tính chất và ứng dụng của nó.',
          ),
          TopicSeed(
            'Địa chất và khoáng sản',
            'Quá trình hình thành đá và khoáng sản trong lòng đất.',
          ),
          TopicSeed(
            'Công nghệ sinh học',
            'Ứng dụng sinh học trong y tế, nông nghiệp và công nghiệp.',
          ),
          TopicSeed(
            'Vũ trụ học quan sát',
            'Cách dùng kính viễn thị và tín hiệu vô tuyến để quan sát vũ trụ.',
          ),
          TopicSeed(
            'Bảo tồn đa dạng sinh học',
            'Cách bảo vệ các loài và hệ sinh thái trước suy thoái.',
          ),
        ],
      };

  /// Các góc nhìn dùng để mở rộng một chủ đề mẫu thành nhiều chủ đề khác nhau
  /// về **nội dung** (không chỉ khác số thứ tự).
  static const List<({String suffix, String angle})> _angles =
      <({String suffix, String angle})>[
        (suffix: ' — nguyên lý cốt lõi', angle: 'nguyên lý nền tảng'),
        (suffix: ' — lịch sử phát triển', angle: 'quá trình hình thành'),
        (suffix: ' — ứng dụng thực tiễn', angle: 'ứng dụng đời sống'),
        (suffix: ' — thách thức và giới hạn', angle: 'giới hạn và thách thức'),
        (suffix: ' — góc nhìn liên ngành', angle: 'liên hệ liên ngành'),
      ];

  /// Sinh danh sách chủ đề tiếng Việt cho một lĩnh vực.
  ///
  /// Ưu tiên catalog biên soạn sẵn; lĩnh vực chưa có catalog thì mở rộng từ
  /// các chủ đề mẫu theo nhiều góc nhìn để vẫn đủ [count] chủ đề khác nhau.
  static List<TopicSeed> forDomain(
    String domainName,
    List<String> sampleTopics, {
    int count = 20,
  }) {
    final int total = count < 1 ? 1 : (count > 40 ? 40 : count);
    final List<TopicSeed> seeds = <TopicSeed>[];
    final Set<String> seen = <String>{};

    void add(TopicSeed seed) {
      if (seeds.length >= total) return;
      if (!seen.add(seed.title.trim().toLowerCase())) return;
      seeds.add(seed);
    }

    for (final TopicSeed seed in byDomain[domainName] ?? const <TopicSeed>[]) {
      add(seed);
      if (seeds.length >= total) break;
    }

    final List<String> bases = sampleTopics.isEmpty
        ? <String>[domainName]
        : sampleTopics;
    for (final String base in bases) {
      for (final ({String suffix, String angle}) angle in _angles) {
        if (seeds.length >= total) break;
        add(
          TopicSeed(
            '$base${angle.suffix}',
            'Góc nhìn ${angle.angle} của "$base" trong lĩnh vực $domainName.',
          ),
        );
      }
      if (seeds.length >= total) break;
    }

    // Bổ sung tối thiểu cho lĩnh vực không có chủ đề mẫu nào.
    for (int i = 0; i < total && seeds.length < total; i++) {
      add(
        TopicSeed(
          '$domainName — chủ đề $i',
          'Chủ đề $i trong lĩnh vực $domainName, trình bày bằng tiếng Việt.',
        ),
      );
    }
    return seeds;
  }
}
