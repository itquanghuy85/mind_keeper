import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/core/services/pdf_text_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  final PdfTextService service = PdfTextService();

  test('trích xuất văn bản từ PDF tạo bằng chính syncfusion', () {
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();
    page.graphics.drawString(
      'MindKeeper luu ki thuc theo duong cong tri nho.',
      PdfStandardFont(PdfFontFamily.helvetica, 14),
      bounds: const Rect.fromLTWH(20, 20, 500, 100),
    );
    final List<int> bytes = document.saveSync();
    document.dispose();

    final String text = service.extractText(bytes);

    expect(text, contains('MindKeeper'));
    expect(text, contains('duong cong tri nho'));
  });

  test('ném lỗi rõ ràng với dữ liệu không phải PDF', () {
    final List<int> garbage = utf8.encode('day khong phai la mot file pdf');
    expect(() => service.extractText(garbage), throwsA(anything));
  });
}
