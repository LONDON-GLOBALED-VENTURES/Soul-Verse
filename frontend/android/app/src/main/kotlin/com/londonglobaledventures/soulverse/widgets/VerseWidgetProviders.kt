package com.londonglobaledventures.soulverse.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import com.londonglobaledventures.soulverse.MainActivity
import com.londonglobaledventures.soulverse.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Shows the verse image the Flutter app rendered for this size (see home_widget_service.dart),
 * or plain text until the app has run once.
 */
abstract class VerseWidgetProvider(private val imageKey: String) : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val bitmap = widgetData.getString(imageKey, null)?.let(BitmapFactory::decodeFile)

        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.verse_widget).apply {
                if (bitmap != null) {
                    setImageViewBitmap(R.id.widget_image, bitmap)
                    setViewVisibility(R.id.widget_image, View.VISIBLE)
                    setViewVisibility(R.id.widget_fallback, View.GONE)
                } else {
                    setViewVisibility(R.id.widget_image, View.GONE)
                    setViewVisibility(R.id.widget_fallback, View.VISIBLE)
                    setTextViewText(
                        R.id.widget_text,
                        widgetData.getString("verse_text", null)
                            ?: context.getString(R.string.verse_widget_empty),
                    )
                    setTextViewText(
                        R.id.widget_reference,
                        widgetData.getString("verse_reference", null) ?: "",
                    )
                }
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

class VerseWidgetSmall : VerseWidgetProvider("verse_image_small")

class VerseWidgetMedium : VerseWidgetProvider("verse_image_medium")

class VerseWidgetLarge : VerseWidgetProvider("verse_image_large")
