package com.example.noah_frontend_flutter

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The phone's own share sheet, for sharing a link to a Noahgram post.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "noah/share").setMethodCallHandler { call, result ->
            if (call.method == "text" && call.arguments is String) {
                val send = Intent(Intent.ACTION_SEND).apply {
                    type = "text/plain"
                    putExtra(Intent.EXTRA_TEXT, call.arguments as String)
                }
                startActivity(Intent.createChooser(send, null))
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}
