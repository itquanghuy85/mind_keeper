import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  // Warm start: Share Extension mở app bằng mindkeeper://share?id=...
  // (cold start: payload được lấy qua ShareBridge.getInitialShared).
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts {
      ShareBridge.shared?.handleIncoming(url: context.url)
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
