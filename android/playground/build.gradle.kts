plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
}

android {
    namespace = "com.devryner.rynbridge.playground"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.devryner.rynbridge.playground"
        minSdk = 30
        targetSdk = 35
        versionCode = 1
        versionName = "0.1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation(project(":core"))
    implementation(project(":device"))
    implementation(project(":storage"))
    implementation(project(":secure-storage"))
    implementation(project(":ui"))
    implementation(project(":auth"))
    implementation(project(":push"))
    implementation(project(":payment"))
    implementation(project(":media"))
    implementation(project(":crypto"))
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.appcompat)
    implementation(libs.activity.ktx)
}
