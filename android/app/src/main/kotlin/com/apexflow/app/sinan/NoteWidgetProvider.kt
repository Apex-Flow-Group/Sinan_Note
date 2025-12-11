package com.apexflow.app.sinan

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.Intent
import android.app.PendingIntent
import android.widget.RemoteViews
import android.os.Build
import android.graphics.Color
import es.antonborri.home_widget.HomeWidgetProvider

class NoteWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val title = widgetData.getString("title", "Select Note")
                val content = widgetData.getString("content", "Tap to select a note")
                val noteId = widgetData.getInt("note_id", 0)

                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_content, content)

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
                        putExtra("widget_type", "note")
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
