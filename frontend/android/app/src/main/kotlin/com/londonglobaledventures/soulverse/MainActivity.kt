package com.londonglobaledventures.soulverse

import android.content.ActivityNotFoundException
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "soulverse/share")
            .setMethodCallHandler { call, result ->
                if (call.method != "shareImageToApp") return@setMethodCallHandler result.notImplemented()

                val packageName = call.argument<String>("package")
                val path = call.argument<String>("path")
                if (packageName == null || path == null) {
                    return@setMethodCallHandler result.error("ARGS", "package and path are required", null)
                }
                result.success(shareImageToApp(packageName, File(path), call.argument<String>("text")))
            }
    }

    /** Returns false when the target app isn't installed, so Dart can fall back to the share sheet. */
    private fun shareImageToApp(packageName: String, file: File, text: String?): Boolean {
        val uri = FileProvider.getUriForFile(this, "${applicationContext.packageName}.verse_share", file)
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            setPackage(packageName)
            putExtra(Intent.EXTRA_STREAM, uri)
            if (!text.isNullOrBlank()) putExtra(Intent.EXTRA_TEXT, text)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        return try {
            startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }
}
