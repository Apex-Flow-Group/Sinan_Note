package com.apexflow.app.sinan

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.app.PendingIntent
import android.widget.RemoteViews
import android.graphics.Color
import android.os.Build

class ChecklistWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_checklist_layout)
        
        try {
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val title = prefs.getString("checklist_title", "Select Checklist") ?: "Select Checklist"
            val content = prefs.getString("checklist_content", "Tap to select a checklist") ?: "Tap to select a checklist"
            val noteId = prefs.getInt("checklist_note_id", 0)
            val totalItems = prefs.getInt("checklist_total", 0)
            val completedItems = prefs.getInt("checklist_completed", 0)
            
            views.setTextViewText(R.id.checklist_title, title)
            views.setTextViewText(R.id.checklist_content, content)
            
            // Show progress if available
            if (totalItems > 0) {
                val progressText = "$completedItems / $totalItems"
                views.setTextViewText(R.id.checklist_progress, progressText)
                views.setViewVisibility(R.id.checklist_progress, android.view.View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.checklist_progress, android.view.View.GONE)
            }
            
            // System theme colors are applied via widget_background drawable
            
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            
            if (noteId > 0) {
                val viewIntent = Intent(context, MainActivity::class.java).apply {
                    action = "com.apexflow.app.sinan.ACTION_VIEW_NOTE"
                    putExtra("note_id", noteId)
                    setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                }
                val pendingIntent = PendingIntent.getActivity(context, noteId, viewIntent, flags)
                views.setOnClickPendingIntent(R.id.widget_card, pendingIntent)
            } else {
                val selectIntent = Intent(context, MainActivity::class.java).apply {
                    action = "com.apexflow.app.sinan.ACTION_SELECT_NOTE_FOR_WIDGET"
                    putExtra("widget_type", "checklist")
                    setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                }
                val pendingIntent = PendingIntent.getActivity(context, 0, selectIntent, flags)
                views.setOnClickPendingIntent(R.id.widget_card, pendingIntent)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
