// ===============================
// 🔧 Android Project Build (root)
// ===============================

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Dành cho Firebase / Google Services
        classpath("com.google.gms:google-services:4.3.15")
    }
}

// ===============================
// ⚙️ Cấu hình chung cho toàn bộ project
// ===============================
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ===============================
// 📂 Đặt lại thư mục build để tách khỏi module con
// ===============================
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

// ===============================
// 🧹 Task clean
// ===============================
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// ===============================
// 🧩 Plugins (Gradle-level)
// ===============================
plugins {
    // Google Services – áp dụng sau cho module app
    id("com.google.gms.google-services") version "4.3.15" apply false

    // Nếu cần Kotlin DSL cho root-level plugin
    // id("org.jetbrains.kotlin.jvm") version "2.1.0" apply false
}
