plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.cevicheria_app"
    compileSdk = 35  // Mejor usar número fijo para evitar problemas con flutter.compileSdkVersion dinámico
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.cevicheria_app"
        minSdk = 21  // Puedes ajustarlo si quieres, aquí es 21 mínimo recomendado
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

   buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug")
        isMinifyEnabled = false       // No minificar código
        isShrinkResources = false     // No eliminar recursos no usados (desactivar)
    }
}

}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    implementation("com.google.firebase:firebase-analytics")
    implementation("androidx.core:core-ktx:1.10.1")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.9.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")

    implementation("org.jetbrains.kotlin:kotlin-stdlib:2.1.0")
}
