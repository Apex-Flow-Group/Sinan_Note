package com.apexflow.app.sinan

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.Intent
import android.app.PendingIntent
import android.widget.RemoteViews
import android.graphics.Color
import android.os.Build
import es.antonborri.home_widget.HomeWidgetProvider

class ChecklistWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_checklist_layout).apply {
                val title = widgetData.getString("checklist_title", "Select Checklist") ?: "Select Checklist"
                val preview = widgetData.getString("checklist_preview", "Tap to select a checklist") ?: "Tap to select a checklist"
                val noteId = widgetData.getInt("checklist_note_id", 0)
                val totalItems = widgetData.getInt("checklist_total", 0)
                val completedItems = widgetData.getInt("checklist_completed", 0)
                
                setTextViewText(R.id.checklist_title, title)
                setTextViewText(R.id.checklist_content, preview) // Use simple text snapshot
                
                // Show progress if available
                if (totalItems > 0) {
                    val progressText = "$completedItems / $totalItems"
                    setTextViewText(R.id.checklist_progress, progressText)
                    setViewVisibility(R.id.checklist_progress, android.view.View.VISIBLE)
                } else {
                    setViewVisibility(R.id.checklist_progress, android.view.View.GONE)
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
                    setOnClickPendingIntent(R.id.widget_card, pendingIntent)
                } else {
                    val selectIntent = Intent(context, MainActivity::class.java).apply {
                        action = "com.apexflow.app.sinan.ACTION_SELECT_NOTE_FOR_WIDGET"
                        putExtra("widget_type", "checklist")
                        setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    }
                    val pendingIntent = PendingIntent.getActivity(context, 0, selectIntent, flags)
                    setOnClickPendingIntent(R.id.widget_card, pendingIntent)
                }
            }
            
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
