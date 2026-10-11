# Exporting and backing up data

Save a complete Train Libre backup for safekeeping or moving your data, or export selected history for use in another app.

## Create a full backup

1. Open **Profile** > **Settings** > **Data backup & import** to open the **Data Hub**.
2. Under **Train Libre Data Backup**, tap **Export**.
3. Choose a destination in the system share sheet, such as a files app or a cloud storage app, and save or send the `.zip` file.

The full backup contains your profile and app settings, workout history and plans, food and fluid logs, supplements, measurements, and supported activity and sleep records. It also includes meal and workout preview images. A full backup is for restoring Train Libre data; it is not the same as exporting a spreadsheet. To restore one, see [Import workout history and other data](importing_data.md#restore-a-train-libre-backup). Restore replaces the data currently in Train Libre.

To make a password-protected backup, tap **Export Encrypted**, enter a password, and save the `.zip` from the share sheet. Keep the password somewhere safe: it is required to restore the backup. The regular **Export** option does not ask for a password.

## Export selected history

1. In **Profile** > **Settings** > **Data backup & import** > **Data Hub**, scroll to the export options below the backup and automatic backup sections.
2. Choose **Excel Export (.xlsx)**, **Nutrition Diary**, **Measurements**, or **Workout History**.
3. Choose where to save or send the generated file in the system share sheet.

**Excel Export (.xlsx)** creates one workbook with separate sheets for nutrition, workouts and exercises, sleep, activity and health data, and measurements. The other options share focused CSV files: **Nutrition Diary** includes food and fluid entries; **Workout History** includes set-level workout history; **Measurements** can share measurement, sleep, steps, and heart-rate history files. These exports are useful for analysis, but do not contain everything needed to restore Train Libre.

## Automatic backups on Android and other non-Apple platforms

The Data Hub's **Automatic Backups** section saves a full `.zip` backup about once a day when Train Libre runs. It keeps up to seven recent automatic backups in the destination folder. On Android, tap **Choose Folder** to select a storage folder; if no folder is selected or it cannot be used, the backup may be saved in the app's documents folder instead. The last backup path is shown in the section. Tap **Check & Run Auto-Backup Now** to create one immediately. These files are local unless you choose a folder that is itself provided or synced by another storage app.

## Automatic iCloud backup on Apple platforms

On iOS and macOS, use the iCloud backup switch in the Data Hub to enable automatic iCloud backup. Enabling it starts an initial backup; after that, Train Libre attempts to upload a backup when the app goes into the background. Automatic uploads are limited to no more than once every five minutes. The card shows the last successful sync time. Tap **Backup to iCloud Now** to start an upload yourself. Train Libre keeps the current backup and one previous copy in its iCloud container.

This iCloud backup is separate from **Export** and its share sheet. To restore an iCloud backup on an Apple device, choose the iCloud restore option during onboarding. iCloud availability and account access are required; if no backup is found, use a saved full backup instead.

## Exporting to Apple Health or Health Connect

Health export writes supported Train Libre records to the health store on your device; it does not create a backup file. In **Profile** > **Settings** > **Health**, enable **Apple Health export** on iOS or **Health Connect export** on Android and grant access. Tap **Export now** to run an export. For details about supported data and the one-way connection, see [Health sync and export](../features/health_sync_export.md).
