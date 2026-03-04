pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "RynBridge"

include(":core")
include(":device")
include(":storage")
include(":secure-storage")
include(":ui")
include(":auth")
include(":push")
include(":payment")
include(":media")
include(":crypto")
include(":playground")
