import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/ocr_service.dart';
import '../../core/services/pdf_text_service.dart';
import '../../core/widgets/app_dialog.dart';
import 'text_import_screen.dart';

/// Luồng nhập từ ảnh (OCR) và PDF: trích xuất văn bản → mở màn nhập văn bản sẵn nội dung.
class MediaImportFlow {
  const MediaImportFlow._();

  /// Chọn ảnh (chụp hoặc thư viện) → OCR → mở màn nhập văn bản.
  static Future<void> fromImage(BuildContext context, {String? topicId}) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.of(sheetCtx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.of(sheetCtx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;

    final XFile? picked = await ImagePicker().pickImage(source: source);
    if (picked == null || !context.mounted) return;

    showAppSnack(context, message: 'Đang nhận diện chữ trong ảnh...');
    final OcrService ocr = OcrService();
    String text;
    try {
      text = await ocr.recognizeFromImage(picked.path);
    } catch (e) {
      if (context.mounted) {
        showAppSnack(context, message: 'OCR thất bại: $e', error: true);
      }
      return;
    } finally {
      await ocr.dispose();
    }
    if (!context.mounted) return;
    if (text.isEmpty) {
      showAppSnack(
        context,
        message: 'Không đọc được chữ trong ảnh — thử ảnh rõ hơn.',
        error: true,
      );
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TextImportScreen(
          topicId: topicId,
          initialText: text.length > 100000 ? text.substring(0, 100000) : text,
        ),
      ),
    );
  }

  /// Chọn file PDF → trích văn bản → mở màn nhập văn bản sẵn nội dung.
  static Future<void> fromPdf(BuildContext context, {String? topicId}) async {
    final List<PlatformFile> files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['pdf'],
    );
    if (files.isEmpty || !context.mounted) return;
    final PlatformFile file = files.single;
    Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (e) {
      if (context.mounted) {
        showAppSnack(context, message: 'Không đọc được file: $e', error: true);
      }
      return;
    }
    if (!context.mounted) return;

    showAppSnack(context, message: 'Đang trích xuất văn bản PDF...');
    String text;
    try {
      text = await compute(_extractPdfText, bytes);
    } catch (e) {
      if (context.mounted) {
        showAppSnack(context, message: 'Không đọc được PDF: $e', error: true);
      }
      return;
    }
    if (!context.mounted) return;
    if (text.trim().isEmpty) {
      showAppSnack(
        context,
        message: 'PDF không có lớp văn bản (bản scan?) — dùng nhập từ ảnh.',
        error: true,
      );
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TextImportScreen(
          topicId: topicId,
          initialText: text.length > 100000 ? text.substring(0, 100000) : text,
        ),
      ),
    );
  }
}

String _extractPdfText(Uint8List bytes) => PdfTextService().extractText(bytes);
