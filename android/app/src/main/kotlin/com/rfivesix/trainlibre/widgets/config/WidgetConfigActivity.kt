package com.rfivesix.trainlibre.widgets.config

import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.datastore.preferences.core.MutablePreferences
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.emptyPreferences
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.state.getAppWidgetState
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.glance.state.PreferencesGlanceStateDefinition
import androidx.lifecycle.lifecycleScope
import com.rfivesix.trainlibre.R
import kotlinx.coroutines.launch

/** Writes a configuration into the widget instance's state. */
typealias ConfigWriter = suspend (MutablePreferences) -> Unit

/**
 * Base for the widget configuration screens.
 *
 * These exist because Android has no counterpart to iOS's widget edit sheet: an
 * `AppIntentConfiguration` declares its parameters and the system renders the UI
 * from them, whereas here every configurable widget has to bring its own
 * Activity.
 */
abstract class WidgetConfigActivity : ComponentActivity() {

    protected var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
        private set

    /** The widget being configured, so it can be redrawn once the choice lands. */
    protected abstract val widget: GlanceAppWidget

    protected abstract val titleRes: Int

    /**
     * [current] is this instance's stored configuration, so reopening the screen
     * on an existing widget starts from what it is actually showing rather than
     * from the defaults.
     */
    @Composable
    protected abstract fun Body(current: Preferences, onSave: (ConfigWriter) -> Unit)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Set first and unconditionally: backing out of this screen has to leave
        // the launcher with a cancelled placement rather than a widget that was
        // never configured.
        setResult(RESULT_CANCELED)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        setContent {
            var current by remember { mutableStateOf<Preferences?>(null) }
            LaunchedEffect(appWidgetId) {
                current = runCatching {
                    val glanceId = GlanceAppWidgetManager(this@WidgetConfigActivity)
                        .getGlanceIdBy(appWidgetId)
                    getAppWidgetState(
                        this@WidgetConfigActivity,
                        PreferencesGlanceStateDefinition,
                        glanceId,
                    )
                    // A widget being placed for the first time has no state yet,
                    // and that is not a failure — it is the defaults.
                }.getOrDefault(emptyPreferences())
            }

            ConfigTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .verticalScroll(rememberScrollState())
                            .padding(24.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp),
                    ) {
                        Text(
                            text = stringResource(titleRes),
                            style = MaterialTheme.typography.headlineSmall,
                        )
                        // Nothing is drawn until the stored state is in hand, so
                        // the controls cannot flash the defaults and then jump.
                        current?.let { Body(current = it, onSave = ::save) }
                    }
                }
            }
        }
    }

    /**
     * Writes the choice into this instance's Glance state, redraws it and hands
     * the launcher its widget.
     */
    private fun save(write: ConfigWriter) {
        lifecycleScope.launch {
            val glanceId = GlanceAppWidgetManager(this@WidgetConfigActivity)
                .getGlanceIdBy(appWidgetId)
            updateAppWidgetState(this@WidgetConfigActivity, glanceId, write)
            widget.update(this@WidgetConfigActivity, glanceId)

            setResult(
                RESULT_OK,
                Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId),
            )
            finish()
        }
    }
}

/**
 * The app's accent on Material 3's own surfaces.
 *
 * Deliberately not the full in-app theme: this screen belongs to the launcher's
 * flow, appears for a few seconds, and should read as part of the system rather
 * than as a second, smaller app.
 */
@Composable
private fun ConfigTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = if (isSystemInDarkTheme()) {
            darkColorScheme(primary = Color(0xFFDDFF00), onPrimary = Color.Black)
        } else {
            lightColorScheme(primary = Color(0xFF8B9E00), onPrimary = Color.White)
        },
        content = content,
    )
}

/** One radio row — the shape every one of these screens is built from. */
@Composable
fun ConfigOption(
    label: String,
    selected: Boolean,
    onSelect: () -> Unit,
    subtitle: String? = null,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .selectable(selected = selected, onClick = onSelect)
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        RadioButton(selected = selected, onClick = onSelect)
        Column(modifier = Modifier.padding(start = 8.dp)) {
            Text(text = label, style = MaterialTheme.typography.bodyLarge)
            if (subtitle != null) {
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}

/**
 * A labelled picker.
 *
 * The four action slots offer seven choices each; as radio rows that is
 * twenty-eight lines of scrolling to change one thing. A dropdown keeps the
 * whole screen on one page.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun <T> ConfigDropdown(
    label: String,
    options: List<T>,
    selected: T,
    optionLabel: (T) -> String,
    onSelect: (T) -> Unit,
) {
    var expanded by remember { mutableStateOf(false) }
    ExposedDropdownMenuBox(
        expanded = expanded,
        onExpandedChange = { expanded = it },
        modifier = Modifier.fillMaxWidth(),
    ) {
        OutlinedTextField(
            value = optionLabel(selected),
            onValueChange = {},
            readOnly = true,
            label = { Text(label) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            modifier = Modifier
                .menuAnchor(androidx.compose.material3.MenuAnchorType.PrimaryNotEditable)
                .fillMaxWidth(),
        )
        ExposedDropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            options.forEach { option ->
                DropdownMenuItem(
                    text = { Text(optionLabel(option)) },
                    onClick = {
                        onSelect(option)
                        expanded = false
                    },
                )
            }
        }
    }
}

/** A group heading, for the screens that configure more than one thing. */
@Composable
fun ConfigSection(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.titleSmall,
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier.padding(top = 8.dp),
    )
}

/** The button every configuration screen ends with. */
@Composable
fun ConfigSaveButton(onClick: () -> Unit) {
    Button(onClick = onClick, modifier = Modifier.fillMaxWidth()) {
        Text(text = stringResource(R.string.widget_config_save))
    }
}
