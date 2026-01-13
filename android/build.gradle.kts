buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // PERIKSA BARIS INI. HARUS ADA!
        // Gunakan versi 4.4.1 atau terbaru
        classpath("com.google.gms:google-services:4.4.1")
        
        // Classpath untuk Kotlin dan Android (biasanya sudah ada)
        classpath("com.android.tools.build:gradle:8.2.1") // (Versi mungkin beda, biarkan)
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22") // (Versi mungkin beda, biarkan)
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
