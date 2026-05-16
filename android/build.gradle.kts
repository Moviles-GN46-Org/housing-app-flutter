allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.layout.buildDirectory.set(file("../build"))

subprojects {
    //  fix for verifyReleaseResources
    afterEvaluate {
        if (plugins.hasPlugin("com.android.application") ||
            plugins.hasPlugin("com.android.library")) {
            extensions.findByName("android")?.let { ext ->
                val android = ext as com.android.build.gradle.BaseExtension
                android.compileSdkVersion(36)
                android.buildToolsVersion("36.0.0")
            }
        }
        if (hasProperty("android")) {
            extensions.findByName("android")?.let { ext ->
                val android = ext as com.android.build.gradle.BaseExtension
                if (android.namespace == null) {
                    android.namespace = group.toString()
                }
            }
        }
    }
    // ===============================

    layout.buildDirectory.set(rootProject.layout.buildDirectory.dir(name))
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    if (project.name == "isar_flutter_libs") {
        pluginManager.withPlugin("com.android.library") {
            extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
                ?.namespace = "dev.isar.isar_flutter_libs"
        }
    }
}
