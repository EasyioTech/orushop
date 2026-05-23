import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Read key.properties as source of truth; env vars can override for CI.
val keyProps = Properties().also { props ->
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { props.load(it) }
}
// key.properties wins on local machine; env vars are CI fallback (no key.properties in CI).
fun keyProp(envKey: String, propKey: String, default: String) =
    keyProps.getProperty(propKey) ?: System.getenv(envKey) ?: default

android {
    namespace = "com.orushops.orushops"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        getByName("debug") {
            keyAlias = "androiddebugkey"
            keyPassword = "Easyioroot@123"
            storeFile = file("$rootDir/debug.keystore")
            storePassword = "Easyioroot@123"
        }
        create("release") {
            keyAlias = keyProp("KEY_ALIAS", "keyAlias", "orushops")
            keyPassword = keyProp("KEY_PASSWORD", "keyPassword", "OruShops@123")
            storeFile = rootProject.file(keyProp("STORE_FILE", "storeFile", "app/orushops-release-jks.jks"))
            storePassword = keyProp("STORE_PASSWORD", "storePassword", "OruShops@123")
        }
    }

    defaultConfig {
        applicationId = "com.orushops.orushops"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // integration_test is dev_dependency — compileOnly keeps it off the release APK
    // while satisfying GeneratedPluginRegistrant.java compile-time reference (flutter#56591)
    compileOnly(project(":integration_test"))
}

tasks.withType<JavaCompile> {
    options.compilerArgs.add("-Xlint:-options")
}
