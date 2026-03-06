export interface PushRegistration {
  token: string;
  platform: string;
}

export interface PushToken {
  token: string | null;
}

export interface PushPermission {
  granted: boolean;
}

export interface PushPermissionStatus {
  status: 'granted' | 'denied' | 'notDetermined';
}

export interface PushNotification {
  title: string | null;
  body: string | null;
  data: Record<string, unknown> | null;
}

export interface PushTokenRefresh {
  token: string;
}

export interface PushNotificationOpened {
  title: string | null;
  body: string | null;
  data: Record<string, unknown> | null;
}
