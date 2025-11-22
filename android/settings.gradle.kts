// =============================================
// ✅ Flutter 3.35.x – settings.gradle.kts chuẩn
// =============================================
pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val localPropertiesFile = File(settingsDir, "local.properties")

        require(localPropertiesFile.exists()) {
            "❌ Không tìm thấy local.properties tại: ${localPropertiesFile.absolutePath}"
        }

        localPropertiesFile.inputStream().use { properties.load(it) }

        val flutterSdk = properties.getProperty("flutter.sdk")
        require(flutterSdk != null) { "❌ Thiếu thuộc tính flutter.sdk trong local.properties" }

        println(">>> 🟢 Using Flutter SDK at: $flutterSdk")
        flutterSdk
    }

    // 🔧 Đường dẫn Flutter tools – tuyệt đối KHÔNG hard-code
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

// =============================
// 🧩 Khai báo plugins Gradle
// =============================
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false

    // START: FlutterFire configuration
    id("com.google.gms.google-services") version "4.3.15" apply false
    // END: FlutterFire configuration

    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

// =============================
// 📦 Include module chính
// =============================
include(":app")
