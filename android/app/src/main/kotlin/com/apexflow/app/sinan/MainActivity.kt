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
                    
                    val data = mapOf(
                        "action" to action,
                        "note_id" to noteId,
                        "current_note_id" to currentNoteId,
                        "widget_type" to widgetType,
                        "shared_text" to sharedText
                    )
                    result.success(data)
                    startIntent = null
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
