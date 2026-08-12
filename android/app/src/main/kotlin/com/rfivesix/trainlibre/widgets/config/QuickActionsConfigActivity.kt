package com.rfivesix.trainlibre.widgets.config

import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.datastore.preferences.core.Preferences
import androidx.glance.appwidget.GlanceAppWidget
import com.rfivesix.trainlibre.R
import com.rfivesix.trainlibre.widgets.QuickAction
import com.rfivesix.trainlibre.widgets.QuickActionsWidget
import com.rfivesix.trainlibre.widgets.glance.WidgetConfig

/**
 * The four action slots of the quick access widget.
 *
 * Counterpart to `QuickActionsConfigIntent` in
 * `ios/TrainLibreLiveActivity/QuickActionsWidget.swift`. Every slot offers every
 * action, including one already chosen elsewhere — the same as on iOS, where the
 * four pickers share a case list.
 */
class QuickActionsConfigActivity : WidgetConfigActivity() {

    override val widget: GlanceAppWidget = QuickActionsWidget()
    override val titleRes = R.string.widget_quick_actions_name

    private val slotTitles = listOf(
        R.string.widget_quick_actions_slot1,
        R.string.widget_quick_actions_slot2,
        R.string.widget_quick_actions_slot3,
        R.string.widget_quick_actions_slot4,
    )

    @Composable
    override fun Body(current: Preferences, onSave: (ConfigWriter) -> Unit) {
        val context = LocalContext.current
        val slots = remember(current) {
            mutableStateListOf(
                *List(slotTitles.size) { index ->
                    QuickAction.fromKey(current[WidgetConfig.slotKey(index)])
                        ?: QuickAction.defaultSlots[index]
                }.toTypedArray(),
            )
        }

        slotTitles.forEachIndexed { index, titleRes ->
            ConfigDropdown(
                label = stringResource(titleRes),
                options = QuickAction.entries,
                selected = slots[index],
                optionLabel = { context.getString(it.labelRes) },
                onSelect = { slots[index] = it },
            )
        }

        ConfigSaveButton {
            onSave { prefs ->
                slots.forEachIndexed { index, action ->
                    prefs[WidgetConfig.slotKey(index)] = action.key
                }
            }
        }
    }
}
