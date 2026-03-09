// Shared types matching KakaoSDK template structures

export interface KakaoLink {
  webUrl?: string;
  mobileWebUrl?: string;
  androidExecutionParams?: Record<string, string>;
  iosExecutionParams?: Record<string, string>;
}

export interface KakaoButton {
  title: string;
  link: KakaoLink;
}

export interface KakaoContent {
  title: string;
  description?: string;
  imageUrl: string;
  imageWidth?: number;
  imageHeight?: number;
  link: KakaoLink;
}

export interface KakaoSocial {
  likeCount?: number;
  commentCount?: number;
  sharedCount?: number;
  viewCount?: number;
  subscriberCount?: number;
}

export interface KakaoCommerce {
  regularPrice: number;
  discountPrice?: number;
  discountRate?: number;
  fixedDiscountPrice?: number;
  productName?: string;
  currencyUnit?: string;
  currencyUnitPosition?: number;
}

// Action payloads

export interface ShareFeedPayload {
  content: KakaoContent;
  social?: KakaoSocial;
  buttons?: KakaoButton[];
  serverCallbackArgs?: Record<string, string>;
}

export interface ShareCommercePayload {
  content: KakaoContent;
  commerce: KakaoCommerce;
  buttons?: KakaoButton[];
  serverCallbackArgs?: Record<string, string>;
}

export interface ShareListPayload {
  headerTitle: string;
  headerLink: KakaoLink;
  contents: KakaoContent[];
  buttons?: KakaoButton[];
  serverCallbackArgs?: Record<string, string>;
}

export interface ShareCustomPayload {
  templateId: number;
  templateArgs?: Record<string, string>;
  serverCallbackArgs?: Record<string, string>;
}

// Responses

export interface KakaoShareResult {
  success: boolean;
  sharingUrl?: string;
}

export interface KakaoShareAvailability {
  available: boolean;
}
