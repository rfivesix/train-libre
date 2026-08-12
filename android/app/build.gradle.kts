// android/app/build.gradle.kts
import java.io.FileInputStream
import java.util.Properties

val localProps = Properties().apply {
    load(rootProject.file("local.properties").inputStream())
}
val flutterVersionName = localProps.getProperty("flutter.versionName") ?: "0.0.0"
val flutterVersionCode = (localProps.getProperty("flutter.versionCode") ?: "1").toInt()

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("org.jetbrains.kotlin.plugin.compose")
    id("org.jetbrains.kotlin.plugin.serialization")
}

android {
    namespace = "com.rfivesix.trainlibre"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    defaultConfig {
        applicationId = "com.rfivesix.trainlibre"
        versionName = flutterVersionName
        versionCode = flutterVersionCode

        minSdk = 26
        targetSdk = 36
    }

    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.getByName("release")
        }
        getByName("debug") { }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_17.toString() }

    // Only the widget configuration Activities are Compose; the app itself
    // stays Flutter.
    buildFeatures { compose = true }
}

flutter { source = "../.." }

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.health.connect:connect-client:1.1.0")
    implementation("androidx.documentfile:documentfile:1.0.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")

    // --- Home screen widgets ---
    // Glance renders the app widgets. It brings DataStore along, which is what
    // backs the per-widget-instance configuration.
    implementation("androidx.glance:glance-appwidget:1.1.1")
    implementation("androidx.glance:glance-material3:1.1.1")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.9.0")
    // 1.16 is the first release carrying setRequestPromotedOngoing, which the
    // workout Live Update needs on Android 16.
    implementation("androidx.core:core-ktx:1.18.0")

    // Compose, for the three widget configuration Activities only.
    // Pinned rather than tracking the newest BOM: Compose 1.12 wants AGP 9.1 and
    // compileSdk 37, which is a toolchain upgrade this change has no business
    // dragging in. 2026.02.01 resolves to Compose 1.10.4, the newest line that
    // still builds against AGP 8.13 / compileSdk 36.
    implementation(platform("androidx.compose:compose-bom:2026.02.01"))
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.activity:activity-compose:1.11.0")
}