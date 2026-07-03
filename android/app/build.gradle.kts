import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

fun loadProperties(path: java.io.File): Properties {
    val properties = Properties()
    if (path.exists()) {
        path.inputStream().use { properties.load(it) }
    }
    return properties
}

val localProperties = loadProperties(rootProject.file("local.properties"))
val secretsProperties = loadProperties(rootProject.file("secrets.properties"))

val googleMapsApiKey =
    secretsProperties.getProperty("google.maps.api.key")?.trim().orEmpty()
        .ifEmpty { localProperties.getProperty("google.maps.api.key")?.trim().orEmpty() }
        .ifEmpty { System.getenv("GOOGLE_MAPS_API_KEY")?.trim().orEmpty() }

if (googleMapsApiKey.isEmpty()) {
    logger.warn(
        """
        |
        | *** Google Maps API key is missing ***
        | Add your key to android/secrets.properties:
        |   google.maps.api.key=AIza...
        | Copy android/secrets.properties.example to get started.
        |
        """.trimMargin(),
    )
}

android {
    namespace = "com.example.car_washing_app"
    compileSdk = 36
    ndkVersion = "26.1.10909125"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.car_washing_app"
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode()
        versionName = flutter.versionName()
        resValue("string", "google_maps_api_key", googleMapsApiKey)
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
