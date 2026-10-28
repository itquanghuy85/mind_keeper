import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // flutter_local_notifications nhận chạm thông báo (cả cold start) và hiện
    // thông báo khi app mở thông qua delegate này; payload được chuyển cho Dart
    // (NotificationRouter) nên không override didReceive thủ công.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Cầu nối Share Extension (channel "mindkeeper/share") — cùng contract với Android.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ShareBridge") {
      ShareBridge.register(with: registrar)
    }
  }

  // Fallback khi không dùng scene lifecycle: mindkeeper://share?id=...
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    ShareBridge.shared?.handleIncoming(url: url)
    return super.application(app, open: url, options: options)
  }
}
