/// Helper dựng nội dung thông báo kiến thức (title/body/bigText) dùng chung
/// cho mẩu khóa học, bài học và thông tin nhanh.
library;

/// Độ dài tối đa của dòng body thông báo.
const int notificationBodyMax = 180;

/// Nhãn đứng trước mẹo nhớ trong phần mở rộng của thông báo.
const String notificationTipLabel = 'Mẹo nhớ: ';

String _flatten(String text) => text.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Cắt [text] còn tối đa [max] ký tự, KHÔNG cắt giữa từ; thêm `…` khi bị cắt.
///
/// Kết quả (kể cả dấu `…`) không vượt quá [max] ký tự. Xuống dòng/khoảng
/// trắng liên tiếp được gộp thành một dấu cách.
String truncateAtWord(String text, int max) {
  final String flat = _flatten(text);
  if (max <= 0) return '';
  if (flat.length <= max) return flat;
  if (max == 1) return '…';
  final String head = flat.substring(0, max - 1);
  // Nếu ký tự ngay sau điểm cắt là khoảng trắng thì head đã kết thúc ở ranh
  // giới từ; ngược lại lùi về dấu cách gần nhất.
  final bool atBoundary = flat[max - 1] == ' ';
  final int space = head.lastIndexOf(' ');
  String cut = atBoundary || space <= 0 ? head : head.substring(0, space);
  cut = cut.replaceFirst(RegExp(r'[\s,;:\-–—]+$'), '');
  if (cut.isEmpty) cut = head.trimRight();
  return '$cut…';
}

/// Lấy tối đa [maxSentences] câu đầu của [text] (ý chính) trong [max] ký tự.
///
/// Giữ nguyên câu hoàn chỉnh khi vừa; câu đầu quá dài thì cắt theo từ.
String leadSentences(
  String text, {
  int maxSentences = 2,
  int max = notificationBodyMax,
}) {
  final String flat = _flatten(text);
  if (flat.isEmpty) return '';
  final List<String> sentences = flat.split(RegExp(r'(?<=[.!?…])\s+'));
  final StringBuffer out = StringBuffer();
  int count = 0;
  for (final String sentence in sentences) {
    if (count >= maxSentences) break;
    final String next = out.isEmpty ? sentence : '$out $sentence';
    if (next.length > max) break;
    out
      ..clear()
      ..write(next);
    count++;
  }
  if (out.isNotEmpty) return out.toString();
  return truncateAtWord(flat, max);
}

/// Body thông báo: tóm tắt rút gọn ≤ [max] ký tự (không cắt giữa từ).
String notificationBody(String summary, {int max = notificationBodyMax}) =>
    truncateAtWord(summary, max);

/// Phần mở rộng: tóm tắt đầy đủ + dòng "Mẹo nhớ: ..." (nếu có mẹo).
String composeBigText(String summary, String memoryTip) {
  final String s = summary.trim();
  final String tip = _flatten(memoryTip);
  if (tip.isEmpty) return s;
  final String line = '$notificationTipLabel$tip';
  return s.isEmpty ? line : '$s\n$line';
}
