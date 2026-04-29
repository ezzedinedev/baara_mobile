plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Google Services : lit android/app/google-services.json et genere les
    // ressources Firebase au build.
    id("com.google.gms.google-services")
    // Crashlytics Gradle plugin : upload des mappings d'obfuscation
    // pour deobfusquer les stack traces remontees en prod.
    id("com.google.firebase.crashlytics")
}

android {
    namespace = "com.opportune.bf"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Requis par flutter_local_notifications pour utiliser des APIs
        // Java 8+ (java.time, etc.) sur les vieux Android. Sans ca, build
        // fail avec "core library desugaring required".
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.opportune.bf"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Polyfill des APIs Java 8+ pour les minSdk < 26.
    // Requis par flutter_local_notifications (cf. compileOptions plus haut).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
