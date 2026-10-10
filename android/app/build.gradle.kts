import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing. Put a real upload key in android/key.properties (never
// commit it) and the release build is signed with it; without one it falls
// back to the debug key, which installs and runs but cannot go to the Play
// Store. Expected keys: storeFile, storePassword, keyAlias, keyPassword.
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

// `flutter build apk --target-platform android-arm64` (tool/build_release_apk.sh
// arm64) is meant to be one 64-bit-ARM APK. Flutter narrows its own libraries
// to that, but the plugins' native libraries (the audio engine and its codecs)
// were still packed for every other CPU too: 6.5 MB of libraries that cannot
// run without the engine beside them. Leave them out for that build only —
// debug builds on an x86 emulator still need them.
val arm64Only = (project.findProperty("target-platform") as String?) == "android-arm64"

android {
    namespace = "com.nammaflutter.dashkart"

    packaging {
        jniLibs {
            if (arm64Only) {
                excludes += listOf("lib/armeabi-v7a/**", "lib/x86/**", "lib/x86_64/**")
            }
        }
    }
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.nammaflutter.dashkart"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keyProperties.containsKey("storeFile")) {
            create("release") {
                storeFile = rootProject.file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keyProperties.containsKey("storeFile")) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // Shrink the Java/Kotlin side (Firebase and the Flutter embedding)
            // with R8, and drop resources nothing references. Dart code and
            // assets are unaffected; those are sized by the flags in
            // tool/build_release_apk.sh and the asset list in pubspec.yaml.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
