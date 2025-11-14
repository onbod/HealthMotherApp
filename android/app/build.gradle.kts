plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // ✅ Added correctly for Kotlin DSL
    id("dev.flutter.flutter-gradle-plugin") // Flutter must come last
}

android {
    namespace = "com.example.healthymamaapp"
    ndkVersion = "27.0.12077973"
    compileSdk = 36

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
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
        
        // Add multiDex for release builds
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // Add these for debugging release issues
            isDebuggable = false
            isJniDebuggable = false
            isRenderscriptDebuggable = false
        }
        
        // Add debug build type for comparison
        debug {
            isDebuggable = true
            isJniDebuggable = true
            isRenderscriptDebuggable = true
        }
    }
    
    // Add packaging options
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
            excludes += "/META-INF/DEPENDENCIES"
            excludes += "/META-INF/LICENSE"
            excludes += "/META-INF/LICENSE.txt"
            excludes += "/META-INF/NOTICE"
            excludes += "/META-INF/NOTICE.txt"
        }
    }
}
dependencies {
  // Add multiDex support
  implementation("androidx.multidex:multidex:2.0.1")
  
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
