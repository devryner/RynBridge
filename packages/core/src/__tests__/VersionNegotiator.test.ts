import { describe, it, expect } from 'vitest';
import { VersionNegotiator } from '../version/VersionNegotiator.js';

describe('VersionNegotiator', () => {
  describe('parse', () => {
    it('parses valid semver', () => {
      expect(VersionNegotiator.parse('1.2.3')).toEqual({ major: 1, minor: 2, patch: 3 });
      expect(VersionNegotiator.parse('0.1.0')).toEqual({ major: 0, minor: 1, patch: 0 });
    });

    it('throws on invalid format', () => {
      expect(() => VersionNegotiator.parse('1.2')).toThrow(/Invalid version/);
      expect(() => VersionNegotiator.parse('abc')).toThrow(/Invalid version/);
      expect(() => VersionNegotiator.parse('1.2.3-beta')).toThrow(/Invalid version/);
    });
  });

  describe('isCompatible', () => {
    it('same major version is compatible (>= 1.0.0)', () => {
      expect(VersionNegotiator.isCompatible('1.0.0', '1.5.3')).toBe(true);
      expect(VersionNegotiator.isCompatible('2.0.0', '2.1.0')).toBe(true);
    });

    it('different major version is incompatible', () => {
      expect(VersionNegotiator.isCompatible('1.0.0', '2.0.0')).toBe(false);
      expect(VersionNegotiator.isCompatible('3.0.0', '1.0.0')).toBe(false);
    });

    it('0.x uses minor for compatibility', () => {
      expect(VersionNegotiator.isCompatible('0.1.0', '0.1.5')).toBe(true);
      expect(VersionNegotiator.isCompatible('0.1.0', '0.2.0')).toBe(false);
    });
  });

  describe('assertCompatible', () => {
    it('does not throw for compatible versions', () => {
      expect(() => VersionNegotiator.assertCompatible('1.0.0', '1.2.0')).not.toThrow();
    });

    it('throws for incompatible versions', () => {
      expect(() => VersionNegotiator.assertCompatible('1.0.0', '2.0.0')).toThrow(
        /incompatible/,
      );
    });
  });
});
