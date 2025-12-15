package com.apexflow.app.sinan

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.apexflow.app.sinan/widget"
    private val SECURITY_CHANNEL = "com.apexflow.app.sinan/security"
    private var startIntent: Intent? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        updateSecureFlag()
        startIntent = intent
    }

    override fun onResume() {
        super.onResume()
        updateSecureFlag()
    }

    private fun updateSecureFlag() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isAppLockEnabled = prefs.getBoolean("flutter.appLockEnabled", false)
        val isRecentsBlurEnabled = prefs.getBoolean("flutter.hideContentInBackground", true)

        // Apply FLAG_SECURE if EITHER setting is enabled (independent controls)
        if (isAppLockEnabled || isRecentsBlurEnabled) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        startIntent = intent
        handleIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getStartIntent" -> {
                    val action = startIntent?.action
                    val noteId = startIntent?.getIntExtra("note_id", 0) ?: 0
                    val widgetType = startIntent?.getStringExtra("widget_type")
                    
                    val data = mapOf(
                        "action" to action,
                        "note_id" to noteId,
                        "widget_type" to widgetType
                    )
                    result.success(data)
                    startIntent = null
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURITY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateSecureFlag" -> {
                    updateSecureFlag()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun handleIntent(intent: Intent) {
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, CHANNEL).invokeMethod("onIntent", mapOf(
                "action" to intent.action,
                "note_id" to intent.getIntExtra("note_id", 0),
                "widget_type" to intent.getStringExtra("widget_type")
            ))
        }
    }
}
