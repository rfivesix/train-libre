package com.rfivesix.trainlibre.widgets

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.LocalContext
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.rfivesix.trainlibre.R
import com.rfivesix.trainlibre.widgets.glance.SnapshotWidget
import com.rfivesix.trainlibre.widgets.glance.openOnTap
import com.rfivesix.trainlibre.widgets.snapshot.HomeWidgetRecovery
import com.rfivesix.trainlibre.widgets.snapshot.HomeWidgetRecoveryState
import com.rfivesix.trainlibre.widgets.snapshot.HomeWidgetSnapshot
import com.rfivesix.trainlibre.widgets.theme.RoundedShape
import com.rfivesix.trainlibre.widgets.theme.StatsActionPill
import com.rfivesix.trainlibre.widgets.theme.StatsHeader
import com.rfivesix.trainlibre.widgets.theme.StatsPalette
import com.rfivesix.trainlibre.widgets.theme.StatsTheme
import com.rfivesix.trainlibre.widgets.theme.provider
import com.rfivesix.trainlibre.widgets.theme.roundedBackground
import com.rfivesix.trainlibre.widgets.theme.statsWidgetContainer

/**
 * The muscle readiness card.
 *
 * Port of `RecoveryWidget` in `ios/TrainLibreLiveActivity/RecoveryWidget.swift`.
 * Composed rather than drawn: the pills are text on a bordered surface, which
 * Glance can express, and keeping them as real text means they scale with the
 * user's font size and are readable by TalkBack.
 */
class RecoveryWidget : SnapshotWidget() {

    @Composable
    override fun Content(snapshot: HomeWidgetSnapshot?) {
        val context = LocalContext.current
        val palette = StatsPalette.of(context)
        val recovery = snapshot?.recovery
        val hasData = recovery != null && recovery.hasData && recovery.states.isNotEmpty()

        Column(
            modifier = GlanceModifier
                .statsWidgetContainer(palette)
                .openOnTap(WidgetDeepLinks.RECOVERY),
        ) {
            StatsHeader(
                title = context.getString(R.string.widget_recovery_name),
                palette = palette,
                chip = if (hasData) context.getString(R.string.widget_recovery_chip) else null,
            )
            Spacer(GlanceModifier.height(4.dp))

            Text(
                text = recovery?.headline.orEmpty(),
                maxLines = 2,
                style = StatsTheme.headlineStyle.copy(
                    color = if (hasData) {
                        palette.stateColor(recovery?.headlineColorHex).provider()
                    } else {
                        palette.secondaryText.provider()
                    },
                ),
            )

            Spacer(GlanceModifier.defaultWeight())

            if (hasData && recovery != null) {
                States(recovery, palette)
            } else {
                EmptyBody(palette)
            }
        }
    }

    @Composable
    private fun States(recovery: HomeWidgetRecovery, palette: StatsPalette) {
        Row(modifier = GlanceModifier.fillMaxWidth()) {
            recovery.states.forEachIndexed { index, state ->
                if (index > 0) Spacer(GlanceModifier.width(StatsTheme.rowSpacing))
                Box(modifier = GlanceModifier.defaultWeight()) {
                    StatePill(state, palette)
                }
            }
        }
    }

    /**
     * One of the three readiness counts — count, label, share.
     *
     * Two nested boxes rather than one bordered shape: a `ColorFilter` tints a
     * whole drawable, so a fill and a border that need different colours cannot
     * share one. The outer box is the ring, the inner one covers all but a
     * hairline of it.
     */
    @Composable
    private fun StatePill(state: HomeWidgetRecoveryState, palette: StatsPalette) {
        Box(
            modifier = GlanceModifier
                .fillMaxWidth()
                .roundedBackground(palette.stateBorder(state.colorHex), RoundedShape.PillStroke)
                .padding(1.dp),
        ) {
            Column(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .roundedBackground(palette.secondarySurface, RoundedShape.Pill)
                    .padding(horizontal = 12.dp, vertical = 10.dp),
            ) {
                Text(
                    text = state.count.toString(),
                    maxLines = 1,
                    style = TextStyle(
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                        color = palette.stateColor(state.colorHex).provider(),
                    ),
                )
                Spacer(GlanceModifier.height(3.dp))
                Text(
                    text = state.label,
                    maxLines = 1,
                    style = TextStyle(
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium,
                        color = palette.onSurface.provider(),
                    ),
                )
                Spacer(GlanceModifier.height(3.dp))
                Text(
                    text = "${state.percent}%",
                    maxLines = 1,
                    style = TextStyle(fontSize = 12.sp, color = palette.secondaryText.provider()),
                )
            }
        }
    }

    /** No workout has been logged yet, so there is nothing to recover from. */
    @Composable
    private fun EmptyBody(palette: StatsPalette) {
        val context = LocalContext.current
        Column(
            modifier = GlanceModifier
                .fillMaxWidth()
                .roundedBackground(palette.secondarySurface, RoundedShape.Pill)
                .padding(12.dp),
            horizontalAlignment = Alignment.Start,
        ) {
            Text(
                text = context.getString(R.string.widget_recovery_empty_body),
                maxLines = 2,
                style = TextStyle(fontSize = 12.sp, color = palette.secondaryText.provider()),
            )
            Spacer(GlanceModifier.height(9.dp))
            StatsActionPill(
                label = context.getString(R.string.widget_start_workout),
                deepLink = WidgetDeepLinks.action(QuickAction.StartWorkout.key),
                palette = palette,
            )
        }
    }
}

class RecoveryWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = RecoveryWidget()
}
