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
include(":webview")
include(":auth")
include(":push")
include(":payment")
include(":media")
include(":crypto")
include(":calendar")
include(":contacts")
include(":share")
include(":navigation")
include(":analytics")
include(":speech")
include(":translation")
include(":auth-google")
include(":auth-kakao")
include(":push-fcm")
include(":payment-google-play")
include(":bluetooth")
include(":health")
include(":background-task")
include(":playground")
