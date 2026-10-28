package com.mindkeeper.mind_keeper

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Nhận văn bản/liên kết từ share sheet (ACTION_SEND, text/plain).
 *
 * - Cold start: nội dung của intent khởi chạy được giữ lại, Dart lấy một lần qua
 *   `getInitialShared`.
 * - Warm start (activity đang chạy, launchMode singleTop): `onNewIntent` đẩy sang
 *   Dart bằng `onShared`.
 *
 * Luôn gọi `super.onNewIntent` để plugin thông báo cục bộ (SELECT_NOTIFICATION)
 * vẫn nhận intent như trước.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var initialShared: Map<String, String>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initialShared = extractShared(intent)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).also {
            it.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialShared" -> {
                        result.success(initialShared)
                        initialShared = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val shared = extractShared(intent) ?: return
        channel?.invokeMethod("onShared", shared)
    }

    private fun extractShared(source: Intent?): Map<String, String>? {
        if (source?.action != Intent.ACTION_SEND) return null
        if (source.type?.startsWith("text/") != true) return null
        val text = source.getStringExtra(Intent.EXTRA_TEXT)?.trim()
        if (text.isNullOrEmpty()) return null
        val subject = source.getStringExtra(Intent.EXTRA_SUBJECT)?.trim().orEmpty()
        return mapOf("text" to text, "subject" to subject)
    }

    companion object {
        private const val CHANNEL = "mindkeeper/share"
    }
}
