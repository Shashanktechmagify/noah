import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The key that signs the app for Google Play: android/key.properties (never committed; see docs/PLAY-STORE.md).
val keystoreFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystoreFile.exists()) keystoreFile.inputStream().use { keystoreProperties.load(it) }

android {
    namespace = "com.karunasadan.noah"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications (banners while the app is open) needs this.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Permanent: the id of the app in Google Play (it cannot be changed after the first upload).
        applicationId = "com.karunasadan.noah"
        minSdk = 24 // the camera plugin needs API 24+
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystoreFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Signed with the upload key when android/key.properties exists. Without it `flutter run --release` still works
            // (debug keys), but a bundle for Google Play is refused below: Play rejects an app signed with the debug key.
            signingConfig = if (keystoreFile.exists()) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// A bundle for Google Play must be signed with the upload key.
gradle.taskGraph.whenReady {
    if (!keystoreFile.exists() && allTasks.any { it.name == "bundleRelease" }) {
        throw GradleException(
            "android/key.properties is missing, so the bundle would be signed with the debug key and Google Play would refuse it. " +
                "Make the upload key and key.properties first: see docs/PLAY-STORE.md."
        )
    }
}

// Firebase push needs the config file from the Firebase console (not committed), and it must be the one of THIS app's package.
// Without it (or with the file of another package) the app still builds and runs, just without push notifications.
val googleServices = file("google-services.json")
if (googleServices.exists() && Regex("\"package_name\"\\s*:\\s*\"com\\.karunasadan\\.noah\"").containsMatchIn(googleServices.readText())) {
    apply(plugin = "com.google.gms.google-services")
} else {
    logger.warn("android/app/google-services.json is missing or is not for com.karunasadan.noah: building without push notifications.")
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
