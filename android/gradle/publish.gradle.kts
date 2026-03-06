// Shared Maven Central publishing configuration
// Apply in each module's build.gradle.kts:
//   apply(from = "../gradle/publish.gradle.kts")

apply(plugin = "maven-publish")
apply(plugin = "signing")

val androidExtension = extensions.findByType<com.android.build.gradle.LibraryExtension>()

afterEvaluate {
    extensions.configure<PublishingExtension> {
        publications {
            create<MavenPublication>("release") {
                from(components.findByName("release"))

                groupId = "io.rynbridge"
                artifactId = project.name
                version = findProperty("rynbridge.version") as? String ?: "0.1.0"

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
                url = uri("https://s01.oss.sonatype.org/service/local/staging/deploy/maven2/")
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
