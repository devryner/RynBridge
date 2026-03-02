export interface ShowAlertPayload {
  title: string;
  message: string;
  buttonText?: string;
}

export interface ShowConfirmPayload {
  title: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
}

export interface ShowConfirmResponse {
  confirmed: boolean;
}

export interface ShowToastPayload {
  message: string;
  duration?: number;
}

export interface ShowActionSheetPayload {
  title?: string;
  options: string[];
}

export interface ShowActionSheetResponse {
  selectedIndex: number;
}

export interface SetStatusBarPayload {
  style?: string;
  hidden?: boolean;
}
