package com.orushops.orushops

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.orushops/whatsapp_share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareImageToWhatsApp" -> {
                        val filePath = call.argument<String>("filePath")
                        if (filePath == null) {
                            result.error("INVALID_ARGS", "filePath is required", null)
                            return@setMethodCallHandler
                        }
                        val success = shareImageToWhatsApp(filePath)
                        result.success(success)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Shares an image file directly to WhatsApp (Business first, then Personal).
     * Bypasses the system share sheet entirely — opens WhatsApp straight away.
     * Returns true if WhatsApp was opened, false if not installed.
     */
    private fun shareImageToWhatsApp(filePath: String): Boolean {
        val file = File(filePath)
        if (!file.exists()) return false

        val contentUri: Uri = FileProvider.getUriForFile(
            this,
            "${applicationContext.packageName}.fileprovider",
            file
        )

        // Try WhatsApp Business first, then personal WhatsApp
        val packages = listOf("com.whatsapp.w4b", "com.whatsapp")

        for (packageName in packages) {
            if (isAppInstalled(packageName)) {
                val intent = Intent(Intent.ACTION_SEND).apply {
                    type = "image/png"
                    putExtra(Intent.EXTRA_STREAM, contentUri)
                    setPackage(packageName)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
                return true
            }
        }
        return false // Neither WhatsApp variant installed
    }

    private fun isAppInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }
}
