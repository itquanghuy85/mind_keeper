import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService extends ChangeNotifier {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyReminderHour = 'reminder_hour';
  static const String _keyReminderMinute = 'reminder_minute';
  static const String _keyDailyGoal = 'daily_goal';
  static const String _keyNewTopicsPerDay = 'new_topics_per_day';
  static const String _keyHiddenCategories = 'hidden_categories';
  static const String _keyFavoriteCategories = 'favorite_categories';
  static const String _keySessionCardIds = 'session_card_ids';
  static const String _keySessionIndex = 'session_index';
  static const String _keyAiBaseUrl = 'ai_base_url';
  static const String _keyAiApiKey = 'ai_api_key';
  static const String _keyAiModel = 'ai_model';
  static const String _keyAiProxyMode = 'ai_proxy_mode';

  /// Mặc định Base URL cho provider OpenAI-compatible khi chưa có giá trị lưu.
  static const String _defaultAiBaseUrl = 'https://api.openai.com/v1';

  /// Mặc định model khi chưa có giá trị lưu.
  static const String _defaultAiModel = 'gpt-4o-mini';
  static const String _keyLessonDefaultMode = 'lesson_default_mode';
  static const String _keyFavoriteDomains = 'favorite_domains';
  static const String _keyHiddenDomains = 'hidden_domains';
  // Knowledge reading notifications
  static const String _keyKnowledgeReadingEnabled = 'knowledge_reading_enabled';
  static const String _keyKnowledgeReadingHour = 'knowledge_reading_hour';
  static const String _keyKnowledgeReadingMinute = 'knowledge_reading_minute';
  static const String _keyKnowledgeReadingDays = 'knowledge_reading_days';
  static const String _keyKnowledgeReadingFrequency =
      'knowledge_reading_frequency';

  // Proactive knowledge reminders
  static const String _keyKnowledgeReminderEnabled =
      'knowledge_reminder_enabled';
  static const String _keyKnowledgeReminderStartHour =
      'knowledge_reminder_start_hour';
  static const String _keyKnowledgeReminderStartMinute =
      'knowledge_reminder_start_minute';
  static const String _keyKnowledgeReminderEndHour =
      'knowledge_reminder_end_hour';
  static const String _keyKnowledgeReminderEndMinute =
      'knowledge_reminder_end_minute';
  static const String _keyKnowledgeReminderCount = 'knowledge_reminder_count';
  static const String _keyKnowledgeReminderSource = 'knowledge_reminder_source';
  static const String _keyKnowledgeReminderSelectedTopics =
      'knowledge_reminder_selected_topics';
  static const String _keyKnowledgeReminderScheduledIds =
      'knowledge_reminder_scheduled_ids';

  // GĐ17 — Kế hoạch học chủ động (hàng ngày)
  static const String _keyStudyPlanPaused = 'study_plan_paused';
  static const String _keyStudyPlanQuickPerDay = 'study_plan_quick_per_day';
  static const String _keyStudyPlanLessonPerDay = 'study_plan_lesson_per_day';
  static const String _keyStudyPlanStartHour = 'study_plan_start_hour';
  static const String _keyStudyPlanStartMinute = 'study_plan_start_minute';
  static const String _keyStudyPlanEndHour = 'study_plan_end_hour';
  static const String _keyStudyPlanEndMinute = 'study_plan_end_minute';
  static const String _keyStudyPlanSlots = 'study_plan_slots';
  static const String _keyStudyPlanNewContentNotifications =
      'study_plan_new_content_notifications';
  static const String _keyStudyPlanExcludedTopics =
      'study_plan_excluded_topics';
  static const String _keyStudyPlanRotation = 'study_plan_rotation';
  static const String _keyStudyPlanPrefetchDays = 'study_plan_prefetch_days';

  // Onboarding + mặc định khóa học
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyDefaultCourseLevel = 'default_course_level';

  /// Khóa prefs người dùng được đưa vào file sao lưu `.mkbackup`.
  ///
  /// KHÔNG gồm: khóa/URL/model AI (`ai_*`), phiên ôn đang chạy (`session_*`),
  /// ID thông báo đã lập (`knowledge_reminder_scheduled_ids`) — các giá trị này
  /// là bí mật hoặc trạng thái runtime, không được xuất.
  static const List<String> backupKeys = <String>[
    _keyNotificationsEnabled,
    _keyReminderHour,
    _keyReminderMinute,
    _keyDailyGoal,
    _keyNewTopicsPerDay,
    _keyHiddenCategories,
    _keyFavoriteCategories,
    _keyLessonDefaultMode,
    _keyFavoriteDomains,
    _keyHiddenDomains,
    _keyKnowledgeReadingEnabled,
    _keyKnowledgeReadingHour,
    _keyKnowledgeReadingMinute,
    _keyKnowledgeReadingDays,
    _keyKnowledgeReadingFrequency,
    _keyKnowledgeReminderEnabled,
    _keyKnowledgeReminderStartHour,
    _keyKnowledgeReminderStartMinute,
    _keyKnowledgeReminderEndHour,
    _keyKnowledgeReminderEndMinute,
    _keyKnowledgeReminderCount,
    _keyKnowledgeReminderSource,
    _keyKnowledgeReminderSelectedTopics,
    _keyStudyPlanPaused,
    _keyStudyPlanQuickPerDay,
    _keyStudyPlanLessonPerDay,
    _keyStudyPlanStartHour,
    _keyStudyPlanStartMinute,
    _keyStudyPlanEndHour,
    _keyStudyPlanEndMinute,
    _keyStudyPlanSlots,
    _keyStudyPlanNewContentNotifications,
    _keyStudyPlanExcludedTopics,
    _keyStudyPlanRotation,
    _keyStudyPlanPrefetchDays,
    _keyOnboardingCompleted,
    _keyDefaultCourseLevel,
  ];

  // Fallback khi prefs chưa cấu hình — inject lúc build, không nhúng trong source.
  // DeepSeek defaults
  static const String _envDeepSeekApiKey = String.fromEnvironment(
    'DEEPSEEK_API_KEY',
  );
  static const String _envDeepSeekBaseUrl = String.fromEnvironment(
    'DEEPSEEK_BASE_URL',
  );
  static const String _envDeepSeekModel = String.fromEnvironment(
    'DEEPSEEK_MODEL',
  );
  static const bool _envDeepSeekProxyMode = bool.fromEnvironment(
    'DEEPSEEK_PROXY_MODE',
  );

  bool get notificationsEnabled =>
      _prefs.getBool(_keyNotificationsEnabled) ?? true;

  int get reminderHour => _prefs.getInt(_keyReminderHour) ?? 20;

  int get reminderMinute => _prefs.getInt(_keyReminderMinute) ?? 0;

  int get dailyGoal => _prefs.getInt(_keyDailyGoal) ?? 10;

  int get newTopicsPerDay => _prefs.getInt(_keyNewTopicsPerDay) ?? 2;

  List<String> get hiddenCategories =>
      _prefs.getStringList(_keyHiddenCategories) ?? const <String>[];

  List<String> get favoriteCategories =>
      _prefs.getStringList(_keyFavoriteCategories) ?? const <String>[];

  String get aiBaseUrl {
    final saved = _prefs.getString(_keyAiBaseUrl);
    if (saved != null && saved.isNotEmpty) return saved;
    final env = _envDeepSeekBaseUrl;
    if (env.isNotEmpty) return env;
    return _defaultAiBaseUrl;
  }

  String get aiApiKey => _prefs.getString(_keyAiApiKey) ?? _envDeepSeekApiKey;

  String get aiModel {
    final saved = _prefs.getString(_keyAiModel);
    if (saved != null && saved.isNotEmpty) return saved;
    final env = _envDeepSeekModel;
    if (env.isNotEmpty) return env;
    return _defaultAiModel;
  }

  /// True khi gọi AI qua proxy backend: client không giữ key DeepSeek.
  bool get aiProxyMode =>
      _prefs.getBool(_keyAiProxyMode) ?? _envDeepSeekProxyMode;

  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs.setBool(_keyNotificationsEnabled, value);
    notifyListeners();
  }

  Future<void> setReminderTime({required int hour, required int minute}) async {
    await _prefs.setInt(_keyReminderHour, hour.clamp(0, 23));
    await _prefs.setInt(_keyReminderMinute, minute.clamp(0, 59));
    notifyListeners();
  }

  Future<void> setDailyGoal(int value) async {
    await _prefs.setInt(_keyDailyGoal, value.clamp(1, 200));
    notifyListeners();
  }

  Future<void> setNewTopicsPerDay(int value) async {
    await _prefs.setInt(_keyNewTopicsPerDay, value.clamp(0, 10));
    notifyListeners();
  }

  Future<void> setHiddenCategories(List<String> value) async {
    await _prefs.setStringList(_keyHiddenCategories, value);
    notifyListeners();
  }

  Future<void> setFavoriteCategories(List<String> value) async {
    await _prefs.setStringList(_keyFavoriteCategories, value);
    notifyListeners();
  }

  Future<void> setAiConfig({
    required String baseUrl,
    required String apiKey,
    required String model,
    bool? proxyMode,
  }) async {
    await _prefs.setString(_keyAiBaseUrl, baseUrl.trim());
    await _prefs.setString(_keyAiApiKey, apiKey.trim());
    await _prefs.setString(_keyAiModel, model.trim());
    if (proxyMode != null) {
      await _prefs.setBool(_keyAiProxyMode, proxyMode);
    }
    notifyListeners();
  }

  List<String> get sessionCardIds =>
      _prefs.getStringList(_keySessionCardIds) ?? const <String>[];

  int get sessionIndex => _prefs.getInt(_keySessionIndex) ?? 0;

  /// Mã chế độ học bài AI mặc định ('standard' khi chưa đặt).
  String get lessonDefaultMode =>
      _prefs.getString(_keyLessonDefaultMode) ?? 'standard';

  List<String> get favoriteDomains =>
      _prefs.getStringList(_keyFavoriteDomains) ?? const <String>[];

  List<String> get hiddenDomains =>
      _prefs.getStringList(_keyHiddenDomains) ?? const <String>[];

  Future<void> setLessonDefaultMode(String modeId) async {
    await _prefs.setString(_keyLessonDefaultMode, modeId.trim());
    notifyListeners();
  }

  Future<void> setFavoriteDomains(List<String> value) async {
    await _prefs.setStringList(_keyFavoriteDomains, value);
    notifyListeners();
  }

  Future<void> toggleFavoriteDomain(String domainId) async {
    final List<String> current = List<String>.of(favoriteDomains);
    if (current.contains(domainId)) {
      current.remove(domainId);
    } else {
      current.add(domainId);
    }
    await setFavoriteDomains(current);
  }

  Future<void> setHiddenDomains(List<String> value) async {
    await _prefs.setStringList(_keyHiddenDomains, value);
    notifyListeners();
  }

  Future<void> toggleHiddenDomain(String domainId) async {
    final List<String> current = List<String>.of(hiddenDomains);
    if (current.contains(domainId)) {
      current.remove(domainId);
    } else {
      current.add(domainId);
    }
    await setHiddenDomains(current);
  }

  // Knowledge reading notifications
  bool get knowledgeReadingEnabled =>
      _prefs.getBool(_keyKnowledgeReadingEnabled) ?? false;

  int get knowledgeReadingHour => _prefs.getInt(_keyKnowledgeReadingHour) ?? 9;

  int get knowledgeReadingMinute =>
      _prefs.getInt(_keyKnowledgeReadingMinute) ?? 0;

  List<int> get knowledgeReadingDays =>
      _prefs.getStringList(_keyKnowledgeReadingDays)?.map(int.parse).toList() ??
      <int>[1, 2, 3, 4, 5, 6, 7];

  int get knowledgeReadingFrequency =>
      _prefs.getInt(_keyKnowledgeReadingFrequency) ?? 1;

  Future<void> setKnowledgeReadingEnabled(bool value) async {
    await _prefs.setBool(_keyKnowledgeReadingEnabled, value);
    notifyListeners();
  }

  Future<void> setKnowledgeReadingTime({
    required int hour,
    required int minute,
  }) async {
    await _prefs.setInt(_keyKnowledgeReadingHour, hour.clamp(0, 23));
    await _prefs.setInt(_keyKnowledgeReadingMinute, minute.clamp(0, 59));
    notifyListeners();
  }

  Future<void> setKnowledgeReadingDays(List<int> days) async {
    await _prefs.setStringList(
      _keyKnowledgeReadingDays,
      days.map((d) => d.toString()).toList(),
    );
    notifyListeners();
  }

  Future<void> setKnowledgeReadingFrequency(int frequency) async {
    await _prefs.setInt(_keyKnowledgeReadingFrequency, frequency.clamp(1, 7));
    notifyListeners();
  }

  bool get knowledgeReminderEnabled =>
      _prefs.getBool(_keyKnowledgeReminderEnabled) ?? false;

  int get knowledgeReminderStartHour =>
      _prefs.getInt(_keyKnowledgeReminderStartHour) ?? 9;

  int get knowledgeReminderStartMinute =>
      _prefs.getInt(_keyKnowledgeReminderStartMinute) ?? 0;

  int get knowledgeReminderEndHour =>
      _prefs.getInt(_keyKnowledgeReminderEndHour) ?? 21;

  int get knowledgeReminderEndMinute =>
      _prefs.getInt(_keyKnowledgeReminderEndMinute) ?? 0;

  int get knowledgeReminderCountPerDay =>
      _prefs.getInt(_keyKnowledgeReminderCount) ?? 3;

  /// 'all' or 'selected'
  String get knowledgeReminderSource =>
      _prefs.getString(_keyKnowledgeReminderSource) ?? 'all';

  List<String> get knowledgeReminderSelectedTopics =>
      _prefs.getStringList(_keyKnowledgeReminderSelectedTopics) ??
      const <String>[];

  List<int> get knowledgeReminderScheduledIds =>
      (_prefs.getStringList(_keyKnowledgeReminderScheduledIds) ??
              const <String>[])
          .map((String e) => int.tryParse(e))
          .whereType<int>()
          .toList();

  Future<void> setKnowledgeReminderEnabled(bool value) async {
    await _prefs.setBool(_keyKnowledgeReminderEnabled, value);
    notifyListeners();
  }

  Future<void> setKnowledgeReminderWindow({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) async {
    await _prefs.setInt(_keyKnowledgeReminderStartHour, startHour.clamp(0, 23));
    await _prefs.setInt(
      _keyKnowledgeReminderStartMinute,
      startMinute.clamp(0, 59),
    );
    await _prefs.setInt(_keyKnowledgeReminderEndHour, endHour.clamp(0, 23));
    await _prefs.setInt(_keyKnowledgeReminderEndMinute, endMinute.clamp(0, 59));
    notifyListeners();
  }

  Future<void> setKnowledgeReminderCountPerDay(int value) async {
    await _prefs.setInt(_keyKnowledgeReminderCount, value.clamp(1, 10));
    notifyListeners();
  }

  Future<void> setKnowledgeReminderSource(String value) async {
    await _prefs.setString(_keyKnowledgeReminderSource, value);
    notifyListeners();
  }

  Future<void> setKnowledgeReminderSelectedTopics(List<String> value) async {
    await _prefs.setStringList(_keyKnowledgeReminderSelectedTopics, value);
    notifyListeners();
  }

  Future<void> setKnowledgeReminderScheduledIds(List<int> value) async {
    await _prefs.setStringList(
      _keyKnowledgeReminderScheduledIds,
      value.map((int e) => e.toString()).toList(),
    );
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // GĐ17 — Kế hoạch học chủ động
  // ---------------------------------------------------------------------

  /// Tạm dừng kế hoạch (giữ nguyên lịch sử + hàng đợi, chỉ ngừng phát hành).
  bool get studyPlanPaused => _prefs.getBool(_keyStudyPlanPaused) ?? false;

  /// Số thông tin nhanh mới mỗi ngày (0 = không phát hành loại này).
  int get studyPlanQuickPerDay => _prefs.getInt(_keyStudyPlanQuickPerDay) ?? 5;

  /// Số bài viết mới mỗi ngày (0 = không phát hành loại này).
  int get studyPlanLessonPerDay =>
      _prefs.getInt(_keyStudyPlanLessonPerDay) ?? 2;

  int get studyPlanStartHour => _prefs.getInt(_keyStudyPlanStartHour) ?? 8;

  int get studyPlanStartMinute => _prefs.getInt(_keyStudyPlanStartMinute) ?? 0;

  int get studyPlanEndHour => _prefs.getInt(_keyStudyPlanEndHour) ?? 20;

  int get studyPlanEndMinute => _prefs.getInt(_keyStudyPlanEndMinute) ?? 0;

  /// Khung giờ tùy chỉnh `HH:mm`. Rỗng = chia đều trong khoảng bắt đầu–kết thúc.
  List<String> get studyPlanSlots =>
      _prefs.getStringList(_keyStudyPlanSlots) ?? const <String>[];

  /// Thông báo bài mới — độc lập với thông báo ôn tập.
  bool get studyPlanNewContentNotifications =>
      _prefs.getBool(_keyStudyPlanNewContentNotifications) ?? true;

  /// Chủ đề bị LOẠI khỏi kế hoạch (rỗng = theo dõi tất cả chủ đề đang bật).
  /// Tách riêng list "loại" để người dùng bật/tắt từng chủ đề và vẫn theo
  /// dõi được chủ đề tạo sau.
  List<String> get studyPlanExcludedTopics =>
      _prefs.getStringList(_keyStudyPlanExcludedTopics) ?? const <String>[];

  /// Con trỏ luân phiên giữa các chủ đề — persist qua restart.
  int get studyPlanRotation => _prefs.getInt(_keyStudyPlanRotation) ?? 0;

  /// Số ngày tạo trước nội dung (mục tiêu ban đầu 3).
  int get studyPlanPrefetchDays =>
      _prefs.getInt(_keyStudyPlanPrefetchDays) ?? 3;

  Future<void> setStudyPlanPaused(bool value) async {
    await _prefs.setBool(_keyStudyPlanPaused, value);
    notifyListeners();
  }

  Future<void> setStudyPlanQuickPerDay(int value) async {
    await _prefs.setInt(_keyStudyPlanQuickPerDay, value.clamp(0, 20));
    notifyListeners();
  }

  Future<void> setStudyPlanLessonPerDay(int value) async {
    await _prefs.setInt(_keyStudyPlanLessonPerDay, value.clamp(0, 10));
    notifyListeners();
  }

  Future<void> setStudyPlanWindow({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) async {
    await _prefs.setInt(_keyStudyPlanStartHour, startHour.clamp(0, 23));
    await _prefs.setInt(_keyStudyPlanStartMinute, startMinute.clamp(0, 59));
    await _prefs.setInt(_keyStudyPlanEndHour, endHour.clamp(0, 23));
    await _prefs.setInt(_keyStudyPlanEndMinute, endMinute.clamp(0, 59));
    notifyListeners();
  }

  Future<void> setStudyPlanSlots(List<String> value) async {
    await _prefs.setStringList(_keyStudyPlanSlots, value);
    notifyListeners();
  }

  Future<void> setStudyPlanNewContentNotifications(bool value) async {
    await _prefs.setBool(_keyStudyPlanNewContentNotifications, value);
    notifyListeners();
  }

  Future<void> setStudyPlanExcludedTopics(List<String> value) async {
    await _prefs.setStringList(_keyStudyPlanExcludedTopics, value);
    notifyListeners();
  }

  Future<void> setStudyPlanRotation(int value) async {
    await _prefs.setInt(_keyStudyPlanRotation, value < 0 ? 0 : value);
    notifyListeners();
  }

  Future<void> setStudyPlanPrefetchDays(int value) async {
    await _prefs.setInt(_keyStudyPlanPrefetchDays, value.clamp(1, 14));
    notifyListeners();
  }

  Future<void> saveSession({
    required List<String> cardIds,
    required int index,
  }) async {
    await _prefs.setStringList(_keySessionCardIds, cardIds);
    await _prefs.setInt(_keySessionIndex, index);
  }

  Future<void> clearSession() async {
    await _prefs.remove(_keySessionCardIds);
    await _prefs.remove(_keySessionIndex);
  }

  /// Đã hoàn tất (hoặc bỏ qua) onboarding lần đầu chưa.
  bool get onboardingCompleted =>
      _prefs.getBool(_keyOnboardingCompleted) ?? false;

  Future<void> setOnboardingCompleted(bool value) async {
    await _prefs.setBool(_keyOnboardingCompleted, value);
    notifyListeners();
  }

  /// Cấp độ mặc định của khóa học mới (`basic|advanced|pro|master`).
  String get defaultCourseLevel =>
      _prefs.getString(_keyDefaultCourseLevel) ?? 'basic';

  Future<void> setDefaultCourseLevel(String levelId) async {
    await _prefs.setString(_keyDefaultCourseLevel, levelId.trim());
    notifyListeners();
  }

  /// Xuất prefs người dùng (chỉ [backupKeys], đã được lọc kiểu) cho file sao lưu.
  Map<String, Object> exportBackupPrefs() {
    final Map<String, Object> out = <String, Object>{};
    for (final String key in backupKeys) {
      final Object? value = _prefs.get(key);
      if (value is bool || value is int || value is String) {
        out[key] = value!;
      } else if (value is List<String>) {
        out[key] = List<String>.of(value);
      }
    }
    return out;
  }

  /// Khôi phục prefs từ file sao lưu: chỉ nhận khóa trong [backupKeys] và đúng
  /// kiểu (`bool`, `int`, `String`, danh sách chuỗi); khóa lạ hoặc sai kiểu bị bỏ qua.
  /// Khóa có trong [backupKeys] nhưng vắng trong file được xóa để về mặc định.
  /// Trả về số khóa đã áp dụng.
  Future<int> restoreBackupPrefs(Map<String, Object?> data) async {
    int applied = 0;
    for (final String key in backupKeys) {
      if (!data.containsKey(key)) {
        await _prefs.remove(key);
        continue;
      }
      final Object? value = data[key];
      bool ok = true;
      if (value is bool) {
        await _prefs.setBool(key, value);
      } else if (value is int) {
        await _prefs.setInt(key, value);
      } else if (value is String) {
        await _prefs.setString(key, value);
      } else if (value is List<Object?> &&
          value.every((Object? e) => e is String)) {
        await _prefs.setStringList(key, value.cast<String>());
      } else {
        ok = false;
      }
      if (ok) applied++;
    }
    notifyListeners();
    return applied;
  }
}
