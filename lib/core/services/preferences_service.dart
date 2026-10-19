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

  String get aiBaseUrl =>
      _prefs.getString(_keyAiBaseUrl) ?? _envDeepSeekBaseUrl;

  String get aiApiKey => _prefs.getString(_keyAiApiKey) ?? _envDeepSeekApiKey;

  String get aiModel => _prefs.getString(_keyAiModel) ?? _envDeepSeekModel;

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
}
