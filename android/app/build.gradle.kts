import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val isReleaseBuild = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use(keystoreProperties::load)
}

android {
    namespace = "com.dashcore.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(
                org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
            )
        }
    }

    defaultConfig {
        applicationId = "com.dashcore.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

    }

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

    androidResources {
        noCompress += listOf("glb", "gltf")
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true

            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else if (isReleaseBuild) {
                throw GradleException(
                    "Missing android/key.properties. Configure the private release keystore before building release artifacts."
                )
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.android.play:core:1.10.3")
}
