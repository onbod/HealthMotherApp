plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // ✅ Added correctly for Kotlin DSL
    id("dev.flutter.flutter-gradle-plugin") // Flutter must come last
}

android {
    namespace = "com.example.healthymamaapp"
    ndkVersion = "27.0.12077973"
    compileSdk = 35

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.healthymamaapp"
        minSdk = 23// ✅ Directly set here
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}
dependencies {
  // Import the Firebase BoM
  implementation(platform("com.google.firebase:firebase-bom:33.14.0"))

  // Add the AndroidX Core KTX dependency
  implementation("androidx.core:core-ktx:1.13.1")

  // Core library desugaring
   coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")


  // TODO: Add the dependencies for Firebase products you want to use
  // When using the BoM, don't specify versions in Firebase dependencies
  implementation("com.google.firebase:firebase-analytics")


  // Add the dependencies for any other desired Firebase products
  // https://firebase.google.com/docs/android/setup#available-libraries
}
flutter {
    source = "../.."
}
