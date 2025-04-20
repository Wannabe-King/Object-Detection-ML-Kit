plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

dependencies {
    // ML Kit Object Detection
    implementation("com.google.mlkit:object-detection:17.0.1")
    implementation("com.google.mlkit:object-detection-custom:17.0.1")

    // CameraX core libraries


    val camVer = "1.3.0"
    implementation("androidx.camera:camera-core:$camVer")
    implementation("androidx.camera:camera-camera2:$camVer")
    implementation("androidx.camera:camera-lifecycle:$camVer")
    implementation("androidx.camera:camera-view:$camVer")
    implementation("androidx.camera:camera-extensions:$camVer")

    // Optional (logging/debugging)
    implementation("androidx.camera:camera-video:$camVer")
}

android {
    namespace = "com.example.object_dection_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.object_dection_flutter"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
