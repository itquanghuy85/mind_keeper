import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/core/services/voice_transcription_service.dart';

void main() {
  test(
    'trả về false thay vì ném lỗi khi nền tảng không có speech plugin',
    () async {
      final VoiceTranscriptionService service = VoiceTranscriptionService();

      final bool ready = await service.initialize();
      expect(ready, isFalse);
      expect(service.isAvailable, isFalse);

      bool resultCalled = false;
      final bool started = await service.start(
        onResult: (String text, bool isFinal) => resultCalled = true,
      );
      expect(started, isFalse);
      expect(resultCalled, isFalse);
      expect(service.isListening, isFalse);

      await service.stop();
      await service.cancel();
    },
  );
}
