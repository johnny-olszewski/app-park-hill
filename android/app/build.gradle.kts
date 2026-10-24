import java.util.Properties

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
}

// Optional, gitignored per-developer override of the dev backend (README).
val devLocal = Properties().apply {
    val file = rootProject.file("dev.local.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

// Well-known local Supabase anon key (the CLI's fixed default), not a secret.
val localAnonKey =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"

android {
    namespace = "app.parkhill"
    compileSdk = 35

    defaultConfig {
        applicationId = providers.gradleProperty("appIdRoot").get()
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "0.1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    // Build-time environment selection (guide 5.2): each flavor's source set
    // provides its own ServiceBinding; src/main never checks which flavor.
    flavorDimensions += "environment"
    productFlavors {
        create("mock") {
            dimension = "environment"
            applicationIdSuffix = ".mock"
            resValue("string", "app_name", "Park Hill Mock")
        }
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Park Hill Dev")
            // Local Supabase from the emulator by default.
            buildConfigField("String", "BACKEND_URL", "\"${devLocal.getProperty("backendUrl") ?: "http://10.0.2.2:54321"}\"")
            buildConfigField("String", "BACKEND_ANON_KEY", "\"${devLocal.getProperty("backendAnonKey") ?: localAnonKey}\"")
        }
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    testOptions {
        // android.util.Log and friends return defaults in JVM unit tests.
        unitTests.isReturnDefaultValues = true
    }

    sourceSets {
        // Mock responses, read in place: mock assets and test resources (guide 4.1 rule 6).
        getByName("mock").assets.srcDirs("../../contract/mock_responses", "../../contract/seed")
        getByName("test").resources.srcDirs("../../contract/mock_responses", "../../contract/seed")
        getByName("androidTest").resources.srcDirs("../../contract/mock_responses", "../../contract/seed")
        // Backend function names and screen keys, generated from contract/names.json.
        // Every variant compiles them; Gradle ignores the Swift file beside them.
        getByName("main").java.srcDirs("../../contract/generated")
    }
}

// Mock never ships, so it has no release variant (guide 5.2 rule 3).
androidComponents {
    beforeVariants { variant ->
        if (variant.productFlavors.contains("environment" to "mock") && variant.buildType == "release") {
            variant.enable = false
        }
    }
}

dependencies {
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.material3)
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.lifecycle.runtime)
    implementation(libs.androidx.lifecycle.process)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.kotlinx.serialization.json)
    implementation(platform(libs.supabase.bom))
    implementation(libs.supabase.postgrest)
    implementation(libs.supabase.auth)
    implementation(libs.ktor.client.okhttp)

    testImplementation(libs.junit)
    testImplementation(libs.kotlinx.coroutines.test)
    testImplementation(libs.okhttp.mockwebserver)

    androidTestImplementation(platform(libs.compose.bom))
    androidTestImplementation(libs.compose.ui.test.junit4)
    debugImplementation(libs.compose.ui.test.manifest)
    androidTestImplementation(libs.androidx.test.runner)
    androidTestImplementation(libs.androidx.test.junit)
    androidTestImplementation(libs.kotlinx.coroutines.test)
}
