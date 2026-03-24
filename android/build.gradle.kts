plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.android.library) apply false
    alias(libs.plugins.kotlin.android) apply false
    alias(libs.plugins.kotlin.serialization) apply false
    alias(libs.plugins.maven.publish) apply false
}

subprojects {
    afterEvaluate {
        if (plugins.hasPlugin("com.android.library")) {
            apply(plugin = "com.vanniktech.maven.publish")

            extensions.configure<com.vanniktech.maven.publish.MavenPublishBaseExtension> {
                coordinates(
                    groupId = "com.devryner.rynbridge",
                    artifactId = project.name,
                    version = findProperty("rynbridge.version") as? String ?: "0.1.0"
                )

                publishToMavenCentral(com.vanniktech.maven.publish.SonatypeHost.CENTRAL_PORTAL)
                signAllPublications()

                pom {
                    name.set("RynBridge ${project.name}")
                    description.set("RynBridge ${project.name} module for Android")
                    url.set("https://github.com/devryner/RynBridge")
                    licenses {
                        license {
                            name.set("MIT License")
                            url.set("https://opensource.org/licenses/MIT")
                        }
                    }
                    developers {
                        developer {
                            id.set("devryner")
                            name.set("Ryner")
                        }
                    }
                    scm {
                        url.set("https://github.com/devryner/RynBridge")
                        connection.set("scm:git:git://github.com/devryner/RynBridge.git")
                        developerConnection.set("scm:git:ssh://git@github.com/devryner/RynBridge.git")
                    }
                }
            }
        }
    }
}
