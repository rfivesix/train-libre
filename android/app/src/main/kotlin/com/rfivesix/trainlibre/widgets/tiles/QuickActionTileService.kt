package com.rfivesix.trainlibre.widgets.tiles

import android.app.PendingIntent
import android.graphics.drawable.Icon
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import com.rfivesix.trainlibre.widgets.QuickAction
import com.rfivesix.trainlibre.widgets.deepLinkIntent

/**
 * A quick action as a Quick Settings tile.
 *
 * The counterpart to the Control Center controls in
 * `ios/TrainLibreLiveActivity/QuickActionIntents.swift`. Each one is a launcher
 * for the same `trainlibre://action/<key>` URL the widget tiles emit, so all
 * three surfaces end in the same handler.
 *
 * One service per action because Android identifies a tile by its component —
 * there is no way to declare seven tiles against one class.
 */
abstract class QuickActionTileService : TileService() {

    protected abstract val action: QuickAction

    override fun onStartListening() {
        super.onStartListening()
        qsTile?.apply {
            label = getString(action.labelRes)
            icon = Icon.createWithResource(this@QuickActionTileService, action.iconRes)
            // These tiles do something rather than toggle something, so they
            // have no on state to report.
            state = Tile.STATE_INACTIVE
            updateTile()
        }
    }

    override fun onClick() {
        super.onClick()
        val intent = deepLinkIntent(this, action.deepLink)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // The Intent overload throws on Android 14 and up rather than
            // merely being deprecated, so this is not an optional migration.
            val pending = PendingIntent.getActivity(
                this,
                action.ordinal,
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            startActivityAndCollapse(pending)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }
}

class AiMealCaptureTileService : QuickActionTileService() {
    override val action = QuickAction.AiMealCapture
}

class ScanBarcodeTileService : QuickActionTileService() {
    override val action = QuickAction.ScanBarcode
}

class StartWorkoutTileService : QuickActionTileService() {
    override val action = QuickAction.StartWorkout
}

class AddMeasurementTileService : QuickActionTileService() {
    override val action = QuickAction.AddMeasurement
}

class LogSupplementTileService : QuickActionTileService() {
    override val action = QuickAction.LogSupplement
}

class AddLiquidTileService : QuickActionTileService() {
    override val action = QuickAction.AddLiquid
}

class AddFoodTileService : QuickActionTileService() {
    override val action = QuickAction.AddFood
}
