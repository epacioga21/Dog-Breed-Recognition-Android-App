plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle plugin (folosit în build.gradle.kts pentru Flutter module)
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.dog_breed_identifier"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.dog_breed_identifier"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    aaptOptions {
        noCompress += listOf("tflite", "lite")
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:2.1.20")
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.annotation:annotation:1.9.1")
// Flutter embedding este adăugat au
}