package com.devryner.rynbridge.core

data class SemVer(
    val major: Int,
    val minor: Int,
    val patch: Int
) {
    val description: String get() = "$major.$minor.$patch"
}

class VersionNegotiator {

    fun parse(version: String): SemVer {
        val parts = version.split(".")
        if (parts.size != 3) {
            throw RynBridgeError(
                code = ErrorCode.VERSION_MISMATCH,
                message = "Invalid version format: '$version'"
            )
        }
        val major = parts[0].toIntOrNull()
        val minor = parts[1].toIntOrNull()
        val patch = parts[2].toIntOrNull()
        if (major == null || minor == null || patch == null || major < 0 || minor < 0 || patch < 0) {
            throw RynBridgeError(
                code = ErrorCode.VERSION_MISMATCH,
                message = "Invalid version format: '$version'"
            )
        }
        return SemVer(major, minor, patch)
    }

    fun isCompatible(local: String, remote: String): Boolean {
        val localVer = try { parse(local) } catch (_: Exception) { return false }
        val remoteVer = try { parse(remote) } catch (_: Exception) { return false }

        // For 0.x: minor versions must match
        if (localVer.major == 0 || remoteVer.major == 0) {
            return localVer.major == remoteVer.major && localVer.minor == remoteVer.minor
        }

        // For 1+: major versions must match
        return localVer.major == remoteVer.major
    }

    fun assertCompatible(local: String, remote: String) {
        if (!isCompatible(local, remote)) {
            throw RynBridgeError(
                code = ErrorCode.VERSION_MISMATCH,
                message = "Version mismatch: local '$local' is not compatible with remote '$remote'"
            )
        }
    }
}
