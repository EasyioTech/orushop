pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version("4.3.15") apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")

// integration_test is a dev_dependency (excluded by flutter-plugin-loader) but
// GeneratedPluginRegistrant.java still references IntegrationTestPlugin at compile time.
// Include it as a project so javac can resolve the class (flutter/flutter#56591).
val integrationTestPath = run {
    val props = java.util.Properties()
    file("local.properties").inputStream().use { props.load(it) }
    "${props.getProperty("flutter.sdk")}/packages/integration_test/android"
}
include(":integration_test")
project(":integration_test").projectDir = file(integrationTestPath)

