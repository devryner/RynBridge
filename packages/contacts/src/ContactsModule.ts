import type { RynBridge } from '@rynbridge/core';
import type {
  Contact,
  GetContactsPayload,
  GetContactsResult,
  GetContactPayload,
  CreateContactPayload,
  CreateContactResult,
  UpdateContactPayload,
  DeleteContactPayload,
  PickContactResult,
  PermissionResult,
  PermissionStatus,
} from './types.js';

const MODULE = 'contacts';

export class ContactsModule {
  private readonly bridge: RynBridge;

  constructor(bridge: RynBridge) {
    this.bridge = bridge;
  }

  async getContacts(payload?: GetContactsPayload): Promise<GetContactsResult> {
    const result = await this.bridge.call(MODULE, 'getContacts', (payload ?? {}) as Record<string, unknown>);
    return result as unknown as GetContactsResult;
  }

  async getContact(payload: GetContactPayload): Promise<Contact> {
    const result = await this.bridge.call(MODULE, 'getContact', payload as unknown as Record<string, unknown>);
    return result as unknown as Contact;
  }

  async createContact(payload: CreateContactPayload): Promise<CreateContactResult> {
    const result = await this.bridge.call(MODULE, 'createContact', payload as unknown as Record<string, unknown>);
    return result as unknown as CreateContactResult;
  }

  async updateContact(payload: UpdateContactPayload): Promise<void> {
    await this.bridge.call(MODULE, 'updateContact', payload as unknown as Record<string, unknown>);
  }

  async deleteContact(payload: DeleteContactPayload): Promise<void> {
    await this.bridge.call(MODULE, 'deleteContact', payload as unknown as Record<string, unknown>);
  }

  async pickContact(): Promise<PickContactResult> {
    const result = await this.bridge.call(MODULE, 'pickContact');
    return result as unknown as PickContactResult;
  }

  async requestPermission(): Promise<PermissionResult> {
    const result = await this.bridge.call(MODULE, 'requestPermission');
    return result as unknown as PermissionResult;
  }

  async getPermissionStatus(): Promise<PermissionStatus> {
    const result = await this.bridge.call(MODULE, 'getPermissionStatus');
    return result as unknown as PermissionStatus;
  }
}
