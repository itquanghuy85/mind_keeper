import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Trích xuất văn bản từ ảnh bằng ML Kit (chạy trên máy, Latin script — phủ tiếng Việt).
class OcrService {
  TextRecognizer? _recognizer;

  /// OCR ảnh tại [imagePath]. Trả về `''` nếu không đọc được chữ nào.
  Future<String> recognizeFromImage(String imagePath) async {
    final TextRecognizer recognizer = _recognizer ??= TextRecognizer(
      script: TextRecognitionScript.latin,
    );
    final RecognizedText recognized = await recognizer.processImage(
      InputImage.fromFilePath(imagePath),
    );
    return recognized.text.trim();
  }

  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}
