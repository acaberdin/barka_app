plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services") // 🔥 Firebase plugin
}

android {
    namespace = "com.boat.barka"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.boat.barka" // ✅ your final app ID
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    // 🔥 Firebase BoM (manages versions automatically)
    implementation(platform("com.google.firebase:firebase-bom:33.5.1"))

    // 🔐 Firebase Auth (login/register)
    implementation("com.google.firebase:firebase-auth")

    // (optional but useful later)
    implementation("com.google.firebase:firebase-firestore")
}