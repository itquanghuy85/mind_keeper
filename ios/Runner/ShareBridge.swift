import Flutter
import UIKit

/// Cầu nối Share Extension → Flutter, giữ nguyên contract của Android:
/// channel `mindkeeper/share`, `getInitialShared` (trả {text, subject} hoặc nil)
/// và `onShared` (native → Dart khi app đang chạy).
///
/// Share Extension ghi payload (id UUID) vào App Group rồi mở app bằng
/// `mindkeeper://share?id=...`. Payload bị xóa ngay khi đọc nên mỗi lần chia sẻ chỉ
/// giao một lần, dù cold start hay warm start.
final class ShareBridge: NSObject, FlutterPlugin {
  static let channelName = "mindkeeper/share"
  private static let appGroup = "group.com.mindkeeper.mindKeeper"
  private static let storeKey = "mindkeeper.pendingShare"
  /// Payload cũ hơn mức này bị bỏ (extension ghi nhưng app không được mở).
  private static let maxAge: TimeInterval = 60 * 60

  private(set) static var shared: ShareBridge?

  private let channel: FlutterMethodChannel
  /// Dart đã gọi `getInitialShared` (đã đặt handler `onShared`) chưa.
  private var dartReady = false
  private var lastDeliveredId: String?

  private init(channel: FlutterMethodChannel) {
    self.channel = channel
    super.init()
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    let instance = ShareBridge(channel: channel)
    shared = instance
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getInitialShared":
      dartReady = true
      result(takePayload())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Gọi từ SceneDelegate / AppDelegate khi app được mở bằng URL `mindkeeper://`.
  func handleIncoming(url: URL) {
    guard url.scheme?.lowercased() == "mindkeeper", url.host?.lowercased() == "share" else {
      return
    }
    // Cold start: Dart chưa sẵn sàng → để payload nằm trong App Group,
    // `getInitialShared` sẽ lấy. Không bắn `onShared` vào handler chưa đăng ký.
    guard dartReady else { return }
    if let payload = takePayload() {
      channel.invokeMethod("onShared", arguments: payload)
    }
  }

  /// Đọc rồi xóa payload; bỏ qua nếu thiếu, quá hạn hoặc đã giao (cùng id).
  private func takePayload() -> [String: String]? {
    guard let defaults = UserDefaults(suiteName: ShareBridge.appGroup),
      let raw = defaults.dictionary(forKey: ShareBridge.storeKey)
    else { return nil }
    defaults.removeObject(forKey: ShareBridge.storeKey)

    let id = raw["id"] as? String ?? ""
    if let created = raw["createdAt"] as? TimeInterval,
      Date().timeIntervalSince1970 - created > ShareBridge.maxAge
    {
      return nil
    }
    if !id.isEmpty && id == lastDeliveredId { return nil }
    lastDeliveredId = id

    let text = (raw["text"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard !text.isEmpty else { return nil }
    return ["text": text, "subject": raw["subject"] as? String ?? ""]
  }
}
