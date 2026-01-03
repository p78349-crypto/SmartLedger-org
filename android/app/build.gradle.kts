plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.smartledger"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    lint {
        // Prevent release builds from failing due to Windows file-lock issues in
        // lintVitalAnalyzeRelease lint cache cleanup.
        checkReleaseBuilds = false
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.smartledger"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Keep Android artifacts small: Windows desktop builds are separate, so
        // Android x86_64 is not required unless you target Chromebook/Emulators.
        // Note: Flutter's `--split-per-abi` configures ABI splits; do not set
        // ndk.abiFilters at the same time (Gradle will fail).
        if (!project.hasProperty("split-per-abi")) {
            ndk {
                abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a"))
            }
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
