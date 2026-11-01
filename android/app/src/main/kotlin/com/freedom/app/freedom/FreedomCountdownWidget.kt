package com.freedom.app.freedom

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Home-screen widget that surfaces the user's "months till freedom" countdown.
 *
 * Data lives in SharedPreferences (written from Flutter via the `home_widget`
 * plugin). Layout uses only RemoteViews-safe widgets so it works on every
 * Android version we ship to.
 */
class FreedomCountdownWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = HomeWidgetPlugin.getData(context)
        for (id in appWidgetIds) {
            val views = buildRemoteViews(context, prefs)
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun buildRemoteViews(
        context: Context,
        prefs: SharedPreferences
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_freedom_countdown)

        val hasLoans = prefs.getBoolean(KEY_HAS_LOANS, false)
        val months = prefs.getInt(KEY_MONTHS, 0)
        val dateLabel = prefs.getString(KEY_DATE_LABEL, "").orEmpty()
        val outflow = prefs.getString(KEY_OUTFLOW, "").orEmpty()
        val progress = prefs.getInt(KEY_PROGRESS, 0).coerceIn(0, 100)
        val nextLender = prefs.getString(KEY_NEXT_LENDER, "").orEmpty()
        val nextLabel = prefs.getString(KEY_NEXT_LABEL, "").orEmpty()

        if (hasLoans) {
            views.setViewVisibility(R.id.filled_section, View.VISIBLE)
            views.setViewVisibility(R.id.empty_section, View.GONE)

            views.setTextViewText(R.id.months_text, months.toString())
            views.setTextViewText(
                R.id.months_unit_text,
                if (months == 1) "month" else "months"
            )
            views.setTextViewText(R.id.date_text, dateLabel)
            views.setTextViewText(R.id.outflow_text, outflow)
            views.setProgressBar(R.id.progress_bar, 100, progress, false)

            val nextText = when {
                nextLender.isNotEmpty() && nextLabel.isNotEmpty() ->
                    "$nextLender • $nextLabel"
                nextLender.isNotEmpty() -> nextLender
                else -> ""
            }
            views.setTextViewText(R.id.next_text, nextText)
            views.setViewVisibility(
                R.id.next_text,
                if (nextText.isEmpty()) View.GONE else View.VISIBLE
            )
        } else {
            views.setViewVisibility(R.id.filled_section, View.GONE)
            views.setViewVisibility(R.id.empty_section, View.VISIBLE)
        }

        // Tap the widget → launch the app.
        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
        if (launchIntent != null) {
            val flags = PendingIntent.FLAG_IMMUTABLE or
                PendingIntent.FLAG_UPDATE_CURRENT
            val pi = PendingIntent.getActivity(context, 0, launchIntent, flags)
            views.setOnClickPendingIntent(R.id.widget_root, pi)
        }

        return views
    }

    private companion object {
        // Keys must match those written by Dart in lib/data/widget_sync.dart.
        const val KEY_HAS_LOANS = "has_loans"
        const val KEY_MONTHS = "months_to_freedom"
        const val KEY_DATE_LABEL = "freedom_date_label"
        const val KEY_OUTFLOW = "monthly_outflow"
        const val KEY_PROGRESS = "progress_percent"
        const val KEY_NEXT_LENDER = "next_due_lender"
        const val KEY_NEXT_LABEL = "next_due_label"
    }
}
