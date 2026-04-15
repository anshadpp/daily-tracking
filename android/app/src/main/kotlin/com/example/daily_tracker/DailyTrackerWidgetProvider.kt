package com.example.daily_tracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
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
            val headline = data.getString("headline", "Daily Tracker")
            val subline = data.getString("subline", "Tap to open")
            val progress = data.getInt("progress", 0)
            val progressLabel = data.getString("progressLabel", "0 / 0")
            val accent = data.getInt("accentColor", 0xFF2E7D32.toInt())
            val prayers = data.getString("prayers", "") ?: ""

            views.setTextViewText(R.id.widget_title, headline)
            views.setTextViewText(R.id.widget_subtitle, subline)
            views.setTextViewText(R.id.widget_progress_label, "$progress%  •  $progressLabel")
            views.setProgressBar(R.id.widget_progress, 100, progress, false)
            views.setInt(R.id.widget_progress, "setProgressTintList", accent)
            views.setInt(R.id.widget_title, "setTextColor", 0xFFFFFFFF.toInt())

            // Prayers row
            if (prayers.isNotEmpty()) {
                val parts = prayers.split(";").take(3)
                val labels = parts.map { it.split("|").let { kv -> "${kv[0]} ${kv.getOrNull(1) ?: ""}" } }
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

            // Refresh button: background callback to let Flutter rebuild + push latest data
            val refreshIntent = HomeWidgetBackgroundIntent.getBroadcast(
                context,
                Uri.parse("dailytracker://refresh")
            )
            views.setOnClickPendingIntent(R.id.widget_refresh_btn, refreshIntent)

            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
