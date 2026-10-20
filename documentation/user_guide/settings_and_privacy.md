# Manage app support and privacy settings

Find the app tour, send a diagnostic report, manage optional usage statistics, review legal information, or reset Train Libre’s local data.

## Reopen the app tour

1. Open **Profile** and tap **Settings**.
2. Under **Support / About**, tap **View App Tour**. Train Libre returns to the start of the app and runs the short in-app walkthrough again.

## Send a feedback report

1. In **Profile > Settings**, under **Support / About**, tap **Send feedback**.
2. In **Feedback report**, optionally enter a note describing what happened and what you expected.
3. Under **Include in report**, switch off any sections you do not want to include: **Adaptive nutrition diagnostics**, **Backup / restore diagnostics**, **Performance log (frame timings)**, or **User note**.
4. Tap **Generate preview** and review the report. Nothing is sent automatically.
5. Choose **Copy**, **Save**, **Share**, or **Email**. Email opens a draft addressed to the developer so you can review or edit it before sending. **Send directly to developer** requires **Share pseudonymised usage statistics** to be enabled; otherwise, use one of the other options.

The preview shows what will be included. Reports can contain app and device details, selected diagnostic information, and your note. Copying, saving, sharing, and emailing are actions you control; review the preview before using them.

## Manage optional usage statistics

1. Open **Profile > Settings** and find **Share pseudonymised usage statistics** under **Support / About**.
2. Turn the switch on or off. The setting is optional and can be changed later.
3. To request deletion of telemetry identifiers and past telemetry data, tap **Delete telemetry data**, review the confirmation, and choose **Delete data now**. This resets local telemetry identifiers and counters and sends a deletion request to the PostHog server in the EU. It does not delete your workouts, food logs, or other app records.

The app describes this telemetry as pseudonymised usage information, such as screen views, feature use, and error reports, without names, email addresses, or personal or health records. See **Privacy Policy** in the Legal screen for the full privacy terms.

## Review app and legal information

1. Open **Profile**.
2. Tap **About Train Libre** to see the app version, build number, release notes, used libraries, licensing information, project website, repository, and data attributions.
3. Return to **Profile** and tap **Legal** to read the **Legal Notice**, **Privacy Policy**, and **Terms of Service**. Tap **View in browser** to open the privacy page on the project website.

## Delete all local app data

This reset permanently removes locally stored workouts, nutrition logs, measurements, supplements, settings and state, cached analytics, and other local app data. It does not remove data already exported to Apple Health or Health Connect, data held by external providers, or remote public food catalogs. Required bundled assets and catalogs are kept or recreated so the app can start again.

1. Open **Profile > Settings** and scroll to **Local app data**.
2. Tap **Delete all local app data** and read the confirmation carefully.
3. Type **DELETE** in the confirmation field, then tap **Delete**.
4. After the reset completes, acknowledge the success message. Train Libre restarts and returns to its initial setup state.

This action cannot be undone. Export or back up anything you want to keep first; see [Export and back up data](exporting_and_backing_up.md).

## Developer tools

The **Developer** entry in **Profile > Settings** opens diagnostics and experimental options intended for troubleshooting and app development. These controls can expose diagnostic data or change experimental behavior, so they are not part of the regular setup workflow.
