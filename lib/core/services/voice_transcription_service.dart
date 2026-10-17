import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Ghi âm → văn bản qua dịch vụ nhận dạng của hệ thống (speech_to_text).
/// Không có sẵn khi chạy test/thiết bị chưa hỗ trợ → trả về false, không ném lỗi.
class VoiceTranscriptionService {
  VoiceTranscriptionService({SpeechToText? speech})
      : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  bool _initFailed = false;

  bool get isAvailable => !_initFailed && _speech.isAvailable;
  bool get isListening => _speech.isListening;

  Future<bool> initialize({
    void Function(String message)? onError,
    void Function(String status)? onStatus,
  }) async {
    if (_initFailed) return false;
    if (_speech.isAvailable) return true;
    try {
      final bool ok = await _speech.initialize(
        onError: onError == null
            ? null
            : (SpeechRecognitionError error) => onError(error.errorMsg),
        onStatus: onStatus,
      );
      if (!ok) _initFailed = true;
      return ok;
    } catch (_) {
      _initFailed = true;
      return false;
    }
  }

  /// Bắt đầu nghe. [onResult] nhận (văn bản tích lũy, đã kết thúc phiên).
  Future<bool> start({
    required void Function(String text, bool isFinal) onResult,
    void Function(String message)? onError,
    void Function(String status)? onStatus,
  }) async {
    final bool ready = await initialize(onError: onError, onStatus: onStatus);
    if (!ready) {
      onError?.call('Thiết bị không hỗ trợ nhận dạng giọng nói.');
      return false;
    }
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) =>
            onResult(result.recognizedWords, result.finalResult),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
          pauseFor: const Duration(seconds: 4),
        ),
      );
      return true;
    } catch (e) {
      onError?.call('Không bắt đầu được ghi âm: $e');
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _speech.stop();
    } catch (_) {}
  }

  Future<void> cancel() async {
    try {
      await _speech.cancel();
    } catch (_) {}
  }
}
