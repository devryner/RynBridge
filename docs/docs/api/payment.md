---
sidebar_position: 8
---

# Payment Module API

`@rynbridge/payment` — In-app purchases, product queries, and transaction management.

## Setup

```typescript
import { PaymentModule } from '@rynbridge/payment';

const payment = new PaymentModule(bridge);
```

## Methods

### `getProducts(payload): Promise<GetProductsResult>`

Fetches product information from the native store.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `productIds` | `string[]` | Yes | Product identifiers to query |

```typescript
const { products } = await payment.getProducts({ productIds: ['premium_monthly', 'premium_yearly'] });
products.forEach((p) => console.log(p.title, p.price, p.currency));
```

### `purchase(payload): Promise<PurchaseResult>`

Initiates a purchase flow.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `productId` | `string` | Yes | Product to purchase |
| `quantity` | `number` | No | Quantity (default: 1) |

```typescript
const result = await payment.purchase({ productId: 'premium_monthly' });
console.log(result.transactionId, result.receipt);
```

### `restorePurchases(): Promise<RestorePurchasesResult>`

Restores previously completed purchases.

```typescript
const { transactions } = await payment.restorePurchases();
transactions.forEach((tx) => console.log(tx.productId, tx.purchaseDate));
```

### `finishTransaction(payload): Promise<void>`

Marks a transaction as finished after server verification.

```typescript
await payment.finishTransaction({ transactionId: 'tx-123' });
```

### `onTransactionUpdate(listener): () => void`

Subscribes to transaction status updates. Returns an unsubscribe function.

```typescript
const unsub = payment.onTransactionUpdate((update) => {
  console.log(update.transactionId, update.status);
  // status: 'purchasing' | 'purchased' | 'failed' | 'restored' | 'deferred'
});
```

## Types

```typescript
interface Product { id: string; title: string; description: string; price: string; currency: string }
interface GetProductsPayload { productIds: string[] }
interface GetProductsResult { products: Product[] }
interface PurchasePayload { productId: string; quantity?: number }
interface PurchaseResult { transactionId: string; productId: string; receipt: string }
interface Transaction { transactionId: string; productId: string; purchaseDate: string; receipt: string }
interface RestorePurchasesResult { transactions: Transaction[] }
interface FinishTransactionPayload { transactionId: string }
interface TransactionUpdateEvent { transactionId: string; productId: string; status: 'purchasing' | 'purchased' | 'failed' | 'restored' | 'deferred' }
```

## Native Provider

| Platform | Protocol/Interface | Key Methods |
|----------|-------------------|-------------|
| iOS | `PaymentProvider` | `getProducts`, `purchase`, `restorePurchases`, `finishTransaction` |
| Android | `PaymentProvider` | Same as iOS |
