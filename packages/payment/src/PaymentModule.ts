import { RynBridge } from '@rynbridge/core';
import type {
  GetProductsPayload,
  GetProductsResult,
  PurchasePayload,
  PurchaseResult,
  RestorePurchasesResult,
  FinishTransactionPayload,
  TransactionUpdateEvent,
} from './types.js';

const MODULE = 'payment';

export class PaymentModule {
  private readonly bridge: RynBridge;

  constructor(bridge?: RynBridge) {
    this.bridge = bridge ?? RynBridge.shared;
  }

  async getProducts(payload: GetProductsPayload): Promise<GetProductsResult> {
    const result = await this.bridge.call(MODULE, 'getProducts', payload as unknown as Record<string, unknown>);
    return result as unknown as GetProductsResult;
  }

  async purchase(payload: PurchasePayload): Promise<PurchaseResult> {
    const result = await this.bridge.call(MODULE, 'purchase', payload as unknown as Record<string, unknown>);
    return result as unknown as PurchaseResult;
  }

  async restorePurchases(): Promise<RestorePurchasesResult> {
    const result = await this.bridge.call(MODULE, 'restorePurchases');
    return result as unknown as RestorePurchasesResult;
  }

  async finishTransaction(payload: FinishTransactionPayload): Promise<void> {
    await this.bridge.call(MODULE, 'finishTransaction', payload as unknown as Record<string, unknown>);
  }

  onTransactionUpdate(listener: (data: TransactionUpdateEvent) => void): () => void {
    const wrapper = (data: Record<string, unknown>) => listener(data as unknown as TransactionUpdateEvent);
    this.bridge.onEvent('payment:transactionUpdate', wrapper);
    return () => this.bridge.offEvent('payment:transactionUpdate', wrapper);
  }
}
