package com.rfivesix.trainlibre.widgets

import androidx.annotation.DrawableRes
import androidx.annotation.StringRes
import androidx.compose.ui.graphics.Color
import com.rfivesix.trainlibre.R

/**
 * The actions the quick access widget and the Quick Settings tiles can trigger.
 *
 * Kept in lockstep with `QuickActionKind` in
 * `ios/TrainLibreLiveActivity/QuickActionEntity.swift`, with `HomeWidgetAction`
 * in `lib/features/home_widgets/home_widget_deep_link.dart`, and with the
 * `action` strings in `MainScreen._executeAddMenuAction` — a tap here ends up in
 * the same handler as the in-app speed dial.
 *
 * Declared in the order the iOS enum uses, which is also the order the
 * configuration screen offers.
 */
enum class QuickAction(
    /** The key that travels in the deep link. */
    val key: String,
    @StringRes val labelRes: Int,
    @DrawableRes val iconRes: Int,
    val tint: Color,
) {
    AiMealCapture(
        key = "ai_meal_capture",
        labelRes = R.string.quick_action_ai_meal_capture,
        iconRes = R.drawable.ic_widget_ai_meal_capture,
        tint = Color(0xFF7C5CFF),
    ),
    ScanBarcode(
        key = "scan_barcode",
        labelRes = R.string.quick_action_scan_barcode,
        iconRes = R.drawable.ic_widget_scan_barcode,
        tint = Color(0xFF2196F3),
    ),
    StartWorkout(
        key = "start_workout",
        labelRes = R.string.quick_action_start_workout,
        iconRes = R.drawable.ic_widget_start_workout,
        tint = Color(0xFFE5253A),
    ),
    AddMeasurement(
        key = "add_measurement",
        labelRes = R.string.quick_action_add_measurement,
        iconRes = R.drawable.ic_widget_add_measurement,
        tint = Color(0xFF66BB6A),
    ),
    LogSupplement(
        key = "log_supplement",
        labelRes = R.string.quick_action_log_supplement,
        iconRes = R.drawable.ic_widget_log_supplement,
        tint = Color(0xFFBA68C8),
    ),
    AddLiquid(
        key = "add_liquid",
        labelRes = R.string.quick_action_add_liquid,
        iconRes = R.drawable.ic_widget_add_liquid,
        tint = Color(0xFF00A9C4),
    ),
    AddFood(
        key = "add_food",
        labelRes = R.string.quick_action_add_food,
        iconRes = R.drawable.ic_widget_add_food,
        tint = Color(0xFFFF9800),
    );

    /** Whether the action is offered at all — AI capture follows the app's setting. */
    fun isAvailable(isAiEnabled: Boolean): Boolean =
        this != AiMealCapture || isAiEnabled

    val deepLink: String get() = WidgetDeepLinks.action(key)

    companion object {
        fun fromKey(key: String?): QuickAction? = entries.firstOrNull { it.key == key }

        /**
         * What a freshly added widget shows before it has been configured — the
         * four the app's own speed dial puts first, minus the AI action, which
         * may be switched off.
         */
        val defaultSlots = listOf(AddFood, AddLiquid, StartWorkout, AddMeasurement)
    }
}
