import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val envStorePassword = System.getenv("SLD_STORE_PASSWORD")
val envKeyPassword = System.getenv("SLD_KEY_PASSWORD")

val releaseStoreFile = keystoreProperties.getProperty("storeFile")
val releaseKeyAlias = keystoreProperties.getProperty("keyAlias")
val releaseStorePassword =
    if (!envStorePassword.isNullOrBlank()) envStorePassword
    else keystoreProperties.getProperty("storePassword")
val releaseKeyPassword =
    if (!envKeyPassword.isNullOrBlank()) envKeyPassword
    else keystoreProperties.getProperty("keyPassword")

val hasReleaseSigning =
    keystorePropertiesFile.exists() &&
    !releaseStoreFile.isNullOrBlank() &&
    !releaseKeyAlias.isNullOrBlank() &&
    !releaseStorePassword.isNullOrBlank() &&
    !releaseKeyPassword.isNullOrBlank()

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.smartledger"
    // Required for App Actions shortcuts.xml attributes like android:entitySetId
    // and android:alternateName.
    // Several Flutter plugins and recent AndroidX libraries now require
    // compiling against android-36 (backward compatible).
    compileSdk = 36
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

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    buildFeatures {
        buildConfig = true
    }

    signingConfigs {
        // 프로덕션 keystore 설정 (key.properties 파일이 있을 때만 사용)
        create("release") {
            if (hasReleaseSigning) {
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword!!
                keyAlias = releaseKeyAlias!!
                keyPassword = releaseKeyPassword!!
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.smartledger"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        // Keep runtime behavior stable; compileSdk can be higher than targetSdk.
        targetSdk = 34
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
            // key.properties가 있으면 release 키 사용, 없으면 debug 키
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            
            // 📦 앱 크기 최적화: 코드 축소 및 리소스 압축
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // 🔒 AI 규제 준수로 제외: MediaPipe LLM Inference API 사용 중단
    // MediaPipe LLM Inference API (온디바이스 AI) - 18개국 규제 준수로 비활성화
    // 공식 문서: https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference/android
    // implementation("com.google.mediapipe:tasks-genai:0.10.14")  # AI 규제로 제외
    
    // Kotlin Coroutines (비동기 처리) - AI 비의존 기능이므로 유지
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.0")
}

