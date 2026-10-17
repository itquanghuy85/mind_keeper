import 'package:flutter/foundation.dart';

import '../../core/services/app_services.dart';
import '../../data/models/due_review_item.dart';
import '../../data/models/enums.dart';

/// Trạng thái phiên ôn tập.
enum ReviewPhase { question, answer, finished }

/// Bộ điều khiển phiên ôn: load thẻ đến hạn, lộ đáp án, chấm và lưu FSRS.
/// Hỗ trợ tiếp tục phiên dở dang qua prefs.sessionCardIds/sessionIndex.
class ReviewController extends ChangeNotifier {
  ReviewController({required AppServices services}) : _services = services;

  final AppServices _services;

  ReviewPhase phase = ReviewPhase.question;
  List<DueReviewItem> queue = const <DueReviewItem>[];
  int index = 0;
  bool loading = false;
  String? error;
  String userAnswer = '';
  DueReviewItem? current;
  int reviewedCount = 0;
  int againCount = 0;
  bool _initialized = false;

  int get total => queue.length;
  bool get hasMore => index < queue.length;
  double get progress =>
      queue.isEmpty ? 0 : (index / queue.length).clamp(0.0, 1.0);

  Future<void> load({bool resume = true}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final DateTime now = DateTime.now();
      final List<DueReviewItem> due =
          await _services.cards.listDueWithContext(now: now);
      if (resume) {
        final List<String> savedIds = _services.prefs.sessionCardIds;
        final int savedIndex = _services.prefs.sessionIndex;
        if (savedIds.isNotEmpty && savedIndex < savedIds.length) {
          final List<DueReviewItem> ordered = <DueReviewItem>[];
          final Map<String, DueReviewItem> byId = <String, DueReviewItem>{
            for (final DueReviewItem item in due) item.card.id: item,
          };
          for (final String id in savedIds.sublist(savedIndex)) {
            final DueReviewItem? item = byId[id];
            if (item != null) {
              ordered.add(item);
              byId.remove(id);
            }
          }
          ordered.addAll(byId.values);
          queue = ordered;
          index = 0;
        } else {
          queue = due;
          index = 0;
        }
      } else {
        queue = due;
        index = 0;
        await _services.prefs.clearSession();
      }
      _initialized = true;
      _advanceToCurrent();
    } catch (e) {
      error = e.toString();
      queue = const <DueReviewItem>[];
      current = null;
      phase = ReviewPhase.finished;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Mở đúng một thẻ (dùng khi notification chạm vào card id).
  Future<void> loadSingleCard(String cardId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final DueReviewItem? item = await _services.cards.getByIdWithContext(cardId);
      if (item == null) {
        error = 'Thẻ ôn tập không còn tồn tại.';
        queue = const <DueReviewItem>[];
        current = null;
        phase = ReviewPhase.finished;
      } else {
        queue = <DueReviewItem>[item];
        index = 0;
        phase = ReviewPhase.question;
        userAnswer = '';
        current = item;
      }
    } catch (e) {
      error = e.toString();
      phase = ReviewPhase.finished;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _advanceToCurrent() {
    if (index >= queue.length) {
      current = null;
      phase = ReviewPhase.finished;
      return;
    }
    current = queue[index];
    phase = ReviewPhase.question;
    userAnswer = '';
  }

  void onAnswerChanged(String value) {
    userAnswer = value;
  }

  void revealAnswer() {
    if (phase != ReviewPhase.question || current == null) return;
    phase = ReviewPhase.answer;
    notifyListeners();
  }

  Future<void> rate(MemoryRating rating) async {
    final DueReviewItem? item = current;
    if (item == null || phase != ReviewPhase.answer) return;
    try {
      final DateTime now = DateTime.now();
      final result = _services.scheduler.schedule(
        card: item.card,
        rating: rating,
        now: now,
        answerText: userAnswer.trim().isEmpty ? null : userAnswer.trim(),
      );
      await _services.cards.saveReview(
        updatedCard: result.card,
        log: result.log,
      );
      reviewedCount++;
      if (rating == MemoryRating.again) {
        againCount++;
        // Thẻ Quên: đưa về cuối phiên để thử lại trong cùng phiên.
        queue = <DueReviewItem>[
          ...queue.sublist(0, index + 1),
          item,
          ...queue.sublist(index + 1),
        ];
      }
      index++;
      await _persistProgress();
      _advanceToCurrent();
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _persistProgress() async {
    final List<String> ids = queue.map((DueReviewItem e) => e.card.id).toList();
    final int nextIndex = againCount > 0 && index < ids.length ? index : index;
    await _services.prefs.saveSession(cardIds: ids, index: nextIndex);
  }

  Future<void> exit() async {
    if (reviewedCount > 0) {
      await _persistProgress();
    } else {
      await _services.prefs.clearSession();
    }
  }

  Future<void> finishAndClear() async {
    await _services.prefs.clearSession();
    phase = ReviewPhase.finished;
    notifyListeners();
  }

  bool get isInitialized => _initialized;
}
