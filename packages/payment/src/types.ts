export interface Product {
  id: string;
  title: string;
  description: string;
  price: string;
  currency: string;
}

export interface GetProductsPayload {
  productIds: string[];
}

export interface GetProductsResult {
  products: Product[];
}

export interface PurchasePayload {
  productId: string;
  quantity?: number;
}

export interface PurchaseResult {
  transactionId: string;
  productId: string;
  receipt: string;
}

export interface Transaction {
  transactionId: string;
  productId: string;
  purchaseDate: string;
  receipt: string;
}

export interface RestorePurchasesResult {
  transactions: Transaction[];
}

export interface FinishTransactionPayload {
  transactionId: string;
}

export interface TransactionUpdateEvent {
  transactionId: string;
  productId: string;
  status: 'purchasing' | 'purchased' | 'failed' | 'restored' | 'deferred';
}
