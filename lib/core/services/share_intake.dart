import 'package:flutter/services.dart';

/// Nội dung người dùng chia sẻ vào app (share sheet Android text/plain; iOS qua
/// Share Extension → App Group → `ShareBridge.swift`, cùng channel và contract).
class SharedPayload {
  const SharedPayload({required this.text, this.subject = ''});

  /// Toàn bộ văn bản chia sẻ (link nằm trong text).
  final String text;

  /// Tiêu đề kèm theo (vd. tên trang) nếu app nguồn gửi `EXTRA_SUBJECT`.
  final String subject;

  static final RegExp _urlRe = RegExp(
    r'https?://[^\s<>"]+',
    caseSensitive: false,
  );

  /// Liên kết http(s) đầu tiên trong [text], bỏ dấu câu dính ở cuối.
  String? get url {
    final RegExpMatch? m = _urlRe.firstMatch(text);
    if (m == null) return null;
    return m.group(0)!.replaceFirst(RegExp(r'[)\].,;:!?]+$'), '');
  }

  /// Văn bản chia sẻ gần như chỉ là một liên kết (phần chữ khác < 20 ký tự).
  bool get isLink {
    final String? link = url;
    if (link == null) return false;
    return text.replaceFirst(link, '').trim().length < 20;
  }

  factory SharedPayload.fromMap(Map<Object?, Object?> map) => SharedPayload(
    text: '${map['text'] ?? ''}'.trim(),
    subject: '${map['subject'] ?? ''}'.trim(),
  );

  @override
  bool operator ==(Object other) =>
      other is SharedPayload && other.text == text && other.subject == subject;

  @override
  int get hashCode => Object.hash(text, subject);
}

/// Cầu nối nhận share sheet từ `MainActivity` (Android) và `ShareBridge.swift`
/// (iOS) — cold + warm start.
///
/// - [initialize] chạy một lần trước `runApp`: lấy nội dung của intent khởi chạy
///   (cold start) và lắng nghe `onShared` (warm start).
/// - Nội dung chưa có ai nhận (vd. đang ở onboarding) được giữ ở [pending] đến
///   khi [setListener] gọi.
class ShareIntake {
  ShareIntake._();

  static final ShareIntake instance = ShareIntake._();

  static const MethodChannel _channel = MethodChannel('mindkeeper/share');

  SharedPayload? pending;
  void Function(SharedPayload payload)? _listener;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onShared' &&
          call.arguments is Map<Object?, Object?>) {
        deliver(SharedPayload.fromMap(call.arguments as Map<Object?, Object?>));
      }
    });
    try {
      final Object? initial = await _channel.invokeMethod<Object?>(
        'getInitialShared',
      );
      if (initial is Map<Object?, Object?>) {
        deliver(SharedPayload.fromMap(initial));
      }
    } on MissingPluginException {
      // Nền tảng không có kênh (desktop/web/test) — bỏ qua. iOS có kênh qua ShareBridge.
    } on PlatformException {
      // Không đọc được intent khởi chạy — không chặn khởi động.
    }
  }

  /// Giao payload cho listener hiện tại; chưa có listener thì giữ lại.
  void deliver(SharedPayload payload) {
    if (payload.text.trim().isEmpty) return;
    final void Function(SharedPayload)? l = _listener;
    if (l == null) {
      pending = payload;
    } else {
      l(payload);
    }
  }

  /// Đăng ký (hoặc gỡ với `null`) listener; nếu đang có payload chờ thì giao ngay.
  void setListener(void Function(SharedPayload payload)? listener) {
    _listener = listener;
    final SharedPayload? waiting = pending;
    if (listener != null && waiting != null) {
      pending = null;
      listener(waiting);
    }
  }
}
