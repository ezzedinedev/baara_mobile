import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Google Services : lit android/app/google-services.json et genere les
    // ressources Firebase au build.
    id("com.google.gms.google-services")
    // Crashlytics Gradle plugin : upload des mappings d'obfuscation
    // pour deobfusquer les stack traces remontees en prod.
    id("com.google.firebase.crashlytics")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val releaseSigningKeys = listOf("storePassword", "keyPassword", "keyAlias", "storeFile")
val hasReleaseSigning = releaseSigningKeys.all {
    keystoreProperties.getProperty(it)?.isNotBlank() == true
}
android {
    namespace = "com.opportune.bf"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "30.0.14904198"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Requis par flutter_local_notifications pour utiliser des APIs
        // Java 8+ (java.time, etc.) sur les vieux Android. Sans ca, build
        // fail avec "core library desugaring required".
        isCoreLibraryDesugaringEnabled = true
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

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

// Migration vers le nouveau DSL compilerOptions requis par Kotlin 2.x+
// pour aligner le target JVM avec celui de Java (17).
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Polyfill des APIs Java 8+ pour les minSdk < 26.
    // Requis par flutter_local_notifications (cf. compileOptions plus haut).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
gradle.taskGraph.whenReady {
    val runsReleaseBuild = allTasks.any { task ->
        task.name.contains("Release", ignoreCase = true)
    }
    if (runsReleaseBuild && !hasReleaseSigning) {
        throw GradleException(
            "Release signing is not configured. Copy android/key.properties.example " +
                "to android/key.properties and fill it with your keystore values."
        )
    }
}
