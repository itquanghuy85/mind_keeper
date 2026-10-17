import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Trích xuất văn bản từ PDF thuần Dart (không gọi dịch vụ ngoài).
class PdfTextService {
  /// [bytes] là nội dung file PDF. Ném lỗi nếu file không phải PDF hợp lệ.
  String extractText(List<int> bytes) {
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    try {
      return PdfTextExtractor(document).extractText().trim();
    } finally {
      document.dispose();
    }
  }
}
