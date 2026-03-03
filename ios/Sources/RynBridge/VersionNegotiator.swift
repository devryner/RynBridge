import Foundation

public struct SemVer: Sendable, Equatable {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public var description: String { "\(major).\(minor).\(patch)" }
}

public struct VersionNegotiator: Sendable {
    public init() {}

    public func parse(_ version: String) throws -> SemVer {
        let parts = version.split(separator: ".")
        guard parts.count == 3,
              let major = Int(parts[0]),
              let minor = Int(parts[1]),
              let patch = Int(parts[2]),
              major >= 0, minor >= 0, patch >= 0 else {
            throw RynBridgeError(code: .versionMismatch, message: "Invalid version format: '\(version)'")
        }
        return SemVer(major: major, minor: minor, patch: patch)
    }

    public func isCompatible(local: String, remote: String) -> Bool {
        guard let localVer = try? parse(local),
              let remoteVer = try? parse(remote) else {
            return false
        }

        // For 0.x: minor versions must match
        if localVer.major == 0 || remoteVer.major == 0 {
            return localVer.major == remoteVer.major && localVer.minor == remoteVer.minor
        }

        // For 1+: major versions must match
        return localVer.major == remoteVer.major
    }

    public func assertCompatible(local: String, remote: String) throws {
        guard isCompatible(local: local, remote: remote) else {
            throw RynBridgeError(
                code: .versionMismatch,
                message: "Version mismatch: local '\(local)' is not compatible with remote '\(remote)'"
            )
        }
    }
}
