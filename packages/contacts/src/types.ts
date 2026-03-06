export interface Contact {
  id: string;
  givenName: string;
  familyName: string;
  phoneNumbers: ContactPhone[];
  emailAddresses: ContactEmail[];
}

export interface ContactPhone {
  label: string;
  number: string;
}

export interface ContactEmail {
  label: string;
  address: string;
}

export interface GetContactsPayload {
  query?: string;
  limit?: number;
  offset?: number;
}

export interface GetContactsResult {
  contacts: Contact[];
}

export interface GetContactPayload {
  id: string;
}

export interface CreateContactPayload {
  givenName: string;
  familyName: string;
  phoneNumbers?: ContactPhone[];
  emailAddresses?: ContactEmail[];
}

export interface CreateContactResult {
  id: string;
}

export interface UpdateContactPayload {
  id: string;
  givenName?: string;
  familyName?: string;
  phoneNumbers?: ContactPhone[];
  emailAddresses?: ContactEmail[];
}

export interface DeleteContactPayload {
  id: string;
}

export interface PickContactResult {
  contact: Contact | null;
}

export interface PermissionResult {
  granted: boolean;
}

export interface PermissionStatus {
  status: 'granted' | 'denied' | 'notDetermined';
}
