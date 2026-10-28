import '../../core/services/preferences_service.dart';
import '../../data/models/topic.dart';
import '../../data/repositories/topic_repository.dart';
import '../discover/discovery_catalog.dart';
import '../discover/discovery_service.dart';

/// Logic onboarding lần đầu: nhận biết người dùng cũ + tạo sẵn nội dung OFFLINE.
///
/// Không gọi AI: nội dung mẫu lấy từ [DiscoveryCatalog] (biên soạn sẵn) và lưu
/// qua [DiscoveryService.saveEntry] (chủ đề + kiến thức + thẻ ôn FSRS due ngay).
class OnboardingService {
  OnboardingService({
    required this.topics,
    required this.discovery,
    required this.prefs,
  });

  final TopicRepository topics;
  final DiscoveryService discovery;
  final PreferencesService prefs;

  static const int minCategories = 2;
  static const int maxCategories = 3;

  /// DB đã có dữ liệu (người dùng cũ) → coi như đã onboarding, không chặn.
  Future<bool> hasExistingData() async {
    final List<Topic> all = await topics.list(activeOnly: false, limit: 1);
    return all.isNotEmpty;
  }

  /// Quyết định có cần hiển thị onboarding không; tự đánh dấu hoàn tất cho
  /// người dùng cũ để lần sau không phải kiểm tra lại.
  Future<bool> shouldShow() async {
    if (prefs.onboardingCompleted) return false;
    if (await hasExistingData()) {
      await prefs.setOnboardingCompleted(true);
      return false;
    }
    return true;
  }

  /// Entry đầu tiên của [category] chưa được lưu (theo mô tả `catalog:<id>`).
  static DiscoveryEntry? pickEntry(
    String category,
    Set<String> savedCatalogIds,
  ) {
    for (final DiscoveryEntry entry in DiscoveryCatalog.byCategory(category)) {
      if (!savedCatalogIds.contains(entry.id)) return entry;
    }
    return null;
  }

  /// Tạo sẵn nội dung cho các [categories] (tối đa [maxCategories], mỗi chủ đề
  /// 1 entry). Bỏ qua chủ đề đã tồn tại → gọi lại không nhân bản dữ liệu.
  Future<List<Topic>> seedFor(List<String> categories) async {
    final List<Topic> existing = await topics.list(
      activeOnly: false,
      limit: 1000,
    );
    final Set<String> saved = <String>{
      for (final Topic t in existing)
        if (t.description.startsWith('catalog:'))
          t.description.substring('catalog:'.length),
    };
    final List<Topic> created = <Topic>[];
    for (final String category in categories.take(maxCategories)) {
      final DiscoveryEntry? entry = pickEntry(category, saved);
      if (entry == null) continue;
      created.add(await discovery.saveEntry(entry));
      saved.add(entry.id);
    }
    return created;
  }

  /// Lưu lựa chọn người dùng (không seed): cấp độ mặc định, giờ nhắc, bật nhắc.
  Future<void> savePreferences({
    required String courseLevelId,
    required int reminderHour,
    required int reminderMinute,
    required bool notificationsEnabled,
  }) async {
    await prefs.setDefaultCourseLevel(courseLevelId);
    await prefs.setReminderTime(hour: reminderHour, minute: reminderMinute);
    await prefs.setNotificationsEnabled(notificationsEnabled);
  }
}
