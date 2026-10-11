# Import workout history and other data

Bring workout history from another tracking app into Train Libre, or restore a Train Libre backup and import shared items.

## Import workout history

Train Libre accepts workout exports in **CSV** and **XLSX** format, including exports from Hevy and Strong.

1. Open **Profile** > **Settings** and choose **Data backup & import** to open the **Data Hub**. During first-time setup, you can also choose **Import Workout Data** on the workout import step.
2. In the Data Hub, tap **External Workout Import**. Choose **Metric (kg)** or **Imperial (lbs)** to tell Train Libre which unit the file uses.
3. Select the exported `.csv` or `.xlsx` file. For XLSX files, the importer reads the first worksheet.
4. Review the preview, including workout and set counts, rows skipped for invalid dates, and any duplicate workouts. Tap **Import Workout Data** to continue, or **Cancel** to stop.
5. If Train Libre finds exercise names that are not in its catalog, match them on the **Exercise Mapping** screen. Imported workouts are saved as completed workouts.

Train Libre detects Hevy and Strong export layouts from their column headers; other CSV and XLSX files use the generic importer. The generic importer still needs a date column and recognizable workout and exercise fields. Prepare other files using [Prepare a compatible workout CSV](prepare_csv_files.md) for the supported column names and date formats.

The importer skips rows with missing or invalid dates and skips workouts already present with the same title and start time. It adds workout history; it does not replace your existing records. Workout files are processed on your device. If anonymous analytics is enabled, Train Libre records whether you started, skipped, or completed an import, but not workout details.

## Restore a Train Libre backup

A full backup restores a broader set of Train Libre data, such as your profile, settings, workout history, food diary, measurements, supplements, and plans. Restoring replaces the data currently in the app.

1. Open **Profile** > **Settings** > **Data backup & import** to open the **Data Hub**, then tap **Import** in **Train Libre Data Backup**.
2. Select a `.zip` backup, or an older `.json` backup. If the backup is encrypted, enter its password when prompted.
3. Confirm the overwrite prompt. After restoration, Train Libre returns you to onboarding to finish setup with the restored data.

You can also choose **Restore from Backup** on the welcome screen during onboarding. The exercise catalog must be initialized before a backup can be restored; if it is not ready, Train Libre will prompt you to download the required catalog first. Treat restoration as a replacement, not a merge: make sure the backup is the one you want before confirming.

## Import shared items

The Data Hub can also import an individual routine, training plan, recipe, or workout from Train Libre JSON content.

1. In the Data Hub, choose **Import shared JSON file** to select a `.json` file, or choose **Paste JSON text** to paste the complete Train Libre JSON content.
2. Review the preview and confirm with **Import to Train Libre**.

Shared items are added as new items, leaving existing items in place. A shared workout is added to workout history. This is separate from restoring a full backup.

## Import health data

Train Libre can read steps, sleep, heart-rate samples, and body measurements from the health store available on your device. These imports require access to **Apple Health** on iOS or **Health Connect** on Android.

1. Open **Profile** > **Settings** > **Health**. The page is labeled **Apple Health** on iOS and **Health Connect** on Android.
2. Turn on **Enable steps tracking**, **Enable sleep tracking**, or **Enable pulse analysis** as needed, and grant the requested access. For body measurements, use the switch labeled **Import body measurements from Apple Health** or **Import body measurements from Health Connect**.
3. To fetch records now, use **Sync steps now**, **Import sleep data now**, or **Import now** under body measurements. Pulse has no separate manual import button; enabling **Enable pulse analysis** grants the access used by the pulse view.

**Import sleep data now** reads up to the last 365 days of available sleep history. **Sync steps now** refreshes recent step data. Body-measurement imports read weight and body-fat values; Apple Health imports waist measurements as well. Train Libre skips its own measurement records. Health Connect may limit body-measurement history to recent records unless full history access is available. Once enabled, body-measurement imports also run when Train Libre next starts. These reads come directly from the device health store; Train Libre does not route them through a cloud sync service. For more about the health connection, see [Health sync and export](../features/health_sync_export.md).

If no sleep data appears, check the read permissions in Apple Health on iOS or the Health Connect app on Android. The health store or its permissions may also be unavailable on the device.
