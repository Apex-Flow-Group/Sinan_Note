package com.apexflow.app.sinan

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.apexflow.app.sinan/widget"
    private val SECURITY_CHANNEL = "com.apexflow.app.sinan/security"
    private val LAUNCHER_CHANNEL = "com.apexflow.app.sinan/launcher"
    private val EMAIL_CHANNEL = "apex_note/email"
    private var startIntent: Intent? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        startIntent = intent
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        startIntent = intent
        handleIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Email Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EMAIL_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendEmail") {
                try {
                    val email = call.argument<String>("email")
                    val subject = call.argument<String>("subject")
                    val body = call.argument<String>("body")
                    
                    val intent = Intent(Intent.ACTION_SENDTO).apply {
                        data = Uri.parse("mailto:")
                        putExtra(Intent.EXTRA_EMAIL, arrayOf(email))
                        putExtra(Intent.EXTRA_SUBJECT, subject)
                        putExtra(Intent.EXTRA_TEXT, body)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    
                    if (intent.resolveActivity(packageManager) != null) {
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.error("NO_EMAIL_APP", "No email app found", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LAUNCHER_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "launch") {
                val url = call.arguments as? String
                if (url != null) {
                    startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                    result.success(null)
                } else {
                    result.error("INVALID_URL", "URL is null", null)
                }
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getStartIntent" -> {
                    val action = startIntent?.action
                    val noteId = startIntent?.getIntExtra("note_id", 0) ?: 0
                    val currentNoteId = startIntent?.getIntExtra("current_note_id", 0) ?: 0
                    val widgetType = startIntent?.getStringExtra("widget_type")
                    
                    val sharedText = when (action) {
                        Intent.ACTION_SEND -> startIntent?.getStringExtra(Intent.EXTRA_TEXT)
                        Intent.ACTION_VIEW, Intent.ACTION_EDIT -> startIntent?.data?.let { uri ->
                            contentResolver.openInputStream(uri)?.bufferedReader()?.use { it.readText() }
                        }
                        else -> null
                    }

                    // Handle .sinan file from Apex
                    val filePath = if (action == Intent.ACTION_VIEW) {
                        startIntent?.data?.let { uri ->
                            val path = uri.path
                            if (path?.endsWith(".sinan") == true) path else null
                        }
                    } else null
                    
                    val data = mapOf(
                        "action" to (if (filePath != null) "com.apexflow.app.sinan.ACTION_OPEN_SINAN_FILE" else action),
                        "note_id" to noteId,
                        "current_note_id" to currentNoteId,
                        "widget_type" to widgetType,
                        "shared_text" to sharedText,
                        "file_path" to filePath
                    )
                    result.success(data)
                    startIntent = null
                }
                "isPackageInstalled" -> {
                    val pkg = call.argument<String>("package") ?: ""
                    val installed = try {
                        packageManager.getPackageInfo(pkg, 0)
                        true
                    } catch (_: Exception) { false }
                    result.success(installed)
                }
                "openApexWithFile" -> {
                    val path = call.argument<String>("path") ?: ""
                    val file = java.io.File(path)
                    val uri = androidx.core.content.FileProvider.getUriForFile(
                        this, "${packageName}.fileprovider", file
                    )
                    val intent = Intent(Intent.ACTION_SEND).apply {
                        type = "application/x-sinan"
                        setPackage("com.apexflow.tools.transfer")
                        putExtra(Intent.EXTRA_STREAM, uri)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    try {
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("NOT_INSTALLED", "Apex not installed", null)
                    }
                }
                "openUrl" -> {
                    val url = call.argument<String>("url") ?: ""
                    val intent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse(url)).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURITY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "secureScreen" -> {
                    val secure = call.argument<Boolean>("secure") ?: false
                    if (secure) {
                        window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun handleIntent(intent: Intent) {
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            val sharedText = when (intent.action) {
                Intent.ACTION_SEND -> intent.getStringExtra(Intent.EXTRA_TEXT)
                Intent.ACTION_VIEW, Intent.ACTION_EDIT -> intent.data?.let { uri ->
                    contentResolver.openInputStream(uri)?.bufferedReader()?.use { it.readText() }
                }
                else -> null
            }
            
            MethodChannel(messenger, CHANNEL).invokeMethod("onIntent", mapOf(
                "action" to intent.action,
                "note_id" to intent.getIntExtra("note_id", 0),
                "widget_type" to intent.getStringExtra("widget_type"),
                "shared_text" to sharedText
            ))
        }
    }
}
