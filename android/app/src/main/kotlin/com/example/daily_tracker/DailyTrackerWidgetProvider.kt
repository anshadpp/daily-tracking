package com.example.daily_tracker

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin

class DailyTrackerWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.daily_tracker_widget)

            val data = HomeWidgetPlugin.getData(context)
            val headline = data.getString("headline", "Daily Tracker") ?: "Daily Tracker"
            val subline = data.getString("subline", "Tap to open") ?: "Tap to open"
            val progress = data.getInt("progress", 0)
            val progressLabel = data.getString("progressLabel", "0 / 0") ?: "0 / 0"
            val prayers = data.getString("prayers", "") ?: ""

            views.setTextViewText(R.id.widget_title, headline)
            views.setTextViewText(R.id.widget_subtitle, subline)
            views.setTextViewText(R.id.widget_progress_label, "$progress%  •  $progressLabel")
            views.setProgressBar(R.id.widget_progress, 100, progress, false)

            if (prayers.isNotEmpty()) {
                val parts = prayers.split(";").take(3)
                val labels = parts.map { segment ->
                    val kv = segment.split("|")
                    "${kv.getOrNull(0) ?: ""} ${kv.getOrNull(1) ?: ""}".trim()
                }
                views.setTextViewText(R.id.widget_prayers, labels.joinToString("  •  "))
                views.setViewVisibility(R.id.widget_prayers, android.view.View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_prayers, android.view.View.GONE)
            }

            // Tap whole card: open app
            val openIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("dailytracker://open")
            )
            views.setOnClickPendingIntent(R.id.widget_root, openIntent)

            // Mark-done button: open app with toggle intent
            val toggleIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("dailytracker://toggle-current")
            )
            views.setOnClickPendingIntent(R.id.widget_done_btn, toggleIntent)

            // Refresh button: just reopens app (no background callback needed)
            val refreshIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("dailytracker://refresh")
            )
            views.setOnClickPendingIntent(R.id.widget_refresh_btn, refreshIntent)

            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
