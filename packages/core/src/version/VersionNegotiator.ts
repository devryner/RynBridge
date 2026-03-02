import { ErrorCode, RynBridgeError } from '../errors.js';

export interface SemVer {
  major: number;
  minor: number;
  patch: number;
}

export class VersionNegotiator {
  static parse(version: string): SemVer {
    const match = version.match(/^(\d+)\.(\d+)\.(\d+)$/);
    if (!match) {
      throw new RynBridgeError(
        ErrorCode.VERSION_MISMATCH,
        `Invalid version format: "${version}". Expected "major.minor.patch"`,
        { version },
      );
    }

    return {
      major: Number(match[1]),
      minor: Number(match[2]),
      patch: Number(match[3]),
    };
  }

  static isCompatible(local: string, remote: string): boolean {
    const localVer = VersionNegotiator.parse(local);
    const remoteVer = VersionNegotiator.parse(remote);

    if (localVer.major === 0 && remoteVer.major === 0) {
      return localVer.minor === remoteVer.minor;
    }

    return localVer.major === remoteVer.major;
  }

  static assertCompatible(local: string, remote: string): void {
    if (!VersionNegotiator.isCompatible(local, remote)) {
      throw new RynBridgeError(
        ErrorCode.VERSION_MISMATCH,
        `Version mismatch: local ${local} is incompatible with remote ${remote}`,
        { local, remote },
      );
    }
  }
}
