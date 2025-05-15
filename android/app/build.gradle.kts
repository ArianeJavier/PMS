plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.intimacare_client"
    compileSdk = 35 // Updated to latest SDK (or at least 33+ for JDK 17 support)
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17" // Fixed: Changed single quotes to double quotes for consistency
    }

    defaultConfig {
        applicationId = "com.example.intimacare_client"
        minSdk = 21
        targetSdk = 35 // Updated to match compileSdk
        versionCode = flutter.versionCode.toInt() // Added toInteger() for type safety
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            // Add these for release builds
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Add any additional dependencies here if needed
}