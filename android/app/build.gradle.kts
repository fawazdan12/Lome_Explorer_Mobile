import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Charger les propriétés de la clé de signature
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    try {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
        println("✅ key.properties chargé avec succès")
    } catch (e: Exception) {
        println("❌ Erreur lors du chargement de key.properties: ${e.message}")
    }
} else {
    println("⚠️ ATTENTION: key.properties non trouvé dans ${keystorePropertiesFile.absolutePath}")
}

android {
    namespace = "com.example.event_flow"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.event_flow"
        minSdk = 21
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Configuration de signature pour la release
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Utiliser la configuration de signature pour la release
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                // Fallback sur debug si key.properties n'existe pas
                println("⚠️ Utilisation de la clé de debug pour la release")
                signingConfigs.getByName("debug")
            }
            
            // Optimisations pour la release
            isMinifyEnabled = false
            isShrinkResources = false
        }
        
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("androidx.multidex:multidex:2.0.1")
    
    // Pour les notifications locales
    implementation("androidx.work:work-runtime:2.8.1")
    implementation("androidx.core:core:1.10.1")
}