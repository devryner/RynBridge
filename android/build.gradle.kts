plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.android.library) apply false
    alias(libs.plugins.kotlin.android) apply false
    alias(libs.plugins.kotlin.serialization) apply false
}

subprojects {
    afterEvaluate {
        if (plugins.hasPlugin("com.android.library")) {
            apply(plugin = "maven-publish")
            apply(plugin = "signing")

            val rynbridgeVersion = findProperty("rynbridge.version") as? String ?: "0.1.0"

            extensions.configure<PublishingExtension> {
                publications {
                    create<MavenPublication>("release") {
                        from(components.findByName("release"))

                        groupId = "com.devryner.rynbridge"
                        artifactId = project.name
                        version = rynbridgeVersion

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

                repositories {
                    maven {
                        name = "MavenCentral"
                        url = uri("https://central.sonatype.com/api/v1/publisher/deployments/download/")
                        credentials {
                            username = findProperty("mavenCentralUsername") as? String ?: ""
                            password = findProperty("mavenCentralPassword") as? String ?: ""
                        }
                    }
                }
            }

            extensions.configure<SigningExtension> {
                val signingKey = findProperty("signingInMemoryKey") as? String
                val signingPassword = findProperty("signingInMemoryKeyPassword") as? String
                if (signingKey != null && signingPassword != null) {
                    useInMemoryPgpKeys(signingKey, signingPassword)
                    sign(extensions.getByType<PublishingExtension>().publications["release"])
                }
            }
        }
    }
}
