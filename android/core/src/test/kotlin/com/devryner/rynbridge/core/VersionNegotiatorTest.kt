package com.devryner.rynbridge.core

import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class VersionNegotiatorTest {

    private val negotiator = VersionNegotiator()

    @Test
    fun `parse valid version`() {
        val v = negotiator.parse("1.2.3")
        assertEquals(1, v.major)
        assertEquals(2, v.minor)
        assertEquals(3, v.patch)
    }

    @Test
    fun `parse invalid version`() {
        val exception = assertThrows(RynBridgeError::class.java) {
            negotiator.parse("invalid")
        }
        assertEquals(ErrorCode.VERSION_MISMATCH, exception.code)
    }

    @Test
    fun `parse incomplete version`() {
        assertThrows(RynBridgeError::class.java) {
            negotiator.parse("1.2")
        }
    }

    @Test
    fun `compatible same major stable`() {
        assertTrue(negotiator.isCompatible(local = "1.0.0", remote = "1.2.3"))
        assertTrue(negotiator.isCompatible(local = "2.0.0", remote = "2.5.0"))
    }

    @Test
    fun `incompatible different major stable`() {
        assertFalse(negotiator.isCompatible(local = "1.0.0", remote = "2.0.0"))
    }

    @Test
    fun `compatible same minor prerelease`() {
        assertTrue(negotiator.isCompatible(local = "0.1.0", remote = "0.1.5"))
    }

    @Test
    fun `incompatible different minor prerelease`() {
        assertFalse(negotiator.isCompatible(local = "0.1.0", remote = "0.2.0"))
    }

    @Test
    fun `assertCompatible throws`() {
        val exception = assertThrows(RynBridgeError::class.java) {
            negotiator.assertCompatible(local = "1.0.0", remote = "2.0.0")
        }
        assertEquals(ErrorCode.VERSION_MISMATCH, exception.code)
    }

    @Test
    fun `assertCompatible passes`() {
        assertDoesNotThrow {
            negotiator.assertCompatible(local = "0.1.0", remote = "0.1.3")
        }
    }

    @Test
    fun `invalid version not compatible`() {
        assertFalse(negotiator.isCompatible(local = "bad", remote = "1.0.0"))
    }
}
