package com.example.daily_tracker

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.SystemClock
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

class DailyTrackerWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val REFRESH_ACTION = "com.example.daily_tracker.WIDGET_REFRESH"
        private const val INTERVAL_MS: Long = 15 * 60 * 1000
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        scheduleAlarm(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        cancelAlarm(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == REFRESH_ACTION) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(
                ComponentName(context, DailyTrackerWidgetProvider::class.java)
            )
            onUpdate(context, mgr, ids)
            return
        }
        super.onReceive(context, intent)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.daily_tracker_widget)
            val data = HomeWidgetPlugin.getData(context)

            var headline = data.getString("headline", "Daily Tracker") ?: "Daily Tracker"
            var subline = data.getString("subline", "Tap to open") ?: "Tap to open"
            var progress = data.getInt("progress", 0)
            var progressLabel = data.getString("progressLabel", "0 / 0") ?: "0 / 0"
            val prayers = data.getString("prayers", "") ?: ""
            val todosStr = data.getString("todos", "[]") ?: "[]"

            // Self-compute from schedule JSON
            val scheduleStr = data.getString("schedule", null)
            if (scheduleStr != null) {
                try {
                    val schedule = JSONObject(scheduleStr)
                    val blocks = schedule.getJSONArray("blocks")
                    val completedArr = schedule.getJSONArray("completedIds")
                    val completedSet = mutableSetOf<Int>()
                    for (i in 0 until completedArr.length()) completedSet.add(completedArr.getInt(i))

                    val cal = Calendar.getInstance()
                    val nowMin = cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE)
                    val totalBlocks = schedule.getInt("totalBlocks")
                    val prayersDone = schedule.optInt("prayersDone", 0)
                    val prayersTotal = schedule.optInt("prayersTotal", 0)
                    val done = completedSet.size + prayersDone
                    val total = totalBlocks + prayersTotal

                    progress = if (total == 0) 0 else (100 * done / total)
                    progressLabel = "$done / $total"

                    var foundCurrent = false
                    var nextTitle: String? = null
                    var nextStart = -1
                    for (i in 0 until blocks.length()) {
                        val b = blocks.getJSONObject(i)
                        val start = b.getInt("start")
                        val end = b.getInt("end")
                        val title = b.getString("title")
                        if (nowMin in start until end) {
                            headline = title
                            subline = "%02d:%02d – %02d:%02d  •  NOW".format(
                                start / 60, start % 60, end / 60, end % 60
                            )
                            foundCurrent = true
                            break
                        }
                        if (start > nowMin && (nextStart == -1 || start < nextStart)) {
                            nextStart = start
                            nextTitle = title
                        }
                    }
                    if (!foundCurrent) {
                        if (nextTitle != null && nextStart >= 0) {
                            headline = nextTitle
                            subline = "Up next · %02d:%02d".format(nextStart / 60, nextStart % 60)
                        } else {
                            headline = "All caught up"
                            subline = "Great work today"
                        }
                    }
                } catch (_: Exception) { }
            }

            views.setTextViewText(R.id.widget_title, headline)
            views.setTextViewText(R.id.widget_subtitle, subline)
            views.setTextViewText(R.id.widget_progress_label, "$progress%  •  $progressLabel")
            views.setProgressBar(R.id.widget_progress, 100, progress, false)

            // Prayers
            if (prayers.isNotEmpty()) {
                val parts = prayers.split(";").take(3)
                val labels = parts.map { seg ->
                    val kv = seg.split("|")
                    "${kv.getOrNull(0) ?: ""} ${kv.getOrNull(1) ?: ""}".trim()
                }
                views.setTextViewText(R.id.widget_prayers, labels.joinToString("  •  "))
                views.setViewVisibility(R.id.widget_prayers, android.view.View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_prayers, android.view.View.GONE)
            }

            // Qada warning
            val qadaStr = data.getString("qada", "") ?: ""
            if (qadaStr.isNotEmpty()) {
                views.setTextViewText(R.id.widget_qada, "⚠ Qada: $qadaStr")
                views.setViewVisibility(R.id.widget_qada, android.view.View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_qada, android.view.View.GONE)
            }

            // Todos
            try {
                val todosArr = JSONArray(todosStr)
                if (todosArr.length() > 0) {
                    views.setViewVisibility(R.id.widget_todo_section, android.view.View.VISIBLE)
                    val rowIds = intArrayOf(R.id.widget_todo1_row, R.id.widget_todo2_row, R.id.widget_todo3_row)
                    val checkIds = intArrayOf(R.id.widget_todo1_check, R.id.widget_todo2_check, R.id.widget_todo3_check)
                    val textIds = intArrayOf(R.id.widget_todo1_text, R.id.widget_todo2_text, R.id.widget_todo3_text)
                    for (i in 0 until 3) {
                        if (i < todosArr.length()) {
                            val todo = todosArr.getJSONObject(i)
                            val todoId = todo.getInt("id")
                            val title = todo.getString("title")
                            views.setViewVisibility(rowIds[i], android.view.View.VISIBLE)
                            views.setTextViewText(textIds[i], title)
                            // Background intent to toggle todo — does NOT open app
                            val toggleIntent = HomeWidgetBackgroundIntent.getBroadcast(
                                context,
                                Uri.parse("dailytracker://toggle-todo/$todoId")
                            )
                            views.setOnClickPendingIntent(checkIds[i], toggleIntent)
                        } else {
                            views.setViewVisibility(rowIds[i], android.view.View.GONE)
                        }
                    }
                } else {
                    views.setViewVisibility(R.id.widget_todo_section, android.view.View.GONE)
                }
            } catch (_: Exception) {
                views.setViewVisibility(R.id.widget_todo_section, android.view.View.GONE)
            }

            // ONLY the app name opens the app
            val openAppIntent = HomeWidgetLaunchIntent.getActivity(
                context, MainActivity::class.java, Uri.parse("dailytracker://open")
            )
            views.setOnClickPendingIntent(R.id.widget_app_name, openAppIntent)

            // Mark current block done — background, no app open
            val toggleBlockIntent = HomeWidgetBackgroundIntent.getBroadcast(
                context, Uri.parse("dailytracker://toggle-current")
            )
            views.setOnClickPendingIntent(R.id.widget_done_btn, toggleBlockIntent)

            // Refresh — opens app to sync latest data
            val refreshIntent = HomeWidgetLaunchIntent.getActivity(
                context, MainActivity::class.java, Uri.parse("dailytracker://refresh")
            )
            views.setOnClickPendingIntent(R.id.widget_refresh_btn, refreshIntent)

            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun scheduleAlarm(context: Context) {
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, DailyTrackerWidgetProvider::class.java).apply {
            action = REFRESH_ACTION
        }
        val pending = PendingIntent.getBroadcast(
            context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarm.setRepeating(
            AlarmManager.ELAPSED_REALTIME,
            SystemClock.elapsedRealtime() + INTERVAL_MS,
            INTERVAL_MS,
            pending
        )
    }

    private fun cancelAlarm(context: Context) {
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, DailyTrackerWidgetProvider::class.java).apply {
            action = REFRESH_ACTION
        }
        val pending = PendingIntent.getBroadcast(
            context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarm.cancel(pending)
    }
}
