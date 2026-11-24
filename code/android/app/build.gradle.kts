plugins {
    id("com.android.application")

    // Apply Flutter after the Android application plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.code"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Support Java APIs used by scheduled notifications.
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.code"

        // Use the Android SDK versions configured by Flutter.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        // Read the app version from pubspec.yaml.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Use debug signing for local testing and the course demo.
            signingConfig = signingConfigs.getByName("debug")
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

dependencies {
    // Required for Android notification scheduling.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}