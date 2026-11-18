import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

fun signingValue(name: String, env: String): String? = System.getenv(env) ?: keyProperties.getProperty(name)

val releaseStore: String? = signingValue("storeFile", "YOUPLAY_KEYSTORE")

android {
    namespace = "com.example.sika_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // NewPipeExtractor utilise java.time / java.nio : désucrage requis.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Identifiant public (F-Droid / IzzyOnDroid refusent com.example). L'ancien, com.example.sika_app,
        // reste le namespace du code Kotlin ; LibraryTransfer.kt transfère la bibliothèque de l'ancienne app.
        applicationId = "io.github.cianusdev.youplay"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Clé de release YouPlay (pas la clé de debug : IzzyOnDroid refuse les APK signés en debug).
    // Une mise à jour signée avec une autre clé est refusée par Android (« package en conflit »).
    // CI : variables YOUPLAY_KEYSTORE / YOUPLAY_KEYSTORE_PASSWORD (secrets KEYSTORE_BASE64, KEYSTORE_PASSWORD).
    // Local : android/key.properties (storeFile, password, keyAlias), jamais commité.
    // Sans clé (contributeurs) : build release signé avec la clé de debug de la machine.
    signingConfigs {
        create("youplay") {
            storeFile = releaseStore?.let { file(it) }
            storePassword = signingValue("password", "YOUPLAY_KEYSTORE_PASSWORD")
            keyAlias = signingValue("keyAlias", "YOUPLAY_KEY_ALIAS") ?: "youplay"
            keyPassword = storePassword
        }
    }

    // Le bloc « dependency info » d'AGP est chiffré avec une clé Google, illisible pour les
    // catalogues d'apps libres (IzzyOnDroid, F-Droid) : on ne l'ajoute pas.
    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (releaseStore != null) "youplay" else "debug")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
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
    // Extraction YouTube / YouTube Music (usage personnel).
    implementation("com.github.TeamNewPipe:NewPipeExtractor:v0.26.5")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    // FileProvider : partage de l'APK de mise à jour avec l'installateur.
    implementation("androidx.core:core-ktx:1.13.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs_nio:2.1.5")
}
