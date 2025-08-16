plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Firebase plugin
}

android {
    namespace = "com.example.my_app"
    compileSdk = 35 // Replace flutter.compileSdkVersion with explicit value
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.my_app"
        minSdk = 23 // Replace flutter.minSdkVersion
        targetSdk = 34 // Replace flutter.targetSdkVersion
        versionCode = 1 // Replace flutter.versionCode
        versionName = "1.0" // Replace flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase libraries with explicit versions
    implementation("com.google.firebase:firebase-storage-ktx:21.0.0")
    implementation("com.google.firebase:firebase-auth-ktx:22.3.1")
    implementation("com.google.firebase:firebase-analytics-ktx:22.1.0")
}

