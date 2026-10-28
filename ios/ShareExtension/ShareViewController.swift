import UIKit
import UniformTypeIdentifiers

/// Share Extension của MindKeeper: nhận văn bản / URL từ share sheet, ghi vào
/// App Group rồi mở app chính qua URL scheme `mindkeeper://share?id=<uuid>`.
/// App chính (ShareBridge) đọc và xóa payload, nên mỗi lần chia sẻ chỉ giao một lần.
final class ShareViewController: UIViewController {
  private static let appGroup = "group.com.mindkeeper.mindKeeper"
  private static let storeKey = "mindkeeper.pendingShare"

  private var started = false

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard !started else { return }
    started = true
    collectPayload { [weak self] text, subject in
      guard let self = self else { return }
      guard !text.isEmpty,
        let defaults = UserDefaults(suiteName: ShareViewController.appGroup)
      else {
        self.finish()
        return
      }
      let id = UUID().uuidString
      defaults.set(
        [
          "id": id,
          "text": text,
          "subject": subject,
          "createdAt": Date().timeIntervalSince1970,
        ] as [String: Any],
        forKey: ShareViewController.storeKey
      )
      guard let url = URL(string: "mindkeeper://share?id=\(id)") else {
        self.finish()
        return
      }
      self.openHostApp(url)
    }
  }

  // MARK: - Đọc nội dung chia sẻ

  /// Gộp attributedContentText / attributedTitle / attachments (chỉ plain text và
  /// URL http(s)). Ưu tiên URL; text chưa chứa URL thì ghép "text\nURL".
  private func collectPayload(_ done: @escaping (String, String) -> Void) {
    let items = (extensionContext?.inputItems as? [NSExtensionItem]) ?? []
    var text = ""
    var subject = ""
    var url: String?
    let group = DispatchGroup()
    let lock = NSLock()

    for item in items {
      if text.isEmpty,
        let t = item.attributedContentText?.string.trimmingCharacters(in: .whitespacesAndNewlines),
        !t.isEmpty
      {
        text = t
      }
      if subject.isEmpty,
        let s = item.attributedTitle?.string.trimmingCharacters(in: .whitespacesAndNewlines),
        !s.isEmpty
      {
        subject = s
      }
      for provider in item.attachments ?? [] {
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
          group.enter()
          provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { value, _ in
            var link: URL?
            if let u = value as? URL { link = u }
            if let s = value as? String { link = URL(string: s) }
            if let l = link, ["http", "https"].contains(l.scheme?.lowercased() ?? "") {
              lock.lock()
              if url == nil { url = l.absoluteString }
              lock.unlock()
            }
            group.leave()
          }
        } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
          group.enter()
          provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) {
            value, _ in
            var s: String?
            if let v = value as? String { s = v }
            if let d = value as? Data { s = String(data: d, encoding: .utf8) }
            if let s = s?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
              lock.lock()
              if text.isEmpty { text = s }
              lock.unlock()
            }
            group.leave()
          }
        }
      }
    }

    group.notify(queue: .main) {
      var body = text
      if let link = url, !body.contains(link) {
        body = body.isEmpty ? link : "\(body)\n\(link)"
      }
      done(body, subject)
    }
  }

  // MARK: - Mở app chính

  private func openHostApp(_ url: URL) {
    // 1) API chính thức của extension (không phải loại extension nào cũng cho phép).
    extensionContext?.open(url) { [weak self] ok in
      DispatchQueue.main.async {
        guard let self = self else { return }
        if !ok { self.openViaResponderChain(url) }
        self.finish()
      }
    }
  }

  /// Fallback: đi dọc responder chain tới UIApplication. Không dùng
  /// `UIApplication.shared` (không có trong extension); gọi bằng selector.
  private func openViaResponderChain(_ url: URL) {
    let openSel = NSSelectorFromString("openURL:options:completionHandler:")
    let legacySel = NSSelectorFromString("openURL:")
    var responder: UIResponder? = self
    while let r = responder {
      if r.responds(to: openSel) {
        typealias OpenFn = @convention(c) (AnyObject, Selector, URL, [AnyHashable: Any], Any?) ->
          Void
        let imp = r.method(for: openSel)
        unsafeBitCast(imp, to: OpenFn.self)(r, openSel, url, [:], nil)
        return
      }
      if r.responds(to: legacySel) {
        _ = r.perform(legacySel, with: url)
        return
      }
      responder = r.next
    }
  }

  private func finish() {
    extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
  }
}
