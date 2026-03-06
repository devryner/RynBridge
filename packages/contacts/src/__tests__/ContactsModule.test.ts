import { describe, it, expect, beforeEach } from 'vitest';
import { RynBridge, MockTransport } from '@rynbridge/core';
import type { BridgeResponse } from '@rynbridge/core';
import { ContactsModule } from '../ContactsModule.js';

describe('ContactsModule', () => {
  let transport: MockTransport;
  let bridge: RynBridge;
  let contacts: ContactsModule;

  beforeEach(() => {
    transport = new MockTransport();
    bridge = new RynBridge({ timeout: 5000 }, transport);
    contacts = new ContactsModule(bridge);
  });

  function respondSuccess(payload: Record<string, unknown> = {}) {
    const sent = JSON.parse(transport.sent[transport.sent.length - 1]);
    const response: BridgeResponse = {
      id: sent.id,
      status: 'success',
      payload,
      error: null,
    };
    transport.simulateIncoming(JSON.stringify(response));
  }

  describe('getContacts', () => {
    it('sends get contacts request', async () => {
      const promise = contacts.getContacts({ query: 'John', limit: 10, offset: 0 });
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('contacts');
      expect(sent.action).toBe('getContacts');

      respondSuccess({ contacts: [{ id: '1', givenName: 'John', familyName: 'Doe', phoneNumbers: [], emailAddresses: [] }] });
      const result = await promise;
      expect(result.contacts).toHaveLength(1);
      expect(result.contacts[0].givenName).toBe('John');
    });
  });

  describe('getContact', () => {
    it('returns a single contact', async () => {
      const promise = contacts.getContact({ id: '1' });
      respondSuccess({ id: '1', givenName: 'Jane', familyName: 'Doe', phoneNumbers: [], emailAddresses: [] });
      const result = await promise;
      expect(result.givenName).toBe('Jane');
    });
  });

  describe('createContact', () => {
    it('creates a contact and returns id', async () => {
      const promise = contacts.createContact({ givenName: 'New', familyName: 'Contact' });
      respondSuccess({ id: 'new-1' });
      const result = await promise;
      expect(result.id).toBe('new-1');
    });
  });

  describe('deleteContact', () => {
    it('deletes a contact', async () => {
      const promise = contacts.deleteContact({ id: '1' });
      respondSuccess();
      await promise;
    });
  });

  describe('requestPermission', () => {
    it('requests permission', async () => {
      const promise = contacts.requestPermission();
      respondSuccess({ granted: true });
      const result = await promise;
      expect(result.granted).toBe(true);
    });
  });

  describe('getPermissionStatus', () => {
    it('returns permission status', async () => {
      const promise = contacts.getPermissionStatus();
      respondSuccess({ status: 'granted' });
      const result = await promise;
      expect(result.status).toBe('granted');
    });
  });

  describe('error handling', () => {
    it('propagates bridge errors', async () => {
      const promise = contacts.getContacts();
      const sent = JSON.parse(transport.sent[0]);
      const response: BridgeResponse = {
        id: sent.id,
        status: 'error',
        payload: {},
        error: { code: 'UNKNOWN', message: 'Permission denied' },
      };
      transport.simulateIncoming(JSON.stringify(response));
      await expect(promise).rejects.toThrow('Permission denied');
    });
  });
});
